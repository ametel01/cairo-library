import pytest
import os

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import (
    compile_starknet_files)

TOKEN_FILE = os.path.realpath(os.path.join(os.path.dirname(
    __file__), '..', 'contracts', 'finance', 'token', 'PSERC20.cairo'))

CONTRACT_FILE = os.path.realpath(os.path.join(os.path.dirname(
    __file__), '..', 'contracts', 'finance', 'VestingWallet.cairo'))


@pytest.fixture
async def contract():
    starknet = await Starknet.empty()
    token = await starknet.deploy(source=TOKEN_FILE,
                                  constructor_calldata=[1111, 2222, 10000, 00, 99999])
    contract = await starknet.deploy(source=CONTRACT_FILE,
                                     constructor_calldata=[
                                         12345, 365])
    return contract


@pytest.mark.asyncio
async def test_constructor(contract):
    data = await contract.beneficiary().call()
    assert data.result.address == 12345
    data = await contract.duration().call()
    assert data.result.duration == 365


@pytest.mark.asyncio
async def test_vesting_schedule(contract):
    await contract.vesting_schedule(1000, 00, 180).invoke()
    data = await contract.vesting_wallet_balance.call()
    assert data.result.amount_to_release == 100
