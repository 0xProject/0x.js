pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import "./IExchange.sol";


interface IERC20BridgeSampler {

    /// @dev Query native orders and sample sell orders on multiple DEXes at once.
    /// @param orders Native orders to query.
    /// @param sources Address of each DEX. Passing in an unknown DEX will throw.
    /// @param takerTokenAmounts Taker sell amount for each sample.
    /// @return orderInfos `OrderInfo`s for each order in `orders`.
    /// @return makerTokenAmountsBySource Maker amounts bought for each source at
    ///         each taker token amount. First indexed by source index, then sample
    ///         index.
    function queryOrdersAndSampleSells(
        IExchange.Order[] calldata orders,
        address[] calldata sources,
        uint256[] calldata takerTokenAmounts
    )
        external
        view
        returns (
            IExchange.OrderInfo[] memory orderInfos,
            uint256[][] memory makerTokenAmountsBySource
        );

    /// @dev Query native orders and sample buy orders on multiple DEXes at once.
    /// @param orders Native orders to query.
    /// @param sources Address of each DEX. Passing in an unknown DEX will throw.
    /// @param makerTokenAmounts Maker sell amount for each sample.
    /// @return orderInfos `OrderInfo`s for each order in `orders`.
    /// @return takerTokenAmountsBySource Taker amounts sold for each source at
    ///         each maker token amount. First indexed by source index, then sample
    ///         index.
    function queryOrdersAndSampleBuys(
        IExchange.Order[] calldata orders,
        address[] calldata sources,
        uint256[] calldata makerTokenAmounts
    )
        external
        view
        returns (
            IExchange.OrderInfo[] memory orderInfos,
            uint256[][] memory makerTokenAmountsBySource
        );

    /// @dev Queries the status of several native orders.
    /// @param orders Native orders to query.
    /// @return orderInfos Order info for each respective order.
    function queryOrders(IExchange.Order[] calldata orders)
        external
        view
        returns (IExchange.OrderInfo[] memory orderInfos);

    /// @dev Sample sell quotes on multiple DEXes at once.
    /// @param sources Address of each DEX. Passing in an unsupported DEX will throw.
    /// @param takerToken Address of the taker token (what to sell).
    /// @param makerToken Address of the maker token (what to buy).
    /// @param takerTokenAmounts Taker token sell amount for each sample.
    /// @return makerTokenAmountsBySource Maker amounts bought for each source at
    ///         each taker token amount. First indexed by source index, then sample
    ///         index.
    function sampleSells(
        address[] calldata sources,
        address takerToken,
        address makerToken,
        uint256[] calldata takerTokenAmounts
    )
        external
        view
        returns (uint256[][] memory makerTokenAmountsBySource);

    /// @dev Query native orders and sample buy quotes on multiple DEXes at once.
    /// @param sources Address of each DEX. Passing in an unsupported DEX will throw.
    /// @param takerToken Address of the taker token (what to sell).
    /// @param makerToken Address of the maker token (what to buy).
    /// @param makerTokenAmounts Maker token buy amount for each sample.
    /// @return takerTokenAmountsBySource Taker amounts sold for each source at
    ///         each maker token amount. First indexed by source index, then sample
    ///         index.
    function sampleBuys(
        address[] calldata sources,
        address takerToken,
        address makerToken,
        uint256[] calldata makerTokenAmounts
    )
        external
        view
        returns (uint256[][] memory takerTokenAmountsBySource);
}