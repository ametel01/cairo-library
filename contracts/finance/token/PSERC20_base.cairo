%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero
from starkware.cairo.common.uint256 import (
    Uint256, uint256_add, uint256_sub, uint256_le, uint256_lt, uint256_check
)

#
# Storage
#

@storage_var
func PSERC20_name() -> (name : felt):
end

@storage_var
func PSERC20_symbol() -> (symbol : felt):
end

@storage_var 
func PSERC20_decimals() -> (decimals : felt):
end

@storage_var
func PSERC20_total_supply() -> (total_supply : Uint256):
end

@storage_var
func PSERC20_balances(account : felt) -> (balance : Uint256):
end

@storage_var
func PSERC20_owner() -> (account : felt):
end

#
# Constructor
#

func PSERC20_initializer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name : felt,
        symbol : felt,
        initial_supply : Uint256,
        recipient : felt
    ):
    PSERC20_name.write(name)
    PSERC20_symbol.write(symbol)
    PSERC20_decimals.write(18)
    PSERC20_mint(recipient, initial_supply)
    PSERC20_owner.write(recipient)
    return ()
end

func PSERC20_transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient : felt, amount : Uint256):
    let (sender) = PSERC20_owner.read()
    _transfer(sender, recipient, amount)
    return ()
end

func PSERC20_transferFrom{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        sender : felt, 
        recipient : felt, 
        amount : Uint256
    ) -> ():
    # let (local caller) = get_caller_address()
    # let (local caller_allowance : Uint256) = ERC20_allowances.read(owner=sender, spender=caller)

    _transfer(sender, recipient, amount)

    return ()
end

func PSERC20_mint{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient : felt, amount : Uint256):
    alloc_locals
    assert_not_zero(recipient)
    uint256_check(amount)

    let (balance : Uint256) = PSERC20_balances.read(account=recipient)
    # overflow is not possible because sum is guaranteed to be less than total supply
    # which we check for overflow below
    let (new_balance, _: Uint256) = uint256_add(balance, amount)
    PSERC20_balances.write(recipient, new_balance)

    let (local supply : Uint256) = PSERC20_total_supply.read()
    let (local new_supply : Uint256, is_overflow) = uint256_add(supply, amount)
    assert (is_overflow) = 0

    PSERC20_total_supply.write(new_supply)
    return ()
end

#
# Internal
#

func _transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(sender : felt, recipient : felt, amount : Uint256):
    alloc_locals
    assert_not_zero(sender)
    assert_not_zero(recipient)
    uint256_check(amount) # almost surely not needed, might remove after confirmation

    let (local sender_balance : Uint256) = PSERC20_balances.read(account=sender)

    # validates amount <= sender_balance and returns 1 if true
    let (enough_balance) = uint256_le(amount, sender_balance)
    assert_not_zero(enough_balance)

    # subtract from sender
    let (new_sender_balance : Uint256) = uint256_sub(sender_balance, amount)
    PSERC20_balances.write(sender, new_sender_balance)

    # add to recipient
    let (recipient_balance : Uint256) = PSERC20_balances.read(account=recipient)
    # overflow is not possible because sum is guaranteed by mint to be less than total supply
    let (new_recipient_balance, _: Uint256) = uint256_add(recipient_balance, amount)
    PSERC20_balances.write(recipient, new_recipient_balance)
    return ()
end