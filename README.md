# Core Example Contracts

Example projects that demonstrate how to interact with the core smart contracts.

## Example Contracts

### [ExampleMakerOrder](./contracts/ExampleMakerOrder.sol)

#### Place a maker order for `WETH9`

```solidity
function placeMakerOrderForWETH9(uint128 amount) external returns (uint256 orderId);
```

#### Place a maker order for `USDC`

```solidity
function placeMakerOrderForUSDC(uint128 amount) external returns (uint256 orderId);
```

### [ExampleSwap](./contracts/ExampleSwap.sol)

#### *Single-Hop*-Swaps a specified amount of `USDC` for as much as possible of `WETH9`

```solidity
function exactInputSingle(uint256 amountIn, uint256 amountOutMinimum) external returns (uint256 amountOut);
```

#### *Single-Hop*-Swaps as little as possible of `WETH9` for a specified amount of `USDC`

```solidity
function exactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn);
```

#### *Multi-Hop*-Swaps a specified amount of `USDC` for as much as possible of `WETH9`

```solidity
function exactInput(uint256 amountIn, uint256 amountOutMinimum) external returns (uint256 amountOut);
```

#### *Multi-Hop*-Swaps as little as possible of `WETH9` for a specified amount of `USDC`

```solidity
function exactOutput(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn);
```

## Installation

```shell
npm install
```

## Compile

```shell
npx hardhat compile
```

Try running some of the following tasks:

```shell
npx hardhat help
npx hardhat test
REPORT_GAS=true npx hardhat test
npx hardhat node
npx hardhat run scripts/deploy.ts
```
