# Speculator Auction

Requirements and functionality documented in separate documentation.

## Missing Features

Following features are not yet implemented:
- Auction time check. Auction can be ended after 24 hours
- Pay out delay of 30 days
- Pay out option. Currency selection is currently ignored
- User sign up has to be implemented
- Revenue withdrawn end of the year for the contract owner
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
```