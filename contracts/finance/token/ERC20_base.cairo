%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin, SignatureBuiltin
from starkware.starknet.common.syscalls import get_caller_address
from starkware.cairo.common.math import assert_not_zero, assert_le


#
# Storage
#

@storage_var
func ERC20_name_() -> (name : felt):
end

@storage_var
func ERC20_symbol_() -> (symbol : felt):
end

@storage_var
func ERC20_decimals_() -> (decimals : felt):
end

@storage_var
func ERC20_total_supply() -> (total_supply : felt):
end

@storage_var
func ERC20_balances(account : felt) -> (balance : felt):
end

@storage_var
func ERC20_allowances(owner : felt, spender : felt) -> (allowance : felt):
end

#
# Constructor
#

func ERC20_initializer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name : felt,
        symbol : felt,
        initial_supply : felt,
        recipient : felt
    ):
    ERC20_name_.write(name)
    ERC20_symbol_.write(symbol)
    ERC20_decimals_.write(18)
    ERC20_mint(recipient, initial_supply)
    return ()
end

func ERC20_name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name : felt):
    let (name) = ERC20_name_.read()
    return (name)
end

func ERC20_symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol : felt):
    let (symbol) = ERC20_symbol_.read()
    return (symbol)
end

func ERC20_totalSupply{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (totalSupply : felt):
    let (totalSupply) = ERC20_total_supply.read()
    return (totalSupply)
end

func ERC20_decimals{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (decimals : felt):
    let (decimals) = ERC20_decimals_.read()
    return (decimals)
end

func ERC20_balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account : felt) -> (balance : felt):
    let (balance) = ERC20_balances.read(account)
    return (balance)
end

func ERC20_allowance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(owner : felt, spender : felt) -> (remaining : felt):
    let (remaining) = ERC20_allowances.read(owner, spender)
    return (remaining)
end

func ERC20_transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient : felt, amount : felt):
    let (sender) = get_caller_address()
    _transfer(sender, recipient, amount)
    return ()
end

func ERC20_transferFrom{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        sender : felt, 
        recipient : felt, 
        amount : felt
    ) -> ():
    alloc_locals
    let (local caller) = get_caller_address()
    let (local caller_allowance) = ERC20_allowances.read(owner=sender, spender=caller)

    # validates amount <= caller_allowance and returns 1 if true   
    assert_le(amount, caller_allowance)
    _transfer(sender, recipient, amount)

    # subtract allowance
    let new_allowance = caller_allowance - amount
    ERC20_allowances.write(sender, caller, new_allowance)
    return ()
end

func ERC20_approve{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(spender : felt, amount : felt):
    let (caller) = get_caller_address()
    assert_not_zero(caller)
    assert_not_zero(spender)
    #uint256_check(amount)     <-- TODO
    ERC20_allowances.write(caller, spender, amount)
    return ()
end

func ERC20_increaseAllowance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(spender : felt, added_value : felt) -> ():
    alloc_locals
    #uint256_check(added_value)      <-- TODO
    let (local caller) = get_caller_address()
    let (local current_allowance) = ERC20_allowances.read(caller, spender)

    # add allowance
    let new_allowance = current_allowance + added_value
    #assert (is_overflow) = 0    <-- TODO

    ERC20_approve(spender, new_allowance)
    return ()
end

func ERC20_decreaseAllowance{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(spender : felt, subtracted_value : felt) -> ():
    alloc_locals
    #uint256_check(subtracted_value)     <-- TODO
    let (local caller) = get_caller_address()
    let (local current_allowance) = ERC20_allowances.read(owner=caller, spender=spender)
    local new_allowance = current_allowance - subtracted_value

    # validates new_allowance < current_allowance and returns 1 if true   
    assert_le(new_allowance, current_allowance)

    ERC20_approve(spender, new_allowance)
    return ()
end

func ERC20_mint{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient : felt, amount : felt):
    alloc_locals
    assert_not_zero(recipient)
    #uint256_check(amount)   <-- TODO
 
    let (balance) = ERC20_balances.read(account=recipient)
    # overflow is not possible because sum is guaranteed to be less than total supply
    # which we check for overflow below
    let new_balance = balance + amount
    ERC20_balances.write(recipient, new_balance)

    let (local supply) = ERC20_total_supply.read()
    let new_supply = supply + amount
    #assert (is_overflow) = 0              <-- TODO

    ERC20_total_supply.write(new_supply)
    return ()
end

func ERC20_burn{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account : felt, amount : felt):
    alloc_locals
    assert_not_zero(account)
    #uint256_check(amount)   <-- TODO
    let (balance : felt) = ERC20_balances.read(account)
    # validates amount <= balance and returns 1 if true
    assert_le(amount, balance)
    
    let new_balance = balance - amount
    ERC20_balances.write(account, new_balance)

    let (supply) = ERC20_total_supply.read()
    let new_supply = supply - amount
    ERC20_total_supply.write(new_supply)
    return ()
end

#
# Internal
#

func _transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(sender : felt, recipient :  felt, amount : felt):
    alloc_locals
    assert_not_zero(sender)
    assert_not_zero(recipient)
    #uint256_check(amount) # almost surely not needed, might remove after confirmation

    let (local sender_balance) = ERC20_balances.read(account=sender)

    # validates amount <= sender_balance and returns 1 if true
    assert_le(amount, sender_balance)

    # subtract from sender
    let new_sender_balance = sender_balance - amount
    ERC20_balances.write(sender, new_sender_balance)

    # add to recipient
    let (recipient_balance) = ERC20_balances.read(account=recipient)
    # overflow is not possible because sum is guaranteed by mint to be less than total supply
    let new_recipient_balance = recipient_balance + amount
    ERC20_balances.write(recipient, new_recipient_balance)
    return ()
end