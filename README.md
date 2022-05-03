# Persistent English Auctions

A sequential clearing auction mechanism inspired by English auctions for maximising bid transparency and revenue.

We consider the situation in which a NFT artist would like to sell a collection of NFTs. They do not know what would be a fair price and thus resort to an auction.

In a persistent English auction, the auctioneer decides the rate at which NFTs should be sold at e.g 1 NFT per hour. Whilst the auction is active, potential buyers can register bids. In theory, at the end of every hour (a clearing round), a sale is made to the highest bidder until all pieces are sold.

Lazy evaluation is used to amortise the cost of operating the auction. Before a bid is made, the time gap between the previous transaction is calculated to see if any previous clearing rounds need to be processed. This approach is inspired by the concept of `virtual orders` used in [TWAMMs](https://www.paradigm.xyz/2021/07/twamm#the-time-weighted-average-market-maker).

Upon auction close, participants can mint their NFTs or claim their funds of unsuccessful bids.

## Getting Started

```
mkdir my-project
cd my-project
forge init --template https://github.com/FrankieIsLost/forge-template
git submodule update --init --recursive  ## initialize submodule dependencies
npm install ## install development dependencies
forge build
forge test
```

## Features

### Testing Utilities

Includes a `Utilities.sol` contract with common testing methods (like creating users with an initial balance), as well as various other utility contracts.

### Preinstalled dependencies

`ds-test` for testing, `forge-std` for better cheatcode UX, and `solmate` for optimized contract implementations.  

### Linting

Pre-configured `solhint` and `prettier-plugin-solidity`. Can be run by

```
npm run solhint
npm run prettier
```

### CI with Github Actions

Automatically run linting and tests on pull requests.

### Default Configuration

Including `.gitignore`, `.vscode`, `remappings.txt`

## Acknowledgement

Inspired by great dapptools templates like https://github.com/gakonst/forge-template, https://github.com/gakonst/dapptools-template and https://github.com/transmissions11/dapptools-template
