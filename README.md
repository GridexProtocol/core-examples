# Core Example Contracts

Example projects that demonstrate how to interact with the core smart contracts.

## Example Contracts

### [ExampleMakerOrder](./contracts/ExampleMakerOrder.sol)

#### Place a maker order

```solidity
struct PlaceOrderParameters {
    uint256 deadline;
    address recipient;
    address tokenA;
    address tokenB;
    int24 resolution;
    bool zero;
    int24 boundaryLower;
    uint128 amount;
}

function placeMakerOrder(
    PlaceOrderParameters calldata parameters
) external payable returns (uint256 orderId);
```

#### Place a batch of maker orders

```solidity
struct PlaceOrderInBatchParameters {
    uint256 deadline;
    address recipient;
    address tokenA;
    address tokenB;
    int24 resolution;
    bool zero;
    IGridParameters.BoundaryLowerWithAmountParameters[] orders;
}

function placeMakerOrderInBatch(
    PlaceOrderInBatchParameters calldata parameters
) external payable returns (uint256[] memory orderIds);
```

### [ExampleSwap](./contracts/ExampleSwap.sol)

#### Swap `amountIn` of one token for as much as possible of another token

```solidity
struct ExactInputSingleParameters {
    address tokenIn;
    address tokenOut;
    int24 resolution;
    address recipient;
    uint256 deadline;
    uint256 amountIn;
    uint256 amountOutMinimum;
    uint160 priceLimitX96;
}

function exactInputSingle(
    ExactInputSingleParameters calldata parameters
) external payable returns (uint256 amountOut);
```

### Swaps as little as possible of one token for `amountOut` of another token

```solidity
struct ExactOutputSingleParameters {
    address tokenIn;
    address tokenOut;
    int24 resolution;
    address recipient;
    uint256 deadline;
    uint256 amountOut;
    uint256 amountInMaximum;
    uint160 priceLimitX96;
}

function exactOutputSingle(
    ExactOutputSingleParameters calldata parameters
) external payable returns (uint256 amountIn);
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
