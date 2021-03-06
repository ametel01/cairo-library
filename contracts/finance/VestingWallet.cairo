%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.math import assert_not_zero, assert_le, unsigned_div_rem
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_mul,
    uint256_signed_div_rem)
from contracts.finance.token.IPSERC20 import IPSERC20
from contracts.finance.VestingWallet_base import (
    vesting_wallet_balance, 
    vesting_wallet_beneficiary, 
    vesting_wallet_duration, 
    vesting_wallet_start,
    vesting_wallet_token_released,

    _vesting_schedule
)

@constructor
func constructor{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(
        beneficiary_address :felt, 
        durantion_in_days : felt):
    assert_not_zero(beneficiary_address)
    assert_not_zero(duration)
    let (start) = get_block_timestamp()
    vesting_wallet_start.write(start)
    vesting_wallet_beneficiary.write(beneficiary_address)
    vesting_wallet_duration.write(durantion_in_days)
    return()
end

@external
func balance{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (account_balance : Uint256):
    let (account_balance) = vesting_wallet_balance.read()
    return(account_balance)
end

@external
func beneficiary{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (beneficiary : felt):
    let (beneficiary) = vesting_wallet_beneficiary.read()
    return(beneficiary)
end

@external
func start_timestamp{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (timestamp : felt):
    let (timestamp) = vesting_wallet_start.read()
    return(timestamp)
end

@external
func duration{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (duration : felt):
    let (days) = vesting_wallet_duration.read()
    return(duration=days)
end

@external
func token_released{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (released : Uint256):
    let (res) = vesting_wallet_token_released.read()
    return(released=res)
end

@external
func vested_amount{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (releaseble_amount : Uint256):
    let (allocation : Uint256) = vesting_wallet_balance.read()
    let (timestamp) = get_block_timestamp()
    let (releaseble_amount) = _vesting_schedule(total_allocation=allocation, current_timestamp=timestamp)
    return (releaseble_amount)
end

