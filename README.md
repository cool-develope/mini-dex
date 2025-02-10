# Mini DEX

A minimalistic implementation of a Decentralized Exchange (DEX) following Uniswap V2's core mechanics.

## Features

- Create trading pairs with custom fee settings
- Add liquidity to trading pairs
- Perform token swaps with automated price calculation
- Simple and efficient implementation

```mermaid
flowchart TD
    A[User] -->|Add Liquidity| B{"`Choose Token
    Pair`"}
    A -->|Remove Liquidity| C{"`Select LP Token
    to Remove`"}
    A -->|Swap Tokens| D{"`Choose Input Token`"}

    subgraph Add Liquidity Flow
        B -->|Transfer tokenA & tokenB| E[MiniRouter]
        E -->|Route to Pair Contract| F[MiniPair]
        F -->|Calculate LP Tokens| G["`Mint LP Tokens`"]
        F -->|Update Reserves| H["`Update tokenA & tokenB
        Reserves`"]
        G -->|Send LP Tokens| I[User Wallet]
    end

    subgraph Remove Liquidity Flow
        C -->|Transfer LP Tokens| J[MiniRouter]
        J -->|Route to Pair Contract| K[MiniPair]
        K -->|Calculate tokenA & tokenB| L["Burn LP Tokens"]
        K -->|Update Reserves| M["`Update tokenA & tokenB
        Reserves`"]
        L -->|Send tokenA & tokenB| N[User Wallet]
    end

    subgraph Swap Tokens Flow
        D -->|Transfer tokenA| O[MiniRouter]
        O -->|Route to Pair Contract| P[MiniPair]
        P -->|Calculate Output Token| Q["`Apply Fee
        Calculate Output`"]
        P -->|Update Reserves| R["`Update tokenA & tokenB
        Reserves`"]
        Q -->|Send tokenB| S[User Wallet]
    end

    I -->|Confirm LP Tokens| A
    N -->|Confirm tokenA & tokenB| A
    S -->|Confirm Output Token| A
```

## Architecture

1. `MiniFactory.sol`: Creates and manages trading pairs
2. `MiniPair.sol`: Handles liquidity provision and swaps
3. `MiniRouter.sol`: User-facing contract for liquidity and swap operations

```mermaid
flowchart TD
   A[User] -->|Add Liquidity| B[Router]
   A -->|Remove Liquidity| B
   A -->|Swap Tokens| B
   A -->|Create Pair| C[Factory]

   subgraph MiniFactory
      C -->|Create Pair| D
   end

   subgraph MiniRouter
      B -->|Get Pair| C --> |Return Pair| B
      B -->|Route Call| D[Pair]
   end

   subgraph MiniPair
      D -->|Add Liquidity| E["`Calculate added Liquidity
      Update Reserves`"]
      D -->|Remove Liquidity| F["`Calculate removed Liquidity
      Update Reserves`"]
      D -->|Swap Tokens| G["`Calculate Output Amounts
      Apply Fee
      Update Reserves`"]
   end

   H[User Wallet] -->|Send Tokens| E
   F -->|Receive Tokens| H
   G <-->|Swap Tokens| H
   H -->|Confirm Transaction| A
```

## Local Development

### Prerequisites

- [Foundry](https://book.getfoundry.sh/getting-started/installation)

```bash
# install foundryup
curl -L https://foundry.paradigm.xyz | bash
# install forge, anvil, cast
foundryup
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

### Deployment

1. Start a local network using Anvil

```bash
anvil --mnemonic "test test test test test test test test test test test junk"
```

2. Open the another terminal and deploy contracts

```bash
source .local.env
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast
```

Please check the logs for the deployed contracts' addresses.

```log
== Logs ==
  Deployed contracts:
  Factory: 0x5FbDB2315678afecb367f032d93F642f64180aa3
  Router: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
  Token A: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
  Token B: 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
```

3. Interact with the contracts using Cast

```bash
# Mint tokens for testing
cast send 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "mint(address,uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast send 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 "mint(address,uint256)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Check token balances
cast --to-dec $(cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url $RPC_URL)

cast --to-dec $(cast call 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url $RPC_URL)

# Approve tokens for router
cast send 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "approve(address,uint256)" 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast send 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 "approve(address,uint256)" 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Add liquidity
cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)"  0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 10000 20000 1000 2000 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Check token balances
cast --to-dec $(cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url $RPC_URL)

cast --to-dec $(cast call 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url $RPC_URL)

# Swap tokens
cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)" 1000 100 "[0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0,0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9]" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Check token balances
cast --to-dec $(cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url $RPC_URL)

cast --to-dec $(cast call 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url $RPC_URL)

# Remove liquidity
cast send 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512 "removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)"  0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 1000 100 100 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Check token balances
cast --to-dec $(cast call 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url $RPC_URL)

cast --to-dec $(cast call 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9 "balanceOf(address)" 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 --rpc-url $RPC_URL)
```

### Testing

1. Run tests

```bash
forge test
```

2. Run coverage

```bash
forge coverage
```

```table
╭------------------------+------------------+------------------+----------------+-----------------╮
| File                   | % Lines          | % Statements     | % Branches     | % Funcs         |
+=================================================================================================+
| script/Deploy.s.sol    | 0.00% (0/14)     | 0.00% (0/18)     | 100.00% (0/0)  | 0.00% (0/1)     |
|------------------------+------------------+------------------+----------------+-----------------|
| src/MiniFactory.sol    | 100.00% (12/12)  | 100.00% (11/11)  | 66.67% (4/6)   | 100.00% (2/2)   |
|------------------------+------------------+------------------+----------------+-----------------|
| src/MiniPair.sol       | 97.01% (65/67)   | 96.34% (79/82)   | 56.00% (14/25) | 100.00% (7/7)   |
|------------------------+------------------+------------------+----------------+-----------------|
| src/MiniRouter.sol     | 97.22% (70/72)   | 97.53% (79/81)   | 75.00% (30/40) | 100.00% (11/11) |
|------------------------+------------------+------------------+----------------+-----------------|
| src/mock/MockToken.sol | 100.00% (4/4)    | 100.00% (2/2)    | 100.00% (0/0)  | 100.00% (2/2)   |
|------------------------+------------------+------------------+----------------+-----------------|
| Total                  | 89.35% (151/169) | 88.14% (171/194) | 67.61% (48/71) | 95.65% (22/23)  |
╰------------------------+------------------+------------------+----------------+-----------------╯
```

## Deployment to Sepolia

1. Create a `.env` file with your private key and Infura/Alchemy API key:

```bash
export PRIVATE_KEY=your_private_key
export RPC_URL=your_sepolia_rpc_url
export ETHERSCAN_KEY=your_etherscan_api_key
```

2. Deploy the contracts:

```bash
source .env
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast --verify --etherscan-api-key $ETHERSCAN_KEY
```

If you don't have an Etherscan API key, you can remove the `--verify` and `--etherscan-api-key` flags.

```bash
forge script script/Deploy.s.sol:Deploy --rpc-url $RPC_URL --broadcast
```

Here are the deployed contracts' addresses:

| **Contract Name** | **Address (Etherscan Link)**                                                                                                  |
| ----------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Factory           | [0x7b9EA8a077f25CdEb98c1DfCf795c6b96c0B002b](https://sepolia.etherscan.io/address/0x7b9EA8a077f25CdEb98c1DfCf795c6b96c0B002b) |
| Router            | [0x986698D6840ef385CF23620AeFe1568989D7586C](https://sepolia.etherscan.io/address/0x986698D6840ef385CF23620AeFe1568989D7586C) |
| Token A           | [0xB61F70350545713349f1EddC770b031466919079](https://sepolia.etherscan.io/address/0xB61F70350545713349f1EddC770b031466919079) |
| Token B           | [0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B](https://sepolia.etherscan.io/address/0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B) |

3. Interact with the contracts using Cast:

```bash
# Mint tokens for testing
cast send 0xB61F70350545713349f1EddC770b031466919079 "mint(address,uint256)" <your_wallet_address> 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast send 0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B "mint(address,uint256)" <your_wallet_address> 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Check token balances
cast --to-dec $(cast call 0xB61F70350545713349f1EddC770b031466919079 "balanceOf(address)" <your_wallet_address> --rpc-url $RPC_URL)

cast --to-dec $(cast call 0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B "balanceOf(address)" <your_wallet_address> --rpc-url $RPC_URL)

# Approve tokens for router
cast send 0xB61F70350545713349f1EddC770b031466919079 "approve(address,uint256)" 0x986698D6840ef385CF23620AeFe1568989D7586C 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

cast send 0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B "approve(address,uint256)" 0x986698D6840ef385CF23620AeFe1568989D7586C 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Add liquidity
cast send 0x986698D6840ef385CF23620AeFe1568989D7586C "addLiquidity(address,address,uint256,uint256,uint256,uint256,address,uint256)"  0xB61F70350545713349f1EddC770b031466919079 0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B 10000 20000 1000 2000 <your_wallet_address> 1000000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Check token balances
cast --to-dec $(cast call 0xB61F70350545713349f1EddC770b031466919079 "balanceOf(address)" <your_wallet_address> --rpc-url $RPC_URL)

cast --to-dec $(cast call 0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B "balanceOf(address)" <your_wallet_address> --rpc-url $RPC_URL)

# Swap tokens
cast send 0x986698D6840ef385CF23620AeFe1568989D7586C "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)" 1000 100 "[0xB61F70350545713349f1EddC770b031466919079,0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B]" <your_wallet_address> 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Check token balances
cast --to-dec $(cast call 0xB61F70350545713349f1EddC770b031466919079 "balanceOf(address)" <your_wallet_address> --rpc-url $RPC_URL)

cast --to-dec $(cast call 0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B "balanceOf(address)" <your_wallet_address> --rpc-url $RPC_URL)

# Remove liquidity
cast send 0x986698D6840ef385CF23620AeFe1568989D7586C "removeLiquidity(address,address,uint256,uint256,uint256,address,uint256)"  0xB61F70350545713349f1EddC770b031466919079 0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B 1000 100 100 <your_wallet_address> 10000000000000 --rpc-url $RPC_URL --private-key $PRIVATE_KEY

# Check token balances
cast --to-dec $(cast call 0xB61F70350545713349f1EddC770b031466919079 "balanceOf(address)" <your_wallet_address> --rpc-url $RPC_URL)

cast --to-dec $(cast call 0x7D5849b2d0f69550ba8d01714ff93ab74c02ed7B "balanceOf(address)" <your_wallet_address> --rpc-url $RPC_URL)
```

## Design Decisions & Assumptions

1. Fee Structure

   - Fees are set per pair at creation time
   - Default swap fee is 0.3% (30 basis points)

2. Intentional Omissions

   - No flash loans
   - No price oracles
   - No governance mechanisms

3. Security Considerations
   - Reentrancy protection
   - Checks-Effects-Interactions pattern
   - SafeERC20 for token transfers
