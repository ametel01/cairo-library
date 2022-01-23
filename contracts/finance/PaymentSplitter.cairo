%lang starknet
%builtins pedersen range_check

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero, unsigned_div_rem
from finance.token.ERC20_base import ERC20_transfer
#from Cairo.cairo_library.contracts.finance.token.ERC20_base import ERC20_transfer


#
# storage
#
@storage_var
func _eth_balance() -> (balance : felt):
end

@storage_var
func _total_shares() -> (shares : felt):
end

@storage_var
func _total_released() -> (released : felt):
end

@storage_var
func _shares(address : felt) -> (shares : felt):
end

# @dev amount of shares released to an address.
@storage_var
func _released(address : felt) -> (amount : felt):
end

@storage_var
func _payees(i : felt) -> (payee : felt):
end

# @dev total amount of token released.
# @param erc20: address of token contract.
@storage_var
func _erc20_total_released(erc20 : felt) -> (amount : felt):
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
    let (released) = _total_released.read()
    return (released)
end

# @dev Getter for the total amount of `token` already released. `token`
# should be the address of an IERC20 contract.
@view
func erc20_released{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(token : felt) -> (tot_released : felt):
    let (token_released) = _erc20_total_released.read(token)
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
func eth_released{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(account : felt) -> (released : felt):
    let (released) = _released.read(account)
    return (released)
end

# @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
# IERC20 contract.
@view
func released{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(token : felt, address : felt) -> (released : felt):
    let (released) = _erc20_realeased.read(token, address)
    return (released)
end

# @dev Getter for the address of the payee number `index`.
@view
func payee{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(id : felt) -> (payee : felt):
    let (payee) = _payees.read(id)
    return (payee)
end

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
        }(payees_len : felt, payees : felt*, shares_len : felt, shares : felt*):
    assert payees_len = shares_len
    assert_not_zero(payees_len)
    add_payee_recursive(lenght=payees_len, payees=payees, shares=shares)
    return ()
end

# # add_payee_recursive(lenght=payees_len, payees=payees, shares=shares)
#     return()
# end

# @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
# total shares and their previous withdrawals.
@external
func release_eth{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(account : felt):
    alloc_locals
    let (shares) = _shares.read(account)
    let (eth_balance) = _eth_balance.read()
    let (total_released) = _total_released.read()
    let total_received = eth_balance + total_released
    let (released) = _released.read(account)
    let (payment) = pending_payment(account, total_received, released)
    # assert_not_zero(p_payment)

    _released.write(account, payment)
    let new_total_released = total_released + payment
    _total_released.write(new_total_released)

    ERC20_transfer(account, payment)
    return ()
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
        }(account : felt, total_received : felt, already_released : felt) -> (res : felt):
    alloc_locals
    local syscall_ptr : felt* = syscall_ptr
    let (shares) = _shares.read(account)
    let (tot_shares) = _total_shares.read()
    let dividend = total_received * shares
    let divisor = tot_shares - already_released
    let (res, _) = unsigned_div_rem(dividend, divisor)
    return (res)
end

# @dev Add a new payee to the contract.
# @param id      The id of the account
# @param account The address of the payee to add.
# @param shares_ The number of shares owned by the payee.
func _add_payee{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(i : felt, address : felt, shares : felt):
    assert_not_zero(address)
    # assert_not_zero(shares) # TODO
    let (account_shares) = _shares.read(address)

    _payees.write(i, address)
    _shares.write(address, shares)
    let (tot_shares) = _total_shares.read()
    let shares_to_write = tot_shares + shares
    _total_shares.write(shares_to_write)
    return ()
end
# @dev recursively add payees and shares when the contract is deployed
#
func add_payee_recursive{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*, 
        range_check_ptr
        }(lenght : felt, payees : felt*, shares : felt*):
    if lenght == 0:
        return ()
    end

    add_payee_recursive(lenght=lenght - 1, payees=payees + 1, shares=shares + 2)

    _add_payee(i=lenght - 1, address=[payees], shares=[shares])
    return ()
end
