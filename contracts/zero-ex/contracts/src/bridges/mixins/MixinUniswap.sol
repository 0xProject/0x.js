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
pragma experimental ABIEncoderV2;

import "@0x/contracts-erc20/contracts/src/v06/LibERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IERC20TokenV06.sol";
import "@0x/contracts-erc20/contracts/src/v06/IEtherTokenV06.sol";

/*
    Uniswap
*/
interface IUniswapExchangeFactory {

    /// @dev Get the exchange for a token.
    /// @param tokenAddress The address of the token contract.
    function getExchange(address tokenAddress)
        external
        view
        returns (address);
}

interface IUniswapExchange {

    /// @dev Buys at least `minTokensBought` tokens with ETH and transfer them
    ///      to `recipient`.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param deadline Time when this order expires.
    /// @param recipient Who to transfer the tokens to.
    /// @return tokensBought Amount of tokens bought.
    function ethToTokenTransferInput(
        uint256 minTokensBought,
        uint256 deadline,
        address recipient
    )
        external
        payable
        returns (uint256 tokensBought);

    /// @dev Buys at least `minEthBought` ETH with tokens.
    /// @param tokensSold Amount of tokens to sell.
    /// @param minEthBought The minimum amount of ETH to buy.
    /// @param deadline Time when this order expires.
    /// @return ethBought Amount of tokens bought.
    function tokenToEthSwapInput(
        uint256 tokensSold,
        uint256 minEthBought,
        uint256 deadline
    )
        external
        returns (uint256 ethBought);

    /// @dev Buys at least `minTokensBought` tokens with the exchange token
    ///      and transfer them to `recipient`.
    /// @param tokensSold Amount of tokens to sell.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param minEthBought The minimum amount of intermediate ETH to buy.
    /// @param deadline Time when this order expires.
    /// @param recipient Who to transfer the tokens to.
    /// @param toTokenAddress The token being bought.
    /// @return tokensBought Amount of tokens bought.
    function tokenToTokenTransferInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address recipient,
        address toTokenAddress
    )
        external
        returns (uint256 tokensBought);

    /// @dev Buys at least `minTokensBought` tokens with the exchange token.
    /// @param tokensSold Amount of tokens to sell.
    /// @param minTokensBought The minimum number of tokens to buy.
    /// @param minEthBought The minimum amount of intermediate ETH to buy.
    /// @param deadline Time when this order expires.
    /// @param toTokenAddress The token being bought.
    /// @return tokensBought Amount of tokens bought.
    function tokenToTokenSwapInput(
        uint256 tokensSold,
        uint256 minTokensBought,
        uint256 minEthBought,
        uint256 deadline,
        address toTokenAddress
    )
        external
        returns (uint256 tokensBought);
}

contract MixinUniswap {

    using LibERC20TokenV06 for IERC20TokenV06;

    /// @dev Mainnet address of the WETH contract.
    IEtherTokenV06 private immutable WETH;
    /// @dev Mainnet address of the `UniswapExchangeFactory` contract.
    IUniswapExchangeFactory private immutable UNISWAP_EXCHANGE_FACTORY;

    constructor(address weth, address exchangeFactory)
        public
    {
        WETH = IEtherTokenV06(weth);
        UNISWAP_EXCHANGE_FACTORY = IUniswapExchangeFactory(exchangeFactory);
    }

    function _tradeUniswap(
        address toTokenAddress,
        uint256 sellAmount,
        bytes memory bridgeData
    )
        internal
        returns (uint256 boughtAmount)
    {
        // Decode the bridge data to get the `fromTokenAddress`.
        (address fromTokenAddress) = abi.decode(bridgeData, (address));

        // Get the exchange for the token pair.
        IUniswapExchange exchange = _getUniswapExchangeForTokenPair(
            fromTokenAddress,
            toTokenAddress
        );

        // Convert from WETH to a token.
        if (fromTokenAddress == address(WETH)) {
            // Unwrap the WETH.
            WETH.withdraw(sellAmount);
            // Buy as much of `toTokenAddress` token with ETH as possible
            boughtAmount = exchange.ethToTokenTransferInput{ value: sellAmount }(
                // Minimum buy amount.
                1,
                // Expires after this block.
                block.timestamp,
                // Recipient is `this`.
                address(this)
            );

        // Convert from a token to WETH.
        } else if (toTokenAddress == address(WETH)) {
            // Grant the exchange an allowance.
            IERC20TokenV06(fromTokenAddress).approveIfBelow(
                address(exchange),
                sellAmount
            );
            // Buy as much ETH with `fromTokenAddress` token as possible.
            boughtAmount = exchange.tokenToEthSwapInput(
                // Sell all tokens we hold.
                sellAmount,
                // Minimum buy amount.
                1,
                // Expires after this block.
                block.timestamp
            );
            // Wrap the ETH.
            WETH.deposit{ value: boughtAmount }();
        // Convert from one token to another.
        } else {
            // Grant the exchange an allowance.
            IERC20TokenV06(fromTokenAddress).approveIfBelow(
                address(exchange),
                sellAmount
            );
            // Buy as much `toTokenAddress` token with `fromTokenAddress` token
            boughtAmount = exchange.tokenToTokenSwapInput(
                // Sell all tokens we hold.
                sellAmount,
                // Minimum buy amount.
                1,
                // Must buy at least 1 intermediate wei of ETH.
                1,
                // Expires after this block.
                block.timestamp,
                // Convert to `toTokenAddress`.
                toTokenAddress
            );
        }

        return boughtAmount;
    }

    /// @dev Retrieves the uniswap exchange for a given token pair.
    ///      In the case of a WETH-token exchange, this will be the non-WETH token.
    ///      In th ecase of a token-token exchange, this will be the first token.
    /// @param fromTokenAddress The address of the token we are converting from.
    /// @param toTokenAddress The address of the token we are converting to.
    /// @return exchange The uniswap exchange.
    function _getUniswapExchangeForTokenPair(
        address fromTokenAddress,
        address toTokenAddress
    )
        private
        view
        returns (IUniswapExchange exchange)
    {
        address exchangeTokenAddress = fromTokenAddress;
        // Whichever isn't WETH is the exchange token.
        if (fromTokenAddress == address(WETH)) {
            exchangeTokenAddress = toTokenAddress;
        }
        exchange = IUniswapExchange(UNISWAP_EXCHANGE_FACTORY.getExchange(exchangeTokenAddress));
        require(address(exchange) != address(0), "NO_UNISWAP_EXCHANGE_FOR_TOKEN");
        return exchange;
    }
}
