%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_not_zero
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check, uint256_mul, uint256_signed_div_rem
)
from contracts.finance.token.IPSERC20 import IPSERC20

#
# storage
#

@storage_var
func payment_splitter_token_address() -> (address : felt):
end

@storage_var
func payment_splitter_total_shares() -> (shares : Uint256):
end

@storage_var
func payment_splitter_total_released() -> (released : Uint256):
end

@storage_var
func payment_splitter_shares(address : felt) -> (shares : Uint256):
end

# @dev amount of shares released to an address.
@storage_var
func payment_splitter_released_to_payee(address : felt) -> (amount : Uint256):
end

@storage_var
func payment_splitter_payees(i : felt) -> (payee : felt):
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
    local syscalls
    let (account_shares) = payment_splitter_shares.read(account)
    let (tot_shares) = payment_splitter_total_shares.read()
    let (token_address) = payment_splitter_token_address.read()
    let (tot_supply) = IPSERC20.totalSupply(contract_address=token_address)
    let (dividend, _) = uint256_mul(tot_supply, account_shares)
    let (res, _) = uint256_signed_div_rem(dividend, tot_shares)
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
    let (account_shares) = payment_splitter_shares.read(address)

    payment_splitter_payees.write(i, address)
    payment_splitter_shares.write(address, shares)
    let (tot_shares) = payment_splitter_total_shares.read()
    let (shares_to_write, _) = uint256_add(tot_shares, shares)
    payment_splitter_total_shares.write(shares_to_write)
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




