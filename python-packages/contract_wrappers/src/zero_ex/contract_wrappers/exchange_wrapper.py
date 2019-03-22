from eth_utils import to_checksum_address
from itertools import repeat
from web3.providers.base import BaseProvider
from zero_ex.contract_addresses import NETWORK_TO_ADDRESSES, NetworkId
from zero_ex.contract_artifacts import abi_by_name
from zero_ex.contract_wrappers.contract_wrapper import ContractWrapper
from zero_ex.contract_wrappers.utils import (
    normalize_signature,
    normalize_token_amount,
)
from zero_ex.json_schemas import assert_valid
from zero_ex.order_utils import (
    generate_order_hash_hex,
    is_valid_signature,
    order_to_jsdict,
    Order,
)


class ExchangeWrapper(ContractWrapper):
    __name__ = "ExchangeWrapper"

    def __init__(
        self,
        provider: BaseProvider,
        account_address: str = None,
        private_key: str = None,
    ):
        super(ExchangeWrapper, self).__init__(
            provider=provider,
            account_address=account_address,
            private_key=private_key,
        )
        self.exchange_address = NETWORK_TO_ADDRESSES[
            NetworkId(int(self._web3.net.version))
        ].exchange
        self._exchange = self._web3.eth.contract(
            address=to_checksum_address(self.exchange_address),
            abi=abi_by_name("exchange"),
        )

    def get_fill_event(self, tx_reciept):
        return self._exchange.events.Fill().processReceipt(tx_reciept)

    def get_cancel_event(self, tx_reciept):
        return self._exchange.events.Cancel().processReceipt(tx_reciept)

    def fill_order(
        self,
        order,
        amount_in_wei,
        signature,
        tx_opts=None,
        validate_only=False,
    ):
        assert_valid(
            order_to_jsdict(order, self.exchange_address), "/orderSchema"
        )
        is_valid_signature(
            self._provider,
            generate_order_hash_hex(order, self.exchange_address),
            signature,
            order["makerAddress"],
        )
        taker_fill_amount = normalize_token_amount(amount_in_wei)
        normalized_signature = normalize_signature(signature)
        func = self._exchange.functions.fillOrder(
            order, taker_fill_amount, normalized_signature
        )
        return self._invoke_function_call(
            func=func, tx_opts=tx_opts, validate_only=validate_only
        )

    def fill_or_kill_order(
        self,
        order,
        amount_in_wei,
        signature,
        tx_opts=None,
        validate_only=False,
    ):
        assert_valid(
            order_to_jsdict(order, self.exchange_address), "/orderSchema"
        )
        is_valid_signature(
            self._provider,
            generate_order_hash_hex(order, self.exchange_address),
            signature,
            order["makerAddress"],
        )
        taker_fill_amount = normalize_token_amount(amount_in_wei)
        normalized_signature = normalize_signature(signature)
        func = self._exchange.functions.fillOrKillOrder(
            order, taker_fill_amount, normalized_signature
        )
        return self._invoke_function_call(
            func=func, tx_opts=tx_opts, validate_only=validate_only
        )
