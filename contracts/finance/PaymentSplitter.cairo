%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
# from finance.token.ERC20_base import ERC20_transfer
# from Cairo.cairo_library.contracts.finance.token.ERC20_base import ERC20_transfer
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_mul,
    uint256_signed_div_rem)
from contracts.finance.PaymentSplitter_base import (
    _token_balance, _total_shares, _total_released, _shares, _released_to_payee, _payees,
    _erc20_total_released, _erc20_realeased, _payees_balances, pending_payment, add_payee,
    add_payee_recursive, _transfer)

#
# Contstructor
#

# @dev Creates an instance of `PaymentSplitter` where each account in `payees` is assigned the number of shares at
# the matching position in the `shares` array.
#
# All addresses in `payees` must be non-zero. Both arrays must have the same non-zero length, and there must be no
# duplicates in `payees`.
@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        token_deposited : Uint256, payees_len : felt, payees : felt*, shares_len : felt,
        shares : Uint256*):
    assert payees_len = shares_len
    let (not_zero) = uint256_lt(Uint256(0, 0), token_deposited)
    assert_not_zero(not_zero)
    assert_not_zero(payees_len)
    _token_balance.write(token_deposited)
    add_payee_recursive(lenght=payees_len, payees=payees, shares=shares)
    return ()
end

#
# view functions
#
@view
func balance_of{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        address : felt) -> (balance : Uint256):
    let (res) = _payees_balances.read(address)
    return (res)
end

# @dev Getter for the total shares held by payees.
@view
func tot_shares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        tot_shares : Uint256):
    let (shares) = _total_shares.read()
    return (tot_shares=shares)
end

# @dev Getter for the total amount of Ether already released.
@view
func tot_released{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}() -> (
        tot_released : Uint256):
    let (released) = _total_released.read()
    return (tot_released=released)
end

# @dev Getter for the amount of shares held by an account.
@view
func shares{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(account : felt) -> (
        shares : Uint256):
    let (shares) = _shares.read(account)
    return (shares=shares)
end

# @dev Getter for the address of the payee number `index`.
@view
func payee{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(id : felt) -> (
        payee : felt):
    let (payee) = _payees.read(id)
    return (payee=payee)
end

# # add_payee_recursive(lenght=payees_len, payees=payees, shares=shares)
#     return()
# end

# @dev Triggers a transfer to `account` of the amount of Ether they are owed, according to their percentage of the
# total shares and their previous withdrawals.
@external
func release_erc20{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        account : felt):
    alloc_locals
    let (shares) = _shares.read(account)
    let (erc20_balance) = _token_balance.read()
    let (total_released) = _total_released.read()
    let (total_received, _) = uint256_add(erc20_balance, total_released)
    let (released) = _released_to_payee.read(account)
    let (payment) = pending_payment(
        account=account, total_received=total_received, already_released=released)
    # assert_not_zero(p_payment)

    _released_to_payee.write(account, payment)
    let (new_total_released, _) = uint256_add(total_released, payment)
    _total_released.write(new_total_released)

    _transfer(recipient=account, amount=payment)
    return ()
end
