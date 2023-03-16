// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@gridexprotocol/core/contracts/interfaces/IGrid.sol";
import "@gridexprotocol/core/contracts/libraries/GridAddress.sol";
import "@gridexprotocol/core/contracts/libraries/BoundaryMath.sol";
import "./interfaces/ISwapRouter.sol";

contract ExampleSwap {
    ISwapRouter public immutable router;

    address public constant WETH9 = 0x82aF49447D8a07e3bd95BD0d56f35241523fBab1;
    address public constant USDC = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    address public constant USDT = 0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9;

    constructor(ISwapRouter _router) {
        router = _router;
    }

    /// @notice Swaps a specified amount of USDC for as much as possible of WETH9
    /// using the USDC/WETH9 0.05% grid by calling exactInputSingle in the swap router.
    /// @dev The caller MUST approve the contract to spend at least `amountIn` USDC.
    /// @param amountIn The amount of USDC to swap
    /// @param amountOutMinimum The minimum amount of WETH9 to receive
    /// @return amountOut The amount of WETH9 the received token
    function exactInputSingle(uint256 amountIn, uint256 amountOutMinimum) external returns (uint256 amountOut) {
        // msg.sender MUST approve the contract to spend the input token
        // transfer the specified amount of USDC to this contract
        SafeERC20.safeTransferFrom(IERC20(USDC), msg.sender, address(this), amountIn);

        // 5 is the resolution of the grid, which fee is 0.05%
        int24 resolution = 5;

        // approve the router to spend USDC
        SafeERC20.safeApprove(IERC20(USDC), address(router), amountIn);

        // the call to exactInputSingle executes the swap
        amountOut = router.exactInputSingle(
            ISwapRouter.ExactInputSingleParameters({
                tokenIn: USDC,
                tokenOut: WETH9,
                resolution: resolution,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum,
                priceLimitX96: 0
            })
        );
    }

    /// @notice Swaps as little as possible of WETH9 for a specified amount of USDC
    /// using the USDC/WETH9 0.05% grid by calling exactOutputSingle in the swap router.
    /// @dev The caller MUST approve the contract to spend at least `amountInMaximum` WETH9.
    /// @param amountOut The amount of USDC to receive
    /// @param amountInMaximum The maximum amount of WETH9 to spend
    /// @return amountIn The amount of WETH9 actually swapped
    function exactOutputSingle(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        // msg.sender MUST approve the contract to spend the input token
        // transfer the specified amount of WETH9 to this contract
        SafeERC20.safeTransferFrom(IERC20(WETH9), msg.sender, address(this), amountInMaximum);

        // 5 is the resolution of the grid, which fee is 0.05%
        int24 resolution = 5;

        // approve the router to spend USDC
        SafeERC20.safeApprove(IERC20(WETH9), address(router), amountInMaximum);

        // the call to exactOutputSingle executes the swap
        amountIn = router.exactOutputSingle(
            ISwapRouter.ExactOutputSingleParameters({
                tokenIn: WETH9,
                tokenOut: USDC,
                resolution: resolution,
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                priceLimitX96: 0
            })
        );

        // refund any unused WETH9
        if (amountIn < amountInMaximum) {
            SafeERC20.safeApprove(IERC20(WETH9), address(router), 0);
            SafeERC20.safeTransfer(IERC20(WETH9), msg.sender, amountInMaximum - amountIn);
        }
    }

    /// @notice Swaps a specified amount of USDC for as much as possible of WETH9
    /// using the USDC/USDT 0.05% grid and USDT/WETH9 0.05% grid by calling exactInput in the swap router.
    /// @dev The caller MUST approve the contract to spend at least `amountIn` USDC.
    /// @param amountIn The amount of USDC to swap
    /// @param amountOutMinimum The minimum amount of WETH9 to receive
    /// @return amountOut The amount of WETH9 the received token
    function exactInput(uint256 amountIn, uint256 amountOutMinimum) external returns (uint256 amountOut) {
        // msg.sender MUST approve the contract to spend the input token
        // transfer the specified amount of USDC to this contract
        SafeERC20.safeTransferFrom(IERC20(USDC), msg.sender, address(this), amountIn);

        // 5 is the resolution of the grid, which fee is 0.05%
        int24 resolution = 5;

        // 1 is a fixed value that refers to the Gridex Protocol
        uint8 protocolGridex = 1;

        // approve the router to spend USDC
        SafeERC20.safeApprove(IERC20(USDC), address(router), amountIn);

        // the call to exactInput executes the swap
        amountOut = router.exactInput(
            ISwapRouter.ExactInputParameters({
                path: abi.encodePacked(USDC, protocolGridex, resolution, USDT, protocolGridex, resolution, WETH9),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: amountOutMinimum
            })
        );
    }

    /// @notice Swaps as little as possible of WETH9 for a specified amount of USDC
    /// using the USDC/USDT 0.05% grid and USDT/WETH9 0.05% grid by calling exactOutput in the swap router.
    /// @dev The caller MUST approve the contract to spend at least `amountInMaximum` WETH9.
    /// @param amountOut The amount of USDC to receive
    /// @param amountInMaximum The maximum amount of WETH9 to spend
    /// @return amountIn The amount of WETH9 actually swapped
    function exactOutput(uint256 amountOut, uint256 amountInMaximum) external returns (uint256 amountIn) {
        // msg.sender MUST approve the contract to spend the input token
        // transfer the specified amount of WETH9 to this contract
        SafeERC20.safeTransferFrom(IERC20(WETH9), msg.sender, address(this), amountInMaximum);

        // 5 is the resolution of the grid, which fee is 0.05%
        int24 resolution = 5;

        // 1 is a fixed value that refers to the Gridex Protocol
        uint8 protocolGridex = 1;

        // approve the router to spend WETH9
        SafeERC20.safeApprove(IERC20(WETH9), address(router), amountInMaximum);

        // the call to exactOutput executes the swap
        amountIn = router.exactOutput(
            ISwapRouter.ExactOutputParameters({
                path: abi.encodePacked(USDC, protocolGridex, resolution, USDT, protocolGridex, resolution, WETH9),
                recipient: msg.sender,
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum
            })
        );

        // refund any unused WETH9
        if (amountIn < amountInMaximum) {
            SafeERC20.safeApprove(IERC20(WETH9), address(router), 0);
            SafeERC20.safeTransfer(IERC20(WETH9), msg.sender, amountInMaximum - amountIn);
        }
    }
}
