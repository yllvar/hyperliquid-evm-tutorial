# Hyperliquid EVM Tutorial

This repository contains a tutorial and reference implementation for interacting with Hyperliquid's EVM (Ethereum Virtual Machine) layer. The code demonstrates how to interact with Hyperliquid's L1 (Layer 1) from EVM smart contracts.

## Overview

Hyperliquid's architecture includes an EVM-compatible layer that allows smart contracts to interact with Hyperliquid's order book and other on-chain features. This tutorial provides a set of contracts that demonstrate common operations such as:

- Transferring assets between EVM and Hyperliquid L1
- Managing spot balances
- Staking and delegation
- Interacting with Hyperliquid's precompiled contracts

## Key Components

### Core Contracts

1. **L1EvmManager.sol**
   - Main contract for managing interactions between EVM and Hyperliquid L1
   - Handles token transfers, staking, and spot balance management
   - Provides a simple interface for common operations

2. **L1Read.sol**
   - Provides read-only access to Hyperliquid L1 state
   - Interfaces with Hyperliquid's precompiled contracts
   - Includes functions to query positions, spot balances, and other on-chain data

3. **L1Write.sol**
   - Interface for write operations on Hyperliquid L1
   - Handles order submission, token delegation, and other state-changing operations

## Getting Started

### Prerequisites

- [Foundry](https://book.getfoundry.org/getting-started/installation)
- Node.js (for testing)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/your-yllvar/hyperliquid-evm-tutorial.git
   cd hyperliquid-evm-tutorial
   ```

2. Install dependencies:
   ```bash
   forge install
   ```

### Building the Project

```bash
forge build
```

## Usage Examples

### Transferring HYPE to Staking

```solidity
// Transfer HYPE from EVM to staking on Hyperliquid L1
function fromEvmToStaking(address validator) public payable {
    require(msg.value > 0, "Must send HYPE token");
    uint64 value = uint64(msg.value);
    (bool success, ) = NATIVE_TRANSFER_ADDRESS.call{value: value}("");
    require(success, "Native Transfer Failed");
    uint64 l1Amount = uint64(value / 1e10);
    l1Write.sendCDeposit(l1Amount);
    l1Write.sendTokenDelegate(validator, l1Amount, false);
    emit EvmToStaking(msg.sender, validator, value);
}
```

### Querying Spot Balance

```solidity
// Get spot balance for a user and token
function getSpotBalance(address user, uint64 token) public view returns (L1Read.SpotBalance memory) {
    return l1Read.spotBalance(user, token);
}
```

## Testing

Run the test suite with:

```bash
forge test -vvv
```

## Deploying

To deploy the contracts to a network:

```bash
forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
```

## Security Considerations

- Always verify contract addresses before interacting with them
- Be cautious with the `delegatecall` operations
- Ensure proper access control is implemented in production
- Test thoroughly on testnet before deploying to mainnet

## Resources

- [Hyperliquid Documentation](https://hyperliquid.gitbook.io/hyperliquid-docs/)
- [Hyperliquid EVM Guide](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/hyperevm)
- [Foundry Documentation](https://book.getfoundry.org/)

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
