# Persistent English Auctions

A sequential clearing auction mechanism inspired by English auctions for maximising bid transparency and revenue.

We consider the situation in which a NFT artist would like to sell a collection of NFTs. They do not know what would be a fair price and thus resort to an auction.

In a persistent English auction, the auctioneer decides the rate at which NFTs should be sold at e.g 1 NFT per hour. Whilst the auction is active, potential buyers can register bids. In theory, at the end of every hour (a clearing round), a sale is made to the highest bidder. This is done until all pieces are sold.

Lazy evaluation is used to amortise the cost of operating the auction. Before a bid is made, the time gap between the previous transaction is calculated to see if any previous clearing rounds need to be processed. This is inspired by the concept of virtual orders used in [TWAMMs](https://www.paradigm.xyz/2021/07/twamm#the-time-weighted-average-market-maker).

Upon auction close, participants can mint their NFTs and/or claim their funds from unsuccessful bids.

## Getting Started

```
git clone https://github.com/HilliamT/persistent-english-auction.git
git submodule update --init --recursive  ## initialize submodule dependencies
npm install ## install development dependencies
forge build
forge test
```
## Changes to Make

### Contract
- [ ] Contract should be made abstract. This will require updating the usage of the contract in tests.
- [ ] Contract can be a `ERC721` itself.
- [ ] Currently, when the auction is to close, the last NFT does not get allocated to a bidder until the auction operator calls `closeAuction`. This also prevents minting and refunds to be processed as only the operator can make the auction inactive. This is not ideal.
- [ ] Fuzzing
### Simulation
- [ ] Translate updated contract logic into simulated class
- [ ] Simulate bids being made at random intervals via distribution
- [ ] Compute revenue and potential maximum revenue

## Resources
Below are a list of helpful resources that have helped me develop this idea.

- [A Guide to Designing Effective NFT Launches](https://www.paradigm.xyz/2021/10/a-guide-to-designing-effective-nft-launches)
- [TWAMMs - Virtual Orders](https://www.paradigm.xyz/2021/07/twamm#the-time-weighted-average-market-maker)