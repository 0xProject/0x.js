import { ContractWrappers, ContractWrappersError, ForwarderWrapperError } from '@0x/contract-wrappers';
import { AbiEncoder, providerUtils } from '@0x/utils';
import { SupportedProvider, ZeroExProvider } from '@0x/web3-wrapper';
import { MethodAbi } from 'ethereum-types';
import * as _ from 'lodash';

import { constants } from '../constants';
import {
    CalldataInfo,
    ExchangeSmartContractParams,
    SmartContractParamsInfo,
    SwapQuote,
    SwapQuoteConsumerBase,
    SwapQuoteConsumerError,
    SwapQuoteConsumerOpts,
    SwapQuoteExecutionOpts,
    SwapQuoteGetOutputOpts,
} from '../types';
import { assert } from '../utils/assert';
import { swapQuoteConsumerUtils } from '../utils/swap_quote_consumer_utils';
import { utils } from '../utils/utils';

export class ExchangeSwapQuoteConsumer implements SwapQuoteConsumerBase<ExchangeSmartContractParams> {
    public readonly provider: ZeroExProvider;
    public readonly networkId: number;

    private readonly _contractWrappers: ContractWrappers;

    constructor(supportedProvider: SupportedProvider, options: Partial<SwapQuoteConsumerOpts> = {}) {
        const { networkId } = _.merge({}, constants.DEFAULT_SWAP_QUOTER_OPTS, options);
        assert.isNumber('networkId', networkId);

        const provider = providerUtils.standardizeOrThrow(supportedProvider);
        this.provider = provider;
        this.networkId = networkId;
        this._contractWrappers = new ContractWrappers(this.provider, {
            networkId,
        });
    }

    public async getCalldataOrThrowAsync(
        quote: SwapQuote,
        opts: Partial<SwapQuoteGetOutputOpts>,
    ): Promise<CalldataInfo> {
        assert.isValidSwapQuote('quote', quote);

        const { to, methodAbi, ethAmount, params } = await this.getSmartContractParamsOrThrowAsync(quote, opts);

        const abiEncoder = new AbiEncoder.Method(methodAbi);

        const { orders, signatures } = params;
        let args: any[];
        if (params.type === 'marketBuy') {
            const { makerAssetFillAmount } = params;
            args = [orders, makerAssetFillAmount, signatures];
        } else {
            const { takerAssetFillAmount } = params;
            args = [orders, takerAssetFillAmount, signatures];
        }
        const calldataHexString = abiEncoder.encode(args);
        return {
            calldataHexString,
            methodAbi,
            to,
            ethAmount,
        };
    }

    public async getSmartContractParamsOrThrowAsync(
        quote: SwapQuote,
        _opts: Partial<SwapQuoteGetOutputOpts>,
    ): Promise<SmartContractParamsInfo<ExchangeSmartContractParams>> {
        assert.isValidSwapQuote('quote', quote);

        const { orders } = quote;

        const signatures = _.map(orders, o => o.signature);

        let params: ExchangeSmartContractParams;
        let methodName: string;

        if (quote.type === 'marketBuy') {
            const { makerAssetFillAmount } = quote;

            params = {
                orders,
                signatures,
                makerAssetFillAmount,
                type: 'marketBuy',
            };

            methodName = 'marketBuyOrders';
        } else {
            const { takerAssetFillAmount } = quote;

            params = {
                orders,
                signatures,
                takerAssetFillAmount,
                type: 'marketSell',
            };

            methodName = 'marketSellOrders';
        }

        const methodAbi = utils.getMethodAbiFromContractAbi(
            this._contractWrappers.exchange.abi,
            methodName,
        ) as MethodAbi;

        return {
            params,
            to: this._contractWrappers.exchange.address,
            methodAbi,
        };
    }

    public async executeSwapQuoteOrThrowAsync(
        quote: SwapQuote,
        opts: Partial<SwapQuoteExecutionOpts>,
    ): Promise<string> {
        assert.isValidSwapQuote('quote', quote);

        const { takerAddress, gasLimit, gasPrice } = opts;

        if (takerAddress !== undefined) {
            assert.isETHAddressHex('takerAddress', takerAddress);
        }
        if (gasLimit !== undefined) {
            assert.isNumber('gasLimit', gasLimit);
        }
        if (gasPrice !== undefined) {
            assert.isBigNumber('gasPrice', gasPrice);
        }

        const { orders } = quote;

        const finalTakerAddress = await swapQuoteConsumerUtils.getTakerAddressOrThrowAsync(this.provider, opts);

        try {
            let txHash: string;
            if (quote.type === 'marketBuy') {
                const { makerAssetFillAmount } = quote;
                txHash = await this._contractWrappers.exchange.marketBuyOrdersNoThrowAsync(
                    orders,
                    makerAssetFillAmount,
                    finalTakerAddress,
                    {
                        gasLimit,
                        gasPrice,
                        shouldValidate: true,
                    },
                );
            } else {
                const { takerAssetFillAmount } = quote;
                txHash = await this._contractWrappers.exchange.marketSellOrdersNoThrowAsync(
                    orders,
                    takerAssetFillAmount,
                    finalTakerAddress,
                    {
                        gasLimit,
                        gasPrice,
                        shouldValidate: true,
                    },
                );
            }
            return txHash;
        } catch (err) {
            if (_.includes(err.message, ContractWrappersError.SignatureRequestDenied)) {
                throw new Error(SwapQuoteConsumerError.SignatureRequestDenied);
            } else if (_.includes(err.message, ForwarderWrapperError.CompleteFillFailed)) {
                throw new Error(SwapQuoteConsumerError.TransactionValueTooLow);
            } else {
                throw err;
            }
        }
    }
}
