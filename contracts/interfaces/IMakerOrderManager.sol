// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;

import "@gridexprotocol/core/contracts/interfaces/IGridParameters.sol";

/// @title The interface for the maker order manager
interface IMakerOrderManager {
    struct InitializeParameters {
        address tokenA;
        address tokenB;
        int24 resolution;
        uint160 priceX96;
        address recipient;
        IGridParameters.BoundaryLowerWithAmountParameters[] orders0;
        IGridParameters.BoundaryLowerWithAmountParameters[] orders1;
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

    struct PlaceOrderInBatchParameters {
        uint256 deadline;
        address recipient;
        address tokenA;
        address tokenB;
        int24 resolution;
        bool zero;
        IGridParameters.BoundaryLowerWithAmountParameters[] orders;
    }

    struct RelativeOrderParameters {
        uint256 deadline;
        address recipient;
        address tokenA;
        address tokenB;
        int24 resolution;
        bool zero;
        uint128 amount;
        /// @dev The price delta is the price difference between the order price and the grid price, as a Q64.96.
        /// Positive values mean the order price is higher than the grid price, and negative values mean the order price is
        /// lower than the grid price.
        int160 priceDeltaX96;
        /// @dev The minimum price of the order, as a Q64.96.
        uint160 priceMinimumX96;
        /// @dev The maximum price of the order, as a Q64.96.
        uint160 priceMaximumX96;
    }

    /// @notice Returns the address of the IGridFactory
    function gridFactory() external view returns (address);

    /// @notice Initializes the grid with the given parameters
    function initialize(InitializeParameters calldata initializeParameters) external payable;

    /// @notice Creates the grid and initializes the grid with the given parameters
    function createGridAndInitialize(InitializeParameters calldata initializeParameters) external payable;

    /// @notice Places a maker order on the grid
    /// @return orderId The unique identifier of the order
    function placeMakerOrder(PlaceOrderParameters calldata parameters) external payable returns (uint256 orderId);

    /// @notice Places maker orders on the grid
    /// @return orderIds The unique identifiers of the orders
    function placeMakerOrderInBatch(
        PlaceOrderInBatchParameters calldata parameters
    ) external payable returns (uint256[] memory orderIds);

    /// @notice Places a relative order
    /// @param parameters The parameters for the relative order
    /// @return orderId The unique identifier of the order
    function placeRelativeOrder(RelativeOrderParameters calldata parameters) external payable returns (uint256 orderId);
}
