# Speculator Auction

Requirements and functionality documented in separate documentation.

## Missing Features

Following features are not yet implemented:
- Auction time check. Auction can be ended after 24 hours
- Pay out delay of 30 days
- User sign up has to be implemented
- Revenue withdrawn end of the year for the contract owner. At the moment no revenue remains in the contract. After an auction all funds are distributed to the bidders and the winner.
- Shutdown for the auction

## Prerequisite

Versions
```bash
$ npm -version
6.14.6
$ truffle version
Truffle v5.1.42 (core: 5.1.42)
Solidity - 0.6.12 (solc-js)
Node v12.18.3
Web3.js v1.2.1

npm install
```

## Testing

```bash
# Terminal 1
npm run ganache

# Terminal2 
truffle test

# Other commands
## Test coverage
npm run coverage

## Linting / Prettier
npm run lint
npm run prettier
```

Hint: Coverage produced failed tests. When using the 'development' network then coverage is running as expected. A network with a port different from 8545 seems to be failing. To run `npm run coverage` stop the `ganache` process firstly. 

**Current Coverage**
```
---------------------|----------|----------|----------|----------|----------------|
File                 |  % Stmts | % Branch |  % Funcs |  % Lines |Uncovered Lines |
---------------------|----------|----------|----------|----------|----------------|
 contracts/          |    97.44 |       60 |     87.5 |    97.47 |                |
  Auction.sol        |    98.61 |    60.71 |    88.89 |    98.61 |            214 |
  IERC20Mintable.sol |      100 |      100 |      100 |      100 |                |
  PriceFeedStub.sol  |      100 |      100 |      100 |      100 |                |
  RANDMinter.sol     |       75 |       50 |       75 |       80 |             18 |
  RANDToken.sol      |      100 |      100 |      100 |      100 |                |
---------------------|----------|----------|----------|----------|----------------|
All files            |    97.44 |       60 |     87.5 |    97.47 |                |
---------------------|----------|----------|----------|----------|----------------|
```