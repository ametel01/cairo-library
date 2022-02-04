%lang starknet

from starkware.cairo.common.uint256 import Uint256

@contract_interface
namespace IPSERC20:
    func name() -> (name : felt):
    end

    func symbol() -> (symbol : felt):
    end

    func decimals() -> (decimals : felt):
    end

    func totalSupply() -> (totalSupply : Uint256):
    end

    func balanceOf(account : felt) -> (balance : Uint256):
    end

    func transfer(recipient : felt, amount : Uint256) -> (success : felt):
    end

    func transferFrom(
            sender : felt, 
            recipient : felt, 
            amount : felt
        ) -> (success : felt):
    end

    func approve(spender : felt, amount : felt) -> (success : felt):
    end
end