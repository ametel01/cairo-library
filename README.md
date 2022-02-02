# Cairo Library

Contracts inspired to OpenZeppelin's solidity library. This project is in continuos evolution.

## Contracts

<ul>
<li> 
<h3>PaymentSplitter</h3> </li>

Allows to split ERC20 token payments among a group of accounts. The sender does not need to be aware that the token will be split in this way, since it is handled transparently by the contract.

The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim an amount proportional to the percentage of total shares they were assigned.

It requires an ERC20 contract to be deployed with the full token balance minted to an account (this set up is temporary, i am thinking about a multisig for this purpose). The ERC20 contracts in this repository have been modified to be compatible with PaymentSplitter.

`PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release} function.

Rebasing tokens, and tokens that apply fees during transfers, are likely to not be supported as expected.

If in doubt, we encourage you to run tests before sending real value to this contract.

### Disclaimer

The contracts are not audited and at a very early stage of development, use with at own risk.
