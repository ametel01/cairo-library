%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero

# 
# storage
#

@storage_var
func _total_shares() -> (shares : felt):
end

@storage_var
func _shares(address: felt) -> (shares : felt):
end

@storage_var
func _realeased() -> (released : felt):
end

@storage_var
func _payees(i: felt) -> (payee : felt):
end

@storage_var
func _erc20_realeased(ierc20 : felt, address : felt) -> (res : felt):
end 

#
# view functions
#

# @dev Getter for the total shares held by payees.
@view
func tot_shares{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (tot_shares : felt):
    let (shares) = _total_shares.read()
    return (shares)
end

# @dev Getter for the total amount of Ether already released.
@view
func tot_released{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }() -> (tot_released : felt):
    let (released) = _realeased.read()
    return (released)
end

# @dev Getter for the total amount of `token` already released. `token` 
# should be the address of an IERC20
@view
func token_released{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(token : felt) -> (tot_released : felt):
    let (token_released) = _realeased.read()
    return (token_released)
end

# @dev Getter for the amount of shares held by an account.
@view
func shares{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(account : felt) -> (shares : felt):
    let (shares) = _shares.read(account)
    return (shares)
end

# @dev Getter for the amount of Ether already released to a payee.
@view
func released{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(account : felt) -> (released : felt):

# @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
# the matching position in the `shares` array.
#
# All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
# duplicates in `payees`.
@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        payees_len : felt, 
        payees : felt*,
        shares_len : felt,
        shares : felt*
    ):
    assert payees_len = shares_len
    assert_not_zero(payees_len)

    add_payee_recursive(lenght=payees_len, payees=payees, shares=shares)
    return()
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
    }(
        account : felt, 
        total_received : felt, 
        already_released : felt
    ) -> (res : felt):
    let (shares) = _shares.read(account)
    let (tot_shares) = _total_shares.read()
    let res = total_received * shares / tot_shares - already_released
    return (res)
end

# @dev Add a new payee to the contract.
# @param id      The id of the account
# @param account The address of the payee to add.
# @param shares_ The number of shares owned by the payee.
func add_payee{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(
        i : felt, 
        address : felt, 
        shares : felt
    ):
    assert_not_zero(address)
    assert_not_zero(shares)
    let (account_shares) = _shares.read(address)
    assert account_shares = 0

    _payees.write(i, address)
    _shares.write(address, shares)
    let (tot_shares) = _total_shares.read()
    _total_shares.write(tot_shares + shares)
    return()
end

func add_payee_recursive{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
    }(
        lenght : felt,
        payees : felt*,
        shares : felt*
    ):
    if lenght == 0:
        return()
    end

    add_payee_recursive(lenght=lenght - 1 , payees=payees + 1, shares=shares + 1)

    add_payee(i=lenght - 1, address=[payees], shares=[shares])
    return()
end
