from unicodedata import name
import pytest
import os

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import (
    compile_starknet_files)

CONTRACT_FILE = os.path.realpath(os.path.join(os.path.dirname(
    __file__), '..', 'contracts', 'finance', 'token', 'ERC20.cairo'))


@pytest.fixture
async def contract():
    contract_definition = compile_starknet_files(
        [CONTRACT_FILE], debug_info=True)
    starknet = await Starknet.empty()
    contract = await starknet.deploy(source=CONTRACT_FILE,
                                     constructor_calldata=[1111, 2222, 10000, 00, 12345])
    return contract


@pytest.mark.asyncio
async def test_constructor(contract):
    name = await contract.name().call()
    assert name.result.name == 1111
    symbol = await contract.symbol().call()
    assert symbol.result.symbol == 2222
    supply = await contract.totalSupply().call()
    assert supply.result.totalSupply == (10000, 0)


@pytest.mark.asyncio
async def test_tansfer(contract):
    transfer_ok = await contract.transfer(98765, (9999, 0)).invoke()
    assert transfer_ok.result.success == 1
    receiver_balance = await contract.balanceOf(98765).call()
    assert receiver_balance.result.balance == (9999, 0)
    sender_balance = await contract.balanceOf(12345).call()
    assert sender_balance.result.balance == (10000-9999, 0)
