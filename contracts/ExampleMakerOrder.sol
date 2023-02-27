// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@gridexprotocol/core/contracts/interfaces/IGrid.sol";
import "@gridexprotocol/core/contracts/interfaces/IGridFactory.sol";
import "@gridexprotocol/core/contracts/interfaces/IWETHMinimum.sol";
import "@gridexprotocol/core/contracts/interfaces/IGridParameters.sol";
import "@gridexprotocol/core/contracts/interfaces/callback/IGridPlaceMakerOrderCallback.sol";
import "@gridexprotocol/core/contracts/libraries/GridAddress.sol";
import "@gridexprotocol/core/contracts/libraries/CallbackValidator.sol";
import "@gridexprotocol/core/contracts/libraries/BoundaryMath.sol";
import "./Multicall.sol";

contract ExampleMakerOrder is IGridPlaceMakerOrderCallback, Multicall {
    /// @dev The address of IGridFactory
    address public immutable gridFactory;
    /// @dev The address of IWETHMinimum
    address public immutable weth9;

    constructor(address _griFactory, address _weth9) {
        gridFactory = _griFactory;
        weth9 = _weth9;
    }

    modifier checkDeadline(uint256 deadline) {
        require(deadline >= block.timestamp, "EXPIRED");
        _;
    }

    struct PlaceMakerOrderCalldata {
        GridAddress.GridKey gridKey;
        address payer;
    }

    /// @inheritdoc IGridPlaceMakerOrderCallback
    function gridexPlaceMakerOrderCallback(uint256 amount0, uint256 amount1, bytes calldata data) external override {
        PlaceMakerOrderCalldata memory decodeData = abi.decode(data, (PlaceMakerOrderCalldata));
        CallbackValidator.validate(gridFactory, decodeData.gridKey);

        if (amount0 > 0) pay(decodeData.gridKey.token0, decodeData.payer, msg.sender, amount0);

        if (amount1 > 0) pay(decodeData.gridKey.token1, decodeData.payer, msg.sender, amount1);
    }

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

    /// @notice Places a maker order
    /// @return orderId An order id representing the placed order
    function placeMakerOrder(
        PlaceOrderParameters calldata parameters
    ) external payable checkDeadline(parameters.deadline) returns (uint256 orderId) {
        GridAddress.GridKey memory gridKey = GridAddress.gridKey(
            parameters.tokenA,
            parameters.tokenB,
            parameters.resolution
        );
        address grid = GridAddress.computeAddress(gridFactory, gridKey);

        orderId = _placeMakerOrder(
            grid,
            gridKey,
            parameters.recipient == address(0) ? msg.sender : parameters.recipient,
            parameters.zero,
            parameters.boundaryLower,
            parameters.amount
        );
    }

    struct PlaceOrderInBatchParameters {
        uint256 deadline;
        address recipient;
        address tokenA;
        address tokenB;
        int24 resolution;
        bool zero;
        IGridParameters.BoundaryLowerWithAmountParameters[] orders;
    }

    /// @notice Places a batch of maker orders
    /// @return orderIds An array of order ids representing the placed orders
    function placeMakerOrderInBatch(
        PlaceOrderInBatchParameters calldata parameters
    ) external payable checkDeadline(parameters.deadline) returns (uint256[] memory orderIds) {
        GridAddress.GridKey memory gridKey = GridAddress.gridKey(
            parameters.tokenA,
            parameters.tokenB,
            parameters.resolution
        );
        address grid = GridAddress.computeAddress(gridFactory, gridKey);

        orderIds = IGrid(grid).placeMakerOrderInBatch(
            IGridParameters.PlaceOrderInBatchParameters({
                recipient: parameters.recipient == address(0) ? msg.sender : parameters.recipient,
                zero: parameters.zero,
                orders: parameters.orders
            }),
            abi.encode(PlaceMakerOrderCalldata({gridKey: gridKey, payer: msg.sender}))
        );
    }

    function _placeMakerOrder(
        address grid,
        GridAddress.GridKey memory gridKey,
        address recipient,
        bool zero,
        int24 boundaryLower,
        uint128 amount
    ) private returns (uint256 orderId) {
        orderId = IGrid(grid).placeMakerOrder(
            IGridParameters.PlaceOrderParameters({
                recipient: recipient,
                zero: zero,
                boundaryLower: boundaryLower,
                amount: amount
            }),
            abi.encode(PlaceMakerOrderCalldata({gridKey: gridKey, payer: msg.sender}))
        );
    }

    /// @dev Returns the grid for the given token pair and resolution. The grid contract may or may not exist.
    function getGrid(address tokenA, address tokenB, int24 resolution) private view returns (IGrid) {
        return IGrid(GridAddress.computeAddress(gridFactory, GridAddress.gridKey(tokenA, tokenB, resolution)));
    }

    /// @dev Pays the token to the recipient
    /// @param token The token to pay
    /// @param payer The address of the payment token
    /// @param recipient The address that will receive the payment
    /// @param amount The amount to pay
    function pay(address token, address payer, address recipient, uint256 amount) private {
        if (token == weth9 && address(this).balance >= amount) {
            // pay with WETH9
            Address.sendValue(payable(weth9), amount);
            IWETHMinimum(weth9).transfer(recipient, amount);
        } else if (payer == address(this)) SafeERC20.safeTransfer(IERC20(token), recipient, amount);
        else SafeERC20.safeTransferFrom(IERC20(token), payer, recipient, amount);
    }
}
