// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract PersistentEnglish is Ownable {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event AuctionSale(address indexed seller, uint256 value);

    /*//////////////////////////////////////////////////////////////
                                 STRUCTS
    //////////////////////////////////////////////////////////////*/

    struct Bid {
        address bidder;
        uint256 amount;
    }

    /*//////////////////////////////////////////////////////////////
                                  STATE
    //////////////////////////////////////////////////////////////*/

    ///@notice All pending active bids on the auction
    Bid[] internal bids;

    ///@notice Amount of tokens sold to each bidder
    mapping(address => uint16) internal amountWon;

    uint256 public immutable auctionStartTime;
    uint32 public immutable totalToSell;
    uint32 public immutable timeBetweenSells;

    uint32 public remainingToSell;
    bool public isActive;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(uint32 _totalToSell, uint32 _timeBetweenSells) {
        auctionStartTime = uint256(block.timestamp);
        totalToSell = _totalToSell;
        timeBetweenSells = _timeBetweenSells;

        remainingToSell = _totalToSell;
        isActive = true;
    }

    /*//////////////////////////////////////////////////////////////
                          AUCTION INTERACTIONS
    //////////////////////////////////////////////////////////////*/

    ///@notice Bid on the auction
    function bid() public payable {
        require(isActive, "Auction is not active");
        require(
            auctionStartTime + timeBetweenSells * totalToSell > block.timestamp,
            "Auction has ended"
        );

        // Accept bids that will have won a previous clearing round e.g
        // If a persistent English auction is to sell NFTs at a rate of
        // 1 per hour but the last bid made prior to this was made 2.5 hours
        // ago, we accept the top 2 bids now to account for this lag.
        while (
            bids.length > 0 &&
            remainingToSell > 0 &&
            uint256(block.timestamp) -
                (totalToSell - remainingToSell) *
                timeBetweenSells >
            auctionStartTime
        ) {
            _takeTopBid();
        }

        _addBid(msg.sender, msg.value);
    }

    ///@notice Close the auction
    function closeAuction() public onlyOwner {
        require(isActive, "Auction is not active");

        isActive = false;

        while (bids.length > 0 && remainingToSell > 0) {
            _takeTopBid();
        }
    }

    ///@notice Claim mint and/or refund
    function claim() public {
        require(!isActive, "Auction is still active");

        uint256 refund = 0;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].bidder == msg.sender) {
                refund += bids[i].amount;
            }
        }

        // Refund the totalClaim
        (bool sent, ) = msg.sender.call{value: refund}("");
        require(sent, "Could not send refund");

        // TODO: mint `amountWon[msg.sender]` NFTs to `msg.sender`
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    ///@notice Get the number of bids
    function noOfBids() public view returns (uint256) {
        return bids.length;
    }

    ///@notice Get all currently active bids from address
    function getBidsFromAddress(address _address)
        public
        view
        returns (Bid[] memory)
    {
        Bid[] memory result = new Bid[](bids.length);
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].bidder == _address) {
                result[i] = bids[i];
            }
        }
        return result;
    }

    ///@notice Get the total amount of winning bids for this address
    function getAmountWon() public view returns (uint256) {
        return amountWon[msg.sender];
    }

    ///@notice Get the total amount of tokens sold
    function totalSold() public view returns (uint256) {
        return totalToSell - remainingToSell;
    }

    ///@notice Get the total amount of tokens remaining to be sold
    function averageSale() public view returns (uint256) {
        if (totalSold() == 0) {
            return 0;
        }

        // Get balance of this smart contract
        uint256 balance = address(this).balance;

        // Subtract the total amount of bids
        uint256 totalInBids = 0;
        for (uint256 i = 0; i < bids.length; i++) {
            totalInBids += bids[i].amount;
        }

        return (balance - totalInBids) / totalSold();
    }

    /*//////////////////////////////////////////////////////////////
                          BID MANAGEMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    ///@notice Record bid
    function _addBid(address bidder, uint256 bidAmount) private {
        bids.push(Bid(bidder, bidAmount));
    }

    ///@notice Extract the largest bid
    function _takeTopBid() private {
        // find the highest bid made across all bids
        uint256 winningIndex = 0;
        uint256 highestAmount = 0;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].amount > highestAmount) {
                winningIndex = i;
                highestAmount = bids[i].amount;
            }
        }

        // remove the highest bid from the list by replacing it with the last bid
        Bid memory winningBid = bids[winningIndex];
        bids[winningIndex] = bids[bids.length - 1];
        bids.pop();

        // add the highest bid to the amountWon mapping
        amountWon[winningBid.bidder]++;
        remainingToSell--;

        emit AuctionSale(winningBid.bidder, winningBid.amount);
    }
}
