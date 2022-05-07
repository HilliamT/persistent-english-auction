// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

abstract contract PersistentEnglish is Ownable, ERC721 {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event AuctionSale(address indexed bidder, uint256 winningBid);

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

    ///@notice id of current ERC721 being minted
    uint256 public currentId = 0;

    ///@notice All pending active bids on the auction
    Bid[] internal bids;

    ///@notice Amount of tokens sold to each bidder
    mapping(address => uint16) internal amountWon;
    mapping(address => uint16) internal amountMinted;

    uint256 public immutable auctionStartTime;
    uint32 public immutable totalToSell;
    uint32 public immutable timeBetweenSells;

    uint32 public remainingToSell;
    uint256 public revenue;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(
        string memory _name,
        string memory _symbol,
        uint32 _totalToSell,
        uint32 _timeBetweenSells
    ) ERC721(_name, _symbol) {
        auctionStartTime = uint256(block.timestamp);
        totalToSell = _totalToSell;
        timeBetweenSells = _timeBetweenSells;
        remainingToSell = _totalToSell;
    }

    /*//////////////////////////////////////////////////////////////
                          AUCTION INTERACTIONS
    //////////////////////////////////////////////////////////////*/

    ///@notice Bid on the auction
    function bid() public payable {
        require(!isOver(), "Auction has ended");

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

    ///@notice Claim mint and/or refund
    function claim() public {
        // For any unresolved clearing rounds, we process
        // these bids now. This allows us to update
        // the auction state lazily without having to
        // send a separate transaction that needs to be
        // scheduled.
        while (bids.length > 0 && remainingToSell > 0) {
            _takeTopBid();
        }

        // If the auction has ended, we allow for them
        // to claim a refund for the bids that were not
        // successful. This could be done as a separate call,
        // but we do it here for simplicity and to avoid
        // having to pay more gas with another transaction.
        if (isOver()) {
            uint256 refund = 0;

            // We can assume here that any bid that has not
            // been processed above by _takeTopBid is a bid that
            // has been unsuccessful in winning a mint. As such,
            // we can simply compute the total of the refund to give.
            for (uint256 i = 0; i < bids.length; i++) {
                if (bids[i].bidder == msg.sender) {
                    refund += bids[i].amount;
                }
            }

            // Refund the totalClaim
            (bool sent, ) = msg.sender.call{value: refund}("");
            require(sent, "Could not send refund");
        }

        // If a user has won a mint at any point in the auction,
        // they are able to claim it immediately. It is recommended
        // to claim after the auction has ended to save on gas, but
        // for those that don't want to wait, we do it here.
        for (
            uint256 i = 0;
            i < amountWon[msg.sender] - amountMinted[msg.sender];
            i++
        ) {
            amountMinted[msg.sender]++;
            _mint(msg.sender, ++currentId);
        }
    }

    /*//////////////////////////////////////////////////////////////
                             VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    ///@notice Is the auction over?
    function isOver() public view returns (bool) {
        return (auctionStartTime + timeBetweenSells * totalToSell <=
            uint256(block.timestamp));
    }

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
        uint256 pendingWins = 0;
        Bid[] memory winningBids = getTopPendingWinningBids();

        for (uint256 i = 0; i < winningBids.length; i++) {
            if (winningBids[i].bidder == msg.sender) {
                pendingWins += 1;
            }
        }

        return amountWon[msg.sender] + pendingWins;
    }

    ///@notice Get the total amount of tokens sold
    function totalSold() public view returns (uint256) {
        return
            totalToSell -
            remainingToSell +
            (isOver() ? getTopPendingWinningBids().length : 0);
    }

    ///@notice Get the total amount of tokens remaining to be sold
    function averageSale() public view returns (uint256) {
        if (totalSold() == 0) {
            return 0;
        }

        uint256 totalRevenue = revenue;

        // If the auction is over, we need to add on additional revenue
        Bid[] memory pendingWinningBids = getTopPendingWinningBids();
        for (uint256 i = 0; i < pendingWinningBids.length; i++) {
            totalRevenue += pendingWinningBids[i].amount;
        }

        return totalRevenue / totalSold();
    }

    ///@notice Get the top bids for tokens remaining to be sold
    ///@dev Only made to be used in (external) view functions due to the cost
    function getTopPendingWinningBids() public view returns (Bid[] memory) {
        Bid[] memory pendingWinningBids = new Bid[](remainingToSell);
        uint256[] memory indicesOfWinningBids = new uint256[](remainingToSell);

        // If the auction is not over, we can simply return an empty array
        if (!isOver() || remainingToSell == 0) {
            return pendingWinningBids;
        }

        // Iterate through all bids and find the top bids that have not been
        // taken yet, but would if _takeTopBid were called.
        for (uint256 i = 0; i < remainingToSell && i < bids.length; i++) {
            uint256 currentHighestBid = 0;
            uint256 currentHighestBidIndex = 0;

            // Get the top bid that is not already winning
            for (uint256 j = 0; j < bids.length; j++) {
                if (bids[j].amount > currentHighestBid) {
                    // Check that it is not a winning bid already
                    bool alreadyWinning = false;
                    for (uint256 k = 0; k < i; k++) {
                        if (j == indicesOfWinningBids[k]) {
                            alreadyWinning = true;
                            break;
                        }
                    }

                    if (!alreadyWinning) {
                        currentHighestBid = bids[j].amount;
                        currentHighestBidIndex = j;
                    }
                }
            }

            // Add the winning bid to the list of winning bids
            indicesOfWinningBids[i] = currentHighestBidIndex;
            pendingWinningBids[i] = bids[currentHighestBidIndex];
        }

        return pendingWinningBids;
    }

    /*//////////////////////////////////////////////////////////////
                          BID MANAGEMENT LOGIC
    //////////////////////////////////////////////////////////////*/

    ///@notice Record bid
    function _addBid(address bidder, uint256 bidAmount) private {
        bids.push(Bid(bidder, bidAmount));
    }

    ///@notice Get winning index for the bid to be sold to next
    function _getWinningIndex() private view returns (uint256) {
        // find the highest bid made across all bids
        uint256 winningIndex = 0;
        uint256 highestAmount = 0;
        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].amount > highestAmount) {
                winningIndex = i;
                highestAmount = bids[i].amount;
            }
        }

        return winningIndex;
    }

    ///@notice Extract the largest bid
    function _takeTopBid() private {
        uint256 winningIndex = _getWinningIndex();

        // remove the highest bid from the list by replacing it with the last bid
        Bid memory winningBid = bids[winningIndex];
        bids[winningIndex] = bids[bids.length - 1];
        bids.pop();

        // add the highest bid to the amountWon mapping
        amountWon[winningBid.bidder]++;
        remainingToSell--;

        revenue += winningBid.amount;
        emit AuctionSale(winningBid.bidder, winningBid.amount);
    }
}
