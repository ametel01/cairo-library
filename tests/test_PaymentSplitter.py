import pytest
import os

from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.testing.contract import StarknetContract
from starkware.starknet.compiler.compile import (
    compile_starknet_files)

TOKEN_FILE = os.path.realpath(os.path.join(os.path.dirname(
    __file__), '..', 'contracts', 'finance', 'token', 'PSERC20.cairo'))

CONTRACT_FILE = os.path.realpath(os.path.join(os.path.dirname(
    __file__), '..', 'contracts', 'finance', 'PaymentSplitter.cairo'))


@pytest.fixture
async def contract():
    starknet = await Starknet.empty()
    token = await starknet.deploy(source=TOKEN_FILE,
                                  constructor_calldata=[1111, 2222, 10000, 00, 99999])
    contract = await starknet.deploy(source=CONTRACT_FILE,
                                     constructor_calldata=[token.contract_address,
                                                           3, 12345, 98765, 56565,
                                                           3, 65, 00, 75, 0, 60, 0])
    return contract


@pytest.mark.asyncio
async def test_constructor(contract):
    data = await contract.tot_shares().call()
    assert data.result.tot_shares == (200, 0)
    data = await contract.shares(12345).call()
    assert data.result.shares == (65, 00)
    data = await contract.shares(98765).call()
    assert data.result.shares == (75, 00)
    data = await contract.payee(1).call()
    assert data.result.payee == 98765
    data = await contract.payee(2).call()
    assert data.result.payee == 12345
    data = await contract.payee(0).call()
    assert data.result.payee == 56565


@pytest.mark.asyncio
async def test_release(contract,):
    await contract.release_erc20(12345).invoke()
    await contract.release_erc20(98765).invoke()
    await contract.release_erc20(56565).invoke()
    data = await contract.balance_of(12345).call()
    assert data.result.balance == (3250, 0)
    data = await contract.balance_of(98765).call()
    assert data.result.balance == (3750, 0)
    data = await contract.balance_of(56565).call()
    assert data.result.balance == (3000, 0)
