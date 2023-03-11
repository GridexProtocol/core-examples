// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

/// @title The interface for the swap router
interface ISwapRouter {
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
    ) external payable returns (uint256 amountOut);

    struct ExactInputParameters {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param parameters The parameters necessary for the multi-hop swap, encoded as `ExactInputParameters` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParameters calldata parameters) external payable returns (uint256 amountOut);

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
    ) external payable returns (uint256 amountIn);

    struct ExactOutputParameters {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param parameters The parameters necessary for the multi-hop swap, encoded as `ExactOutputParameters` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParameters calldata parameters) external payable returns (uint256 amountIn);
}
