%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.uint256 import Uint256

from contracts.finance.token.PSERC20_base import (
    PSERC20_name,
    PSERC20_symbol,
    PSERC20_total_supply,
    PSERC20_decimals,
    PSERC20_balances,

    PSERC20_initializer,
    PSERC20_transfer,
)

@constructor
func constructor{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        name : felt,
        symbol : felt,
        initial_supply : Uint256,
        recipient : felt
    ):
    PSERC20_initializer(name, symbol, initial_supply, recipient)
    return ()
end

#
# Getters
#

@view
func name{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (name : felt):
    let (name) = PSERC20_name.read()
    return (name)
end

@view
func symbol{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (symbol : felt):
    let (symbol) = PSERC20_symbol.read()
    return (symbol)
end

@view
func totalSupply{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (totalSupply : Uint256):
    let (totalSupply : Uint256) = PSERC20_total_supply.read()
    return (totalSupply)
end

@view
func decimals{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }() -> (decimals : felt):
    let (decimals) = PSERC20_decimals.read()
    return (decimals)
end

@view
func balanceOf{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(account : felt) -> (balance : Uint256):
    let (balance : Uint256) = PSERC20_balances.read(account)
    return (balance)
end

@external
func transfer{
        syscall_ptr : felt*, 
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(recipient : felt, amount : Uint256) -> (success : felt):
    PSERC20_transfer(recipient, amount)
    # Cairo equivalent to 'return (true)'
    return (1)
end



