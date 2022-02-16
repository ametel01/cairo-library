%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, assert_le, unsigned_div_rem
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_mul,
    uint256_signed_div_rem)


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

func _vesting_schedule{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(total_allocation : Uint256, current_timestamp : felt) -> (amount_to_release : Uint256):
    alloc_locals
    let (local start) = vesting_wallet_start.read()
    let (local durantion) = vesting_wallet_duration.read()
    assert_le(start, current_timestamp)
    let factor1 = current_timestamp - start
    let (div, _) = uint256_mul(Uint256(factor1,0), total_allocation)
    let (amount, _) = uint256_signed_div_rem(div, Uint256(durantion,0))
    return (amount_to_release=amount)
end