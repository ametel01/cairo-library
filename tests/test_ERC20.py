from unicodedata import name
import pytest
import os

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import (
    compile_starknet_files)

CONTRACT_FILE = "/home/ametel01/Source/Cairo/cairo_library/contracts/finance/token/ERC20.cairo"


@pytest.mark.asyncio
async def test_constructor():
    contract_definition = compile_starknet_files(
        [CONTRACT_FILE], debug_info=True)
    starknet = await Starknet.empty()
    contract = await starknet.deploy(source=CONTRACT_FILE,
                                     constructor_calldata=[1111, 2222, 10000, 00, 12345])

    name = await contract.name().call()
    assert name.result.name == 1111
    symbol = await contract.symbol().call()
    assert symbol.result.symbol == 2222
    supply = await contract.totalSupply().call()
    assert supply.result.totalSupply == (10000, 0)
