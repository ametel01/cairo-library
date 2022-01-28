%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_mul, uint256_signed_div_rem
)

#
# storage
#

@storage_var
func _token_address() -> (address : felt):
end

@storage_var
func _payees_balances(address : felt) -> (balance : Uint256):
end

@storage_var
func _total_shares() -> (shares : Uint256):
end

@storage_var
func _total_released() -> (released : Uint256):
end

@storage_var
func _shares(address : felt) -> (shares : Uint256):
end

# @dev amount of shares released to an address.
@storage_var
func _released_to_payee(address : felt) -> (amount : Uint256):
end

@storage_var
func _payees(i : felt) -> (payee : felt):
end

# @dev total amount of token released.
# @param erc20: address of token contract.
@storage_var
func _erc20_total_released(erc20 : felt) -> (amount : Uint256):
end

# @dev total amount of token ierc20 released to an address
@storage_var
func _erc20_realeased(erc20 : felt, address : felt) -> (res : Uint256):
end

#
# Internal functions
#

# @dev internal logic for computing the pending payment of an `account` given
# the token historical balances and already released amounts.
func pending_payment{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
        }(account : felt, total_received : Uint256, already_released : Uint256) -> (res : Uint256):
    alloc_locals
    local syscall_ptr : felt* = syscall_ptr
    let (shares) = _shares.read(account)
    let (tot_shares) = _total_shares.read()
    let (dividend, _) = uint256_mul(total_received, shares)
    let (divisor) = uint256_sub(tot_shares, already_released)
    let (res, _) = uint256_signed_div_rem(dividend, divisor)
    return (res=res)
end

# @dev Add a new payee to the contract.
# @param id      The id of the account
# @param account The address of the payee to add.
# @param shares_ The number of shares owned by the payee.
func add_payee{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(i : felt, address : felt, shares : Uint256):
    assert_not_zero(address)
    # assert_not_zero(shares) # TODO
    let (account_shares) = _shares.read(address)

    _payees.write(i, address)
    _shares.write(address, shares)
    let (tot_shares) = _total_shares.read()
    let (shares_to_write, _) = uint256_add(tot_shares, shares)
    _total_shares.write(shares_to_write)
    return ()
end
# @dev recursively add payees and shares when the contract is deployed
#
func add_payee_recursive{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(lenght : felt, payees : felt*, shares : Uint256*):
    if lenght == 0:
        return ()
    end

    add_payee_recursive(lenght=lenght - 1, payees=payees + 1, shares=shares + 2)

    add_payee(i=lenght - 1, address=[payees], shares=[shares])
    return ()
end

func _transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient : felt, amount : Uint256):
    let (curr_balance : Uint256) = _payees_balances.read(recipient)
    let new_balance = uint256_add(curr_balance, amount)
    _payees_balances.write(recipient, amount)
    return ()
end


