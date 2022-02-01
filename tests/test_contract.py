from unicodedata import name
import pytest
import os

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import (
    compile_starknet_files)

CONTRACT_FILE = os.path.join(
    os.path.dirname(__file__), "ERC20.cairo")


@pytest.fixture(scope='module')
async def get_starknet():
    starknet = await Starknet.empty()
    return starknet


@pytest.mark.asyncio
async def contract_factory():
    contract_definition = compile_starknet_files(
        [CONTRACT_FILE], debug_info=True)
    starknet = await Starknet.empty()
    contract = await starknet.deploy(source=CONTRACT_FILE,
                                     constructor_calldata=[1111, 2222, 10000, 00, 12345])
    # contract = StarknetContract(
    #     starknet=starknet,
    #     abi=contract_definition.abi,
    #     contract_address=contract_address)

    info = await contract.symbol().call()
    assert info == 2222
