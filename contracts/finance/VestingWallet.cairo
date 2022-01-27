%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_mul,
    uint256_signed_div_rem)


@storage_var
func _balance() -> (balance : Uint256):
end

@storage_var
func _beneficiary() -> (address : felt):
end

# Start block of the vesting
@storage_var
func _start() -> (block : felt):
end

# Duration in number of blocks of the vesting
@storage_var
func _duration() -> (n_blocks : felt):
end

@external
func beneficiary{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (res : felt):
    let (res) = _beneficiary.read()
    return(res=res)
end

@external
func start_block{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (res : felt):
    let (res) = _start.read()
    return(res=res)
end

@external
func daration{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }() -> (res : felt):
    let (res) = _duration.read()
    return(res=res)
end