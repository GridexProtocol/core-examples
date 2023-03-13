// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@gridexprotocol/core/contracts/interfaces/IGrid.sol";
import "@gridexprotocol/core/contracts/interfaces/IGridFactory.sol";
import "@gridexprotocol/core/contracts/libraries/GridAddress.sol";
import "@gridexprotocol/core/contracts/libraries/BoundaryMath.sol";
import "./interfaces/IMakerOrderManager.sol";

contract ExampleMakerOrder {
    IMakerOrderManager public immutable makerOrderManager;

    address public constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    int24 public constant RESOLUTION = 5;

    constructor(IMakerOrderManager _makerOrderManager) {
        makerOrderManager = _makerOrderManager;
    }

    /// @notice place a maker order for WETH9
    /// @param amount The amount of WETH9 to place a maker order
    /// @return orderId The id of the maker order
    function placeMakerOrderForWETH9(uint128 amount) external returns (uint256 orderId) {
        // msg.sender MUST approve the contract to spend the input token
        // transfer the specified amount of WETH9 to this contract
        SafeERC20.safeTransferFrom(IERC20(WETH9), msg.sender, address(this), amount);

        // approve the maker order manager to spend WETH9
        SafeERC20.safeApprove(IERC20(WETH9), address(makerOrderManager), amount);

        // compute grid address
        address gridAddress = GridAddress.computeAddress(
            makerOrderManager.gridFactory(),
            GridAddress.gridKey(WETH9, USDC, RESOLUTION)
        );
        IGrid grid = IGrid(gridAddress);

        (, int24 boundary, , ) = grid.slot0();
        // for this example, we will place a maker order at the current lower boundary of the grid
        int24 boundaryLower = BoundaryMath.getBoundaryLowerAtBoundary(boundary, RESOLUTION);
        IMakerOrderManager.PlaceOrderParameters memory parameters = IMakerOrderManager.PlaceOrderParameters({
            deadline: block.timestamp,
            recipient: address(this),
            tokenA: WETH9,
            tokenB: USDC,
            resolution: RESOLUTION,
            zero: grid.token0() == WETH9, // token0 is WETH9 or not
            boundaryLower: boundaryLower,
            amount: amount
        });

        orderId = makerOrderManager.placeMakerOrder(parameters);
    }

    /// @notice place a maker order for USDC
    /// @param amount The amount of USDC to place a maker order
    /// @return orderId The id of the maker order
    function placeMakerOrderForUSDC(uint128 amount) external returns (uint256 orderId) {
        // msg.sender MUST approve the contract to spend the input token
        // transfer the specified amount of USDC to this contract
        SafeERC20.safeTransferFrom(IERC20(USDC), msg.sender, address(this), amount);

        // approve the maker order manager to spend USDC
        SafeERC20.safeApprove(IERC20(USDC), address(makerOrderManager), amount);

        // compute grid address
        address gridAddress = GridAddress.computeAddress(
            makerOrderManager.gridFactory(),
            GridAddress.gridKey(WETH9, USDC, RESOLUTION)
        );
        IGrid grid = IGrid(gridAddress);

        (, int24 boundary, , ) = grid.slot0();
        // for this example, we will place a maker order at the current lower boundary of the grid
        int24 boundaryLower = BoundaryMath.getBoundaryLowerAtBoundary(boundary, RESOLUTION);
        IMakerOrderManager.PlaceOrderParameters memory parameters = IMakerOrderManager.PlaceOrderParameters({
            deadline: block.timestamp,
            recipient: address(this),
            tokenA: WETH9,
            tokenB: USDC,
            resolution: RESOLUTION,
            zero: grid.token0() == USDC, // token0 is USDC or not
            boundaryLower: boundaryLower,
            amount: amount
        });

        orderId = makerOrderManager.placeMakerOrder(parameters);
    }

    /// @notice settle and collect the maker order
    function settleAndCollect(uint256 orderId) external returns (uint128 amount0, uint128 amount1) {
        // compute grid address
        address gridAddress = GridAddress.computeAddress(
            makerOrderManager.gridFactory(),
            GridAddress.gridKey(WETH9, USDC, RESOLUTION)
        );

        (amount0, amount1) = IGrid(gridAddress).settleMakerOrderAndCollect(msg.sender, orderId, true);
    }
}
