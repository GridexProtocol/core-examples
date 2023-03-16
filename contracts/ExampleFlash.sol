// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity =0.8.9;

import "@gridexprotocol/core/contracts/interfaces/callback/IGridFlashCallback.sol";
import "@gridexprotocol/core/contracts/interfaces/IGrid.sol";
import "@gridexprotocol/core/contracts/libraries/GridAddress.sol";
import "@gridexprotocol/core/contracts/libraries/CallbackValidator.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/ISwapRouter.sol";

/// @title Flash contract implementation
/// @notice An example contract using the Gridex flash function
contract ExampleFlash is IGridFlashCallback {
    // 1 is a fixed value that refers to the Gridex Protocol
    uint8 constant protocolGridex = 1;

    ISwapRouter public immutable swapRouter;
    address private immutable factory;

    constructor(ISwapRouter _swapRouter, address _factory) {
        swapRouter = _swapRouter;
        factory = _factory;
    }

    /// @param data The data needed in the callback passed as FlashCallbackData from `arbitrage`
    /// @notice implements the callback called from flash
    /// @dev fails if the flash is not profitable, meaning the amountOut from the flash is less than the amount borrowed
    function gridexFlashCallback(bytes calldata data) external override {
        FlashCallbackData memory decoded = abi.decode(data, (FlashCallbackData));
        CallbackValidator.validate(factory, decoded.gridKey);

        IERC20 tokenBorrowed = IERC20(decoded.tokenPath[0]);
        tokenBorrowed.approve(address(swapRouter), decoded.amountIn);

        // constructed from the exchange path, which is encoded as
        // `tokenIn+protocolID1+resolution1+swapedToken1+protocolID2+resolution2+swapedToken2+...+tokenOut`
        bytes memory path = abi.encodePacked(decoded.tokenPath[0]);
        for (uint i = 1; i < decoded.tokenPath.length; i++) {
            path = bytes.concat(
                path,
                abi.encodePacked(protocolGridex, decoded.resolutions[i - 1], decoded.tokenPath[i])
            );
        }

        uint256 amountOut = swapRouter.exactInput(
            ISwapRouter.ExactInputParameters({
                path: path,
                recipient: address(this),
                amountIn: decoded.amountIn,
                deadline: block.timestamp,
                amountOutMinimum: decoded.amountIn
            })
        );

        // send the borrowed tokens
        tokenBorrowed.transfer(msg.sender, decoded.amountIn);
        // send the remaining tokens
        tokenBorrowed.transfer(decoded.payer, amountOut - decoded.amountIn);
    }

    struct FlashParams {
        address token0;
        address token1;
        int24 resolution;
        bool isToken0Borrowed;
        uint256 amountIn;
        address[] tokenPath;
        int24[] resolutions;
    }

    struct FlashCallbackData {
        uint256 amountIn;
        address payer;
        GridAddress.GridKey gridKey;
        address[] tokenPath;
        int24[] resolutions;
    }

    /// @param params The parameters necessary for flash and the callback, passed in as FlashParams
    /// @notice Calls the grid flash function with data needed in `gridexFlashCallback`
    function arbitrage(FlashParams memory params) external {
        // Make sure that the correct token is borrowed.
        require(params.token0 < params.token1);
        // Ensure that the lengths of tokenPath and resolutions are matching.
        require(params.resolutions.length == params.tokenPath.length - 1);
        GridAddress.GridKey memory gridKey = GridAddress.GridKey({
            token0: params.token0,
            token1: params.token1,
            resolution: params.resolution
        });
        // Declaring the grid variable as type IGrid enables the execution of the flash method at a specific contract address.
        IGrid grid = IGrid(GridAddress.computeAddress(factory, gridKey));
        grid.flash(
            address(this),
            params.isToken0Borrowed ? params.amountIn : 0,
            params.isToken0Borrowed ? 0 : params.amountIn,
            abi.encode(
                FlashCallbackData({
                    amountIn: params.amountIn,
                    payer: msg.sender,
                    gridKey: gridKey,
                    tokenPath: params.tokenPath,
                    resolutions: params.resolutions
                })
            )
        );
    }
}
