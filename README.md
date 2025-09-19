# Blockchain-Based Loyalty Program

A universal loyalty points system powered by blockchain technology, built on the Stacks blockchain using Clarity smart contracts.

## Overview

This project implements a decentralized loyalty rewards system that allows businesses to issue, manage, and redeem loyalty tokens through smart contracts. The system provides transparency, security, and interoperability for loyalty programs across different merchants and platforms.

## Features

- **Token Issuance**: Smart contract to mint and distribute loyalty tokens to customers
- **Token Management**: Track balances, transfers, and token metadata
- **Redemption System**: Allow customers to redeem loyalty points for products or services  
- **Multi-merchant Support**: Enable cross-merchant loyalty point usage
- **Transparent Tracking**: All transactions recorded on the blockchain
- **Secure Operations**: Built-in security measures and access controls

## Architecture

The system consists of two main smart contracts:

### 1. Loyalty Token Contract (`loyalty-token.clar`)
- Manages loyalty token creation, distribution, and transfers
- Implements token balances and metadata
- Handles merchant registration and token allocation
- Provides secure minting and burning capabilities

### 2. Redemption Contract (`redemption-contract.clar`)
- Manages the redemption of loyalty points for rewards
- Tracks available rewards and their point requirements
- Handles redemption transactions and validations
- Maintains redemption history and analytics

## Smart Contract Details

### Core Functions

**Loyalty Token Contract:**
- `mint-tokens`: Issue new loyalty tokens to users
- `transfer`: Transfer tokens between accounts
- `get-balance`: Check token balance for an account
- `burn-tokens`: Remove tokens from circulation
- `register-merchant`: Register new merchant in the system

**Redemption Contract:**
- `add-reward`: Add new rewards to the redemption catalog
- `redeem-points`: Redeem loyalty points for specific rewards
- `get-reward-details`: Get information about available rewards
- `get-redemption-history`: View past redemptions for an account

### Security Features

- Access control mechanisms for administrative functions
- Input validation for all public functions
- Overflow/underflow protection for mathematical operations
- Event logging for audit trails

## Getting Started

### Prerequisites

- [Clarinet](https://docs.hiro.so/clarinet) - Clarity development tool
- [Node.js](https://nodejs.org/) (for testing framework)
- [Git](https://git-scm.com/)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/aveevaricca/blockchain-based-loyalty-program.git
cd blockchain-based-loyalty-program
```

2. Install dependencies:
```bash
npm install
```

3. Check contract syntax:
```bash
clarinet check
```

4. Run tests:
```bash
clarinet test
```

## Usage

### Deploying Contracts

1. Configure your deployment settings in `settings/Mainnet.toml`, `settings/Testnet.toml`, or `settings/Devnet.toml`

2. Deploy to testnet:
```bash
clarinet deployments apply -e testnet
```

### Interacting with Contracts

Example contract calls using Clarinet console:

```clarity
;; Mint loyalty tokens
(contract-call? .loyalty-token mint-tokens u1000 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Check balance
(contract-call? .loyalty-token get-balance 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Add a reward
(contract-call? .redemption-contract add-reward "Coffee Cup" u100)

;; Redeem points
(contract-call? .redemption-contract redeem-points u0 u100)
```

## Testing

The project includes comprehensive unit tests for all contract functions. Run tests with:

```bash
clarinet test
```

Tests cover:
- Token minting and burning
- Balance tracking and transfers
- Reward management
- Redemption logic
- Security validations
- Error conditions

## Development

### Project Structure

```
blockchain-based-loyalty-program/
├── contracts/
│   ├── loyalty-token.clar      # Main loyalty token contract
│   └── redemption-contract.clar # Redemption management contract
├── tests/
│   ├── loyalty-token_test.ts    # Tests for loyalty token
│   └── redemption-contract_test.ts # Tests for redemption
├── settings/
│   ├── Devnet.toml             # Development network config
│   ├── Testnet.toml            # Testnet configuration  
│   └── Mainnet.toml            # Mainnet configuration
├── Clarinet.toml               # Main project configuration
└── package.json                # Node.js dependencies
```

### Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

### Code Style

- Follow Clarity best practices
- Use descriptive function and variable names
- Include comprehensive comments
- Write unit tests for all new functions
- Validate all inputs and handle edge cases

## Roadmap

- [ ] Integration with popular e-commerce platforms
- [ ] Mobile SDK for easy app integration
- [ ] Analytics dashboard for merchants
- [ ] Multi-token support (different loyalty currencies)
- [ ] NFT rewards integration
- [ ] Cross-chain compatibility

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For questions and support:
- Create an issue in the GitHub repository
- Review the [Clarity documentation](https://docs.stacks.co/clarity)
- Check the [Clarinet documentation](https://docs.hiro.so/clarinet)

## Acknowledgments

- Built with [Clarity](https://clarity-lang.org/) smart contract language
- Developed using [Clarinet](https://docs.hiro.so/clarinet) development tools
- Deployed on [Stacks blockchain](https://www.stacks.co/)