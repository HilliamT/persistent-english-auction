# Persistent English Auctions

A sequential clearing auction mechanism inspired by English auctions for maximising bid transparency and revenue.

We consider the situation in which a NFT artist would like to sell a collection of NFTs. They do not know what would be a fair price and thus resort to an auction.

In a persistent English auction, the auctioneer decides the rate at which NFTs should be sold at e.g 1 NFT per hour. Whilst the auction is active, potential buyers can register bids. In theory, at the end of every hour (a clearing round), a sale is made to the highest bidder. This is done until all pieces are sold.

Lazy evaluation is used to amortise the cost of operating the auction on the blockchain. Before a bid is made, the time gap between the previous transaction is calculated to see if any previous clearing rounds need to be processed. This is inspired by the concept of virtual orders used in [TWAMMs](https://www.paradigm.xyz/2021/07/twamm#the-time-weighted-average-market-maker).

Upon auction close, participants can mint their NFTs and/or claim their funds from unsuccessful bids.

The structure of this repository is heavily alike to [**@FrankieIsLost**](https://github.com/FrankieIsLost)'s [Gradual Dutch Auctions](https://github.com/FrankieIsLost/gradual-dutch-auction/) repository - the repository has formed a good basis for the development of this project.

## Getting Started

```
git clone https://github.com/HilliamT/persistent-english-auction.git
git submodule update --init --recursive  ## initialize submodule dependencies
npm install ## install development dependencies
forge build
forge test
```

## "Next Bid Wins" and "Propagate to Next Round"

If an auction round does not contain any bids to choose as the winner, we have two approaches that can be used to resolve this.

* **Next Bid Wins** - One solution is to immediately accept the next bid made. This ensures that within one bid, the item is sold. We note that this bid is automatically made inactive and thus can not win multiple items with a single bid. Through this method, it is possible for a bidder to pay zero as to maximise their utility gain. It can be argued that if no bids were placed by willing bidders, the value of the item could be zero by nature. This situation may also occur if all honest and colluding auction participants perceive that it is better to not bid within the auction round and win by placing the next bid with a bid amount of 0 - this can lead to zero value capture by the auctioneer.

* **Propagate To Next Round** - Another solution is to select an additional winner or winners at the end of the following round. Should an insufficient amount of bids be place in the following round, the remaining number of additional winners to pick is further propagated to further rounds. This can prove to be a fairer system that does not rely on placing the first bid to win - auction participants are given the duration of a round to respond to no bids being placed in the previous round.

Both implementations are provided, within `src/PersistentEnglish.sol` and `src/PersistentEnglishPropagation.sol` respectively.

## Resources
Below are a list of helpful resources that have helped me develop this idea.

- [A Guide to Designing Effective NFT Launches](https://www.paradigm.xyz/2021/10/a-guide-to-designing-effective-nft-launches)
- [FrankieIsLost/gradual-dutch-auction](https://github.com/FrankieIsLost/gradual-dutch-auction)
- [TWAMMs - Virtual Orders](https://www.paradigm.xyz/2021/07/twamm#the-time-weighted-average-market-maker)