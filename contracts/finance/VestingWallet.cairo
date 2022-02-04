%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_block_timestamp
from starkware.cairo.common.math import assert_not_zero, assert_le, unsigned_div_rem
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_mul,
    uint256_signed_div_rem)
from contracts.finance.token.IPSERC20 import IPSERC20

const SECONDS_PER_YEAR = 86400

@storage_var
func vesting_wallet_balance() -> (balance : Uint256):
end

@storage_var
func vesting_wallet_token_released() -> (released : Uint256):
end

@storage_var
func vesting_wallet_beneficiary() -> (address : felt):
end

# Start block of the vesting
@storage_var
func vesting_wallet_start() -> (timestamp : felt):
end

# Duration in number of blocks of the vesting
@storage_var
func vesting_wallet_duration() -> (durantion : felt):
end

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
func beneficiary{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (res : felt):
    let (res) = vesting_wallet_beneficiary.read()
    return(res=res)
end

@external
func start_timestamp{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (res : felt):
    let (res) = vesting_wallet_start.read()
    return(res=res)
end

@external
func duration{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (res : felt):
    let (res) = vesting_wallet_duration.read()
    return(res=res)
end

@external
func token_released{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (res : Uint256):
    let (res) = vesting_wallet_token_released.read()
    return(res=res)
end

func _vesting_schedule{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(total_allocation : Uint256, timestamp : felt) -> (amount_to_release : Uint256):
    alloc_locals
    local amount_to_release : Uint256
    let (local start) = vesting_wallet_start.read()
    let (local durantion) = vesting_wallet_duration.read()
    assert_le(start, timestamp)
    let factor1 = timestamp - start
    let (div, _) = uint256_mul(Uint256(factor1,0), total_allocation)
    let (amount, _) = uint256_signed_div_rem(div, Uint256(durantion,0))
    return (amount_to_release=amount)
end





