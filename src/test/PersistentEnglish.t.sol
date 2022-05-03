// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";

import {MockPersistentEnglish} from "./mocks/MockPersistentEnglish.sol";

contract PersistentEnglishTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    MockPersistentEnglish internal auction;
    uint32 TOTAL_TO_SELL = 3;
    uint32 TIME_BETWEEN_SELLS = 1;

    function setUp() public {
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
        auction.bid{value: 0.01 ether}();
        assertEq(auction.noOfBids(), 1);

        auction.bid{value: 0.01 ether}();
        assertEq(auction.noOfBids(), 2);

        auction.bid{value: 0.02 ether}();
        assertEq(auction.noOfBids(), 3);
    }

    function testClosingAuctionWithZeroBids() public {
        auction.closeAuction();

        assertEq(auction.noOfBids(), 0);
        assertEq(auction.totalSold(), 0);
    }

    function testClosingAuctionWithMoreThanEnoughBids() public {
        auction.bid{value: 0.01 ether}();
        auction.bid{value: 0.02 ether}();
        auction.bid{value: 0.03 ether}();
        auction.bid{value: 0.04 ether}();
        auction.bid{value: 0.05 ether}();

        auction.closeAuction();

        assertEq(auction.noOfBids(), 2);
        assertEq(auction.totalSold(), TOTAL_TO_SELL);
        assertEq(auction.averageSale(), 0.04 ether);
    }

    function testClosingAuctionWithNotEnoughBidsToSellOut() public {
        auction.bid{value: 0.01 ether}();
        auction.bid{value: 0.02 ether}();

        auction.closeAuction();

        assertEq(auction.noOfBids(), 0);
        assertEq(auction.totalSold(), 2);
        assertEq(auction.averageSale(), 0.015 ether);
    }

    function testLazyEvaluatedSale() public {
        vm.warp(0);

        auction.bid{value: 0.01 ether}();
        auction.bid{value: 0.02 ether}();
        assertEq(auction.noOfBids(), 2);

        vm.warp(TIME_BETWEEN_SELLS * 2);

        auction.bid{value: 0.03 ether}();

        assertEq(auction.noOfBids(), 1);
        assertEq(auction.totalSold(), 2);
        assertEq(auction.averageSale(), 0.015 ether);
    }
}
