// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";

import {MockPersistentEnglish} from "./mocks/MockPersistentEnglish.sol";

contract PersistentEnglishTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    MockPersistentEnglish internal auction;
    uint32 TOTAL_TO_SELL = 3;
    uint32 TIME_BETWEEN_SELLS = 2;

    function setUp() public {
        vm.warp(0);
        auction = new MockPersistentEnglish(
            "PersistentEnglish",
            "PEA",
            TOTAL_TO_SELL,
            TIME_BETWEEN_SELLS
        );
    }

    function testPlacingFirstBid() public {
        auction.bid{value: 0.01 ether}();
        assertEq(auction.noOfBids(), 1);
    }

    function testCanBidMultipleTimes() public {
        assertEq(auction.noOfBids(), 0);
        assertEq(auction.getBidsFromAddress(address(this)).length, 0);
        assertEq(auction.totalSold(), 0);
        assertEq(auction.averageSale(), 0);
        assertTrue(!auction.isOver());

        auction.bid{value: 0.01 ether}();
        assertEq(auction.noOfBids(), 1);
        assertEq(auction.getBidsFromAddress(address(this)).length, 1);
        assertEq(auction.totalSold(), 0);
        assertEq(auction.averageSale(), 0);
        assertTrue(!auction.isOver());

        auction.bid{value: 0.01 ether}();
        assertEq(auction.noOfBids(), 2);
        assertEq(auction.getBidsFromAddress(address(this)).length, 2);
        assertEq(auction.totalSold(), 0);
        assertEq(auction.averageSale(), 0);
        assertTrue(!auction.isOver());

        auction.bid{value: 0.02 ether}();
        assertEq(auction.noOfBids(), 3);
        assertEq(auction.getBidsFromAddress(address(this)).length, 3);
        assertEq(auction.totalSold(), 0);
        assertEq(auction.averageSale(), 0);
        assertTrue(!auction.isOver());
    }

    function testClosingAuctionWithZeroBids() public {
        auction.claim();

        assertEq(auction.noOfBids(), 0);
        assertEq(auction.getBidsFromAddress(address(this)).length, 0);
        assertEq(auction.totalSold(), 0);
        assertEq(auction.averageSale(), 0);
    }

    function testClosingAuctionWithMoreThanEnoughBids() public {
        auction.bid{value: 0.01 ether}();
        auction.bid{value: 0.02 ether}();
        auction.bid{value: 0.03 ether}();
        auction.bid{value: 0.04 ether}();
        auction.bid{value: 0.05 ether}();

        auction.claim();

        assertEq(auction.noOfBids(), 2);
        assertEq(auction.getBidsFromAddress(address(this)).length, 2);
        assertEq(auction.getAmountWon(), 3);
        assertEq(auction.totalSold(), TOTAL_TO_SELL);
        assertEq(auction.averageSale(), 0.04 ether);
    }

    function testClosingAuctionWithNotEnoughBidsToSellOut() public {
        auction.bid{value: 0.01 ether}();
        auction.bid{value: 0.02 ether}();

        auction.claim();

        assertEq(auction.noOfBids(), 0);
        assertEq(auction.getBidsFromAddress(address(this)).length, 0);
        assertEq(auction.getAmountWon(), 2);
        assertEq(auction.totalSold(), 2);
        assertEq(auction.averageSale(), 0.015 ether);
    }

    function testLazyEvaluatedSale() public {
        auction.bid{value: 0.01 ether}();
        auction.bid{value: 0.02 ether}();
        assertEq(auction.noOfBids(), 2);

        vm.warp(block.timestamp + TIME_BETWEEN_SELLS * 2);
        auction.bid{value: 0.03 ether}();

        assertEq(auction.noOfBids(), 1);
        assertEq(auction.getBidsFromAddress(address(this)).length, 1);
        assertEq(auction.getAmountWon(), 2);
        assertEq(auction.totalSold(), 2);
        assertEq(auction.averageSale(), 0.015 ether);

        auction.bid{value: 0.06 ether}();

        assertEq(auction.noOfBids(), 2);
        assertEq(auction.getBidsFromAddress(address(this)).length, 2);
        assertEq(auction.getAmountWon(), 2);
        assertEq(auction.totalSold(), 2);
        assertEq(auction.averageSale(), 0.015 ether);

        vm.warp(block.timestamp + TIME_BETWEEN_SELLS * 3);

        assertTrue(auction.isOver());

        assertEq(auction.noOfBids(), 2);
        assertEq(auction.getBidsFromAddress(address(this)).length, 2);
        assertEq(auction.getAmountWon(), 3);
        assertEq(auction.totalSold(), 3);
        // Note: 0.01 eth + 0.02 eth + 0.06 eth
        assertEq(auction.averageSale(), 0.03 ether);

        auction.claim();

        assertEq(auction.noOfBids(), 1);
        assertEq(auction.getBidsFromAddress(address(this)).length, 1);
        assertEq(auction.getAmountWon(), 3);
        assertEq(auction.totalSold(), 3);
        // Note: 0.01 eth + 0.02 eth + 0.06 eth
        assertEq(auction.averageSale(), 0.03 ether);
    }

    // Needed to accept refunds upon calling `auction.claim`
    fallback() external payable {}
}
