// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

import "@openzeppelin/contracts/utils/math/SafeCast.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@gridexprotocol/core/contracts/interfaces/IGrid.sol";
import "@gridexprotocol/core/contracts/interfaces/IWETHMinimum.sol";
import "@gridexprotocol/core/contracts/interfaces/callback/IGridSwapCallback.sol";
import "@gridexprotocol/core/contracts/libraries/GridAddress.sol";
import "@gridexprotocol/core/contracts/libraries/CallbackValidator.sol";
import "@gridexprotocol/core/contracts/libraries/BoundaryMath.sol";
import "./Multicall.sol";

contract ExampleSwap is IGridSwapCallback, Multicall {
    using SafeCast for uint256;

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

    struct SwapCallbackData {
        address tokenIn;
        address tokenOut;
        int24 resolution;
        address payer;
    }

    /// @inheritdoc IGridSwapCallback
    function gridexSwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata _data) external override {
        SwapCallbackData memory data = abi.decode(_data, (SwapCallbackData));
        CallbackValidator.validate(gridFactory, GridAddress.gridKey(data.tokenIn, data.tokenOut, data.resolution));

        if (amount0Delta > 0) {
            pay(data.tokenIn, data.payer, msg.sender, uint256(amount0Delta));
        } else {
            pay(data.tokenIn, data.payer, msg.sender, uint256(amount1Delta));
        }
    }

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

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param parameters The parameters necessary for the swap, encoded as `ExactInputSingleParameters` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(
        ExactInputSingleParameters calldata parameters
    ) external payable checkDeadline(parameters.deadline) returns (uint256 amountOut) {
        bool zeroForOne = parameters.tokenIn < parameters.tokenOut;

        IGrid grid = getGrid(parameters.tokenIn, parameters.tokenOut, parameters.resolution);
        (int256 amount0, int256 amount1) = grid.swap(
            parameters.recipient == address(0) ? msg.sender : parameters.recipient,
            zeroForOne,
            parameters.amountIn.toInt256(),
            parameters.priceLimitX96 == 0
                ? (zeroForOne ? BoundaryMath.MIN_RATIO : BoundaryMath.MAX_RATIO)
                : parameters.priceLimitX96,
            abi.encode(
                SwapCallbackData({
                    payer: msg.sender,
                    tokenIn: parameters.tokenIn,
                    tokenOut: parameters.tokenOut,
                    resolution: parameters.resolution
                })
            )
        );

        amountOut = uint256(-(zeroForOne ? amount1 : amount0));

        require(amountOut >= parameters.amountOutMinimum, "TOO_LITTLE_RECEIVED");
    }

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

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param parameters The parameters necessary for the swap, encoded as `ExactOutputSingleParameters` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(
        ExactOutputSingleParameters calldata parameters
    ) external payable checkDeadline(parameters.deadline) returns (uint256 amountIn) {
        bool zeroForOne = parameters.tokenIn < parameters.tokenOut;

        IGrid grid = getGrid(parameters.tokenIn, parameters.tokenOut, parameters.resolution);
        (int256 amount0, int256 amount1) = grid.swap(
            parameters.recipient == address(0) ? msg.sender : parameters.recipient,
            zeroForOne,
            -parameters.amountOut.toInt256(),
            parameters.priceLimitX96 == 0
                ? (zeroForOne ? BoundaryMath.MIN_RATIO : BoundaryMath.MAX_RATIO)
                : parameters.priceLimitX96,
            abi.encode(
                SwapCallbackData({
                    payer: msg.sender,
                    tokenIn: parameters.tokenIn,
                    tokenOut: parameters.tokenOut,
                    resolution: parameters.resolution
                })
            )
        );

        uint256 amountOutReceived;
        (amountIn, amountOutReceived) = zeroForOne
            ? (uint256(amount0), uint256(-amount1))
            : (uint256(amount1), uint256(-amount0));

        require(amountIn >= parameters.amountInMaximum, "TOO_MUCH_REQUESTED");

        if (parameters.priceLimitX96 == 0) {
            require(amountOutReceived == parameters.amountOut, "INVALID_AMOUNT_OUT_RECEIVED");
        }
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
