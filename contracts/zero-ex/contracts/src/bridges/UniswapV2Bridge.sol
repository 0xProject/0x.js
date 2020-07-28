/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";

interface IUniswapV2Router02 {

    /// @dev Swaps an exact amount of input tokens for as many output tokens as possible, along the route determined by the path.
    ///      The first element of path is the input token, the last is the output token, and any intermediate elements represent
    ///      intermediate pairs to trade through (if, for example, a direct pair does not exist).
    /// @param amountIn The amount of input tokens to send.
    /// @param amountOutMin The minimum amount of output tokens that must be received for the transaction not to revert.
    /// @param path An array of token addresses. path.length must be >= 2. Pools for each consecutive pair of addresses must exist and have liquidity.
    /// @param to Recipient of the output tokens.
    /// @param deadline Unix timestamp after which the transaction will revert.
    /// @return amounts The input token amount and all subsequent output token amounts.
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}


contract UniswapV2Bridge
{

    address constant private UNISWAP_V2_ROUTER_02_ADDRESS = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    function trade(
        address toTokenAdddress,
        uint256 sellAmount,
        bytes calldata bridgeData
    )
        external
        returns (uint256 boughtAmount)
    {
        // Decode the bridge data to get the `fromTokenAddress`.
        // solhint-disable indent
        address[] path = abi.decode(bridgeData, (address[]));
        // solhint-enable indent

        require(path.length >= 2, "UniswapV2Bridge/PATH_LENGTH_MUST_BE_AT_LEAST_TWO");
        require(path[path.length - 1] == toTokenAddress, "UniswapV2Bridge/LAST_ELEMENT_OF_PATH_MUST_MATCH_OUTPUT_TOKEN");
        // Grant the Uniswap router an allowance.
        LibERC20TokenV06.approveIfBelow(
            path[0],
            UNISWAP_V2_ROUTER_02_ADDRESS,
            sellAmount
        );

        IUniswapV2Router01 router = IUniswapV2Router02(UNISWAP_V2_ROUTER_02_ADDRESS);
        uint[] memory amounts = router.swapExactTokensForTokens(
             // Sell all tokens we hold.
            sellAmount,
             // Minimum buy amount.
            0,
            // Convert `fromTokenAddress` to `toTokenAddress`.
            path,
            // Recipient is `to`.
            address(this),
            // Expires after this block.
            block.timestamp
        );
        return amounts[amounts.length-1];
    }
}
