# Mini DEX

A minimalistic implementation of a Decentralized Exchange (DEX) following Uniswap V2's core mechanics.

## Features

- Create trading pairs with custom fee settings
- Add liquidity to trading pairs
- Perform token swaps with automated price calculation
- Simple and efficient implementation

## Contracts

1. `MiniFactory.sol`: Creates and manages trading pairs
2. `MiniPair.sol`: Handles liquidity provision and swaps
3. `MiniRouter.sol`: User-facing contract for liquidity and swap operations
4. `MockToken.sol`: ERC20 token for testing

## Local Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

```bash
curl -L https://foundry.paradigm.xyz | bash
```

### Setup

1. Clone the repository
```bash
git clone <repository-url>
cd mini-swap
```

2. Install dependencies
```bash
forge install
```

3. Build the contracts
```bash
forge build
```

4. Run tests
```bash
forge test
```

## Deployment to Sepolia

1. Create a `.env` file with your private key and Infura/Alchemy API key:
```bash
PRIVATE_KEY=your_private_key
RPC_URL=your_sepolia_rpc_url
```

2. Deploy the contracts:
```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast --verify
```

## Design Decisions & Assumptions

1. Fee Structure
   - Fees are set per pair at creation time
   - Default swap fee is 0.3% (30 basis points)

2. Intentional Omissions
   - No flash loans
   - No price oracles
   - No governance mechanism
   - No LP tokens (simplified for proof of concept)

3. Security Considerations
   - Reentrancy protection
   - Checks-Effects-Interactions pattern
   - SafeERC20 for token transfers

## Test Coverage

The project aims for 90%+ test coverage focusing on:
- Pair creation
- Liquidity provision
- Swap operations
- Edge cases and error conditions
