// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VotingSystem {
    IERC20 public token; // The ERC-20 token used for staking
    address public admin; // The contract admin
    uint256 public votingEnd; // Timestamp when voting ends

    struct Candidate {
        string name; // Candidate's name
        uint256 votes; // Total votes received
    }

    Candidate[] public candidates; // List of candidates
    mapping(address => bool) public hasVoted; // Tracks if an address has voted
    mapping(address => uint256) public stakedTokens; // Tracks staked tokens for each address

    event Voted(address indexed voter, uint256 indexed candidateIndex);
    event TokensStaked(address indexed staker, uint256 amount);
    event TokensWithdrawn(address indexed user, uint256 amount);

    constructor(address _tokenAddress, uint256 _votingDuration) {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_votingDuration > 0, "Voting duration must be positive");

        token = IERC20(_tokenAddress);
        admin = msg.sender;
        votingEnd = block.timestamp + _votingDuration;
    }

    modifier onlyBeforeEnd() {
        require(block.timestamp < votingEnd, "Voting has ended");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= votingEnd, "Voting is ongoing");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }

    function addCandidate(string memory _name) external onlyAdmin {
        require(bytes(_name).length > 0, "Candidate name cannot be empty");
        candidates.push(Candidate({name: _name, votes: 0}));
    }

    function stakeTokens(uint256 _amount) external onlyBeforeEnd {
        require(_amount > 0, "Stake amount must be greater than zero");

        uint256 allowance = token.allowance(msg.sender, address(this));
        uint256 balance = token.balanceOf(msg.sender);

        emit Debug(msg.sender, _amount, allowance, balance); // Add this line

        require(allowance >= _amount, "Insufficient allowance for token transfer");
        require(balance >= _amount, "Insufficient balance");

        token.transferFrom(msg.sender, address(this), _amount);

        stakedTokens[msg.sender] += _amount;

        emit TokensStaked(msg.sender, _amount);
    }

    event Debug(address indexed user, uint256 amount, uint256 allowance, uint256 balance);


    function vote(uint256 _candidateIndex) external onlyBeforeEnd {
        require(!hasVoted[msg.sender], "You have already voted");
        require(stakedTokens[msg.sender] > 0, "No staked tokens available");
        require(_candidateIndex < candidates.length, "Invalid candidate index");

        hasVoted[msg.sender] = true;
        candidates[_candidateIndex].votes++;

        emit Voted(msg.sender, _candidateIndex);
    }

    function withdrawTokens() external onlyAfterEnd {
        uint256 stakedAmount = stakedTokens[msg.sender];
        require(stakedAmount > 0, "No staked tokens to withdraw");

        stakedTokens[msg.sender] = 0;
        token.transfer(msg.sender, stakedAmount);

        emit TokensWithdrawn(msg.sender, stakedAmount);
    }

    function getWinner() external view onlyAfterEnd returns (string memory winnerName) {
        uint256 maxVotes = 0;
        bool tie = false;

        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].votes > maxVotes) {
                maxVotes = candidates[i].votes;
                winnerName = candidates[i].name;
                tie = false;
            } else if (candidates[i].votes == maxVotes) {
                tie = true;
            }
        }

        require(!tie, "Voting resulted in a tie"); // Tie case
        return winnerName;
    }

    function getCandidates() external view returns (Candidate[] memory) {
        return candidates;
    }
}
