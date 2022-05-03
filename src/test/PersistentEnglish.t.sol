// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {DSTest} from "ds-test/test.sol";
import {Vm} from "forge-std/Vm.sol";

import {PersistentEnglish} from "../PersistentEnglish.sol";

contract PersistentEnglishTest is DSTest {
    Vm internal immutable vm = Vm(HEVM_ADDRESS);

    function setUp() public {}

    function testPlacingFirstBid() public {
        uint32 totalToSell = 10;
        uint32 timeBetweenSells = 1;
        PersistentEnglish auction = new PersistentEnglish(
            totalToSell,
            timeBetweenSells
        );

        auction.bid{value: 0.01 ether}();
        assertEq(auction.noOfBids(), 1);
    }

    function testCanBidMultipleTimes() public {
        uint32 totalToSell = 10;
        uint32 timeBetweenSells = 1;
        PersistentEnglish auction = new PersistentEnglish(
            totalToSell,
            timeBetweenSells
        );

        auction.bid{value: 0.01 ether}();
        assertEq(auction.noOfBids(), 1);

        auction.bid{value: 0.01 ether}();
        assertEq(auction.noOfBids(), 2);

        auction.bid{value: 0.02 ether}();
        assertEq(auction.noOfBids(), 3);
    }

    function testClosingAuctionWithZeroBids() public {
        uint32 totalToSell = 10;
        uint32 timeBetweenSells = 1;
        PersistentEnglish auction = new PersistentEnglish(
            totalToSell,
            timeBetweenSells
        );

        auction.closeAuction();

        assertEq(auction.noOfBids(), 0);
        assertEq(auction.totalSold(), 0);
    }

    function testClosingAuctionWithMoreThanEnoughBids() public {
        uint32 totalToSell = 2;
        uint32 timeBetweenSells = 1;
        PersistentEnglish auction = new PersistentEnglish(
            totalToSell,
            timeBetweenSells
        );

        auction.bid{value: 0.01 ether}();
        auction.bid{value: 0.02 ether}();
        auction.bid{value: 0.03 ether}();

        auction.closeAuction();

        assertEq(auction.noOfBids(), 1);
        assertEq(auction.totalSold(), totalToSell);
        assertEq(auction.averageSale(), 0.025 ether);
    }

    function testClosingAuctionWithNotEnoughBidsToSellOut() public {
        uint32 totalToSell = 3;
        uint32 timeBetweenSells = 1;
        PersistentEnglish auction = new PersistentEnglish(
            totalToSell,
            timeBetweenSells
        );

        auction.bid{value: 0.01 ether}();
        auction.bid{value: 0.02 ether}();

        auction.closeAuction();

        assertEq(auction.noOfBids(), 0);
        assertEq(auction.totalSold(), 2);
        assertEq(auction.averageSale(), 0.015 ether);
    }

    function testLazyEvaluatedSale() public {
        uint32 totalToSell = 10;
        uint32 timeBetweenSells = 1;

        vm.warp(0);
        PersistentEnglish auction = new PersistentEnglish(
            totalToSell,
            timeBetweenSells
        );

        auction.bid{value: 0.01 ether}();
        auction.bid{value: 0.02 ether}();
        vm.warp(timeBetweenSells * 2);

        auction.bid{value: 0.03 ether}();

        assertEq(auction.noOfBids(), 1);
        assertEq(auction.totalSold(), 2);
        assertEq(auction.averageSale(), 0.015 ether);
    }
}
