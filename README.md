# Minimal NFT Protocol

A small, dependency-free ERC-721 collection contract built for testing with Foundry.

> **Testing only.** This code has not been audited. Do not use it to manage NFTs or funds of real value.

## Included

- ERC-721 transfers, approvals, safe transfers, and metadata support
- Sequential paid public minting with a fixed maximum supply
- Owner reserve minting, price updates, metadata URI updates, and revenue withdrawal
- Focused Foundry tests with no external Solidity dependencies

## Quick start

Install [Foundry](https://book.getfoundry.sh/getting-started/installation), then run:

```bash
forge build
forge test
```

## Contract

Deploy `MinimalNFT` with a collection name, symbol, maximum supply, mint price in wei, and base metadata URI. Token IDs begin at `1`, and each token URI is formed by appending its ID to the base URI.

Example constructor arguments:

```solidity
new MinimalNFT(
    "Test Collection",
    "TEST",
    1_000,
    0.01 ether,
    "ipfs://your-collection/"
);
```

## License

MIT

