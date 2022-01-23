%lang starknet

@contract_interface
namespace IERC20:
    func name() -> (name : felt):
    end

    func symbol() -> (symbol : felt):
    end

    func decimals() -> (decimals : felt):
    end

    func totalSupply() -> (totalSupply : felt):
    end

    func balanceOf(account : felt) -> (balance : felt):
    end

    func allowance(owner : felt, spender : felt) -> (remaining : felt):
    end

    func transfer(recipient : felt, amount : felt) -> (success : felt):
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
