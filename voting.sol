#  A base implementation in solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VotingSystem {
    IERC20 public token;
    address public admin;
    uint256 public votingEnd;

    struct Candidate {
        string name;
        uint256 votes;
    }

    Candidate[] public candidates;
    mapping(address => bool) public hasVoted;
    mapping(address => uint256) public stakedTokens;

    event Voted(address indexed voter, uint256 indexed candidateIndex);
    event TokensStaked(address indexed staker, uint256 amount);

    constructor(address _tokenAddress, uint256 _votingDuration) {
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

    function addCandidate(string memory _name) external {
        require(msg.sender == admin, "Only admin can add candidates");
        candidates.push(Candidate({name: _name, votes: 0}));
    }

    function stakeTokens(uint256 _amount) external onlyBeforeEnd {
        require(_amount > 0, "Stake amount must be greater than zero");
        token.transferFrom(msg.sender, address(this), _amount);
        stakedTokens[msg.sender] += _amount;

        emit TokensStaked(msg.sender, _amount);
    }

    function vote(uint256 _candidateIndex) external onlyBeforeEnd {
        require(!hasVoted[msg.sender], "Already voted");
        require(stakedTokens[msg.sender] > 0, "No staked tokens");

        hasVoted[msg.sender] = true;
        candidates[_candidateIndex].votes++;

        emit Voted(msg.sender, _candidateIndex);
    }

    function withdrawTokens() external onlyAfterEnd {
        uint256 stakedAmount = stakedTokens[msg.sender];
        require(stakedAmount > 0, "No staked tokens to withdraw");

        stakedTokens[msg.sender] = 0;
        token.transfer(msg.sender, stakedAmount);
    }

    function getWinner() external view onlyAfterEnd returns (string memory winnerName) {
        uint256 maxVotes = 0;
        for (uint256 i = 0; i < candidates.length; i++) {
            if (candidates[i].votes > maxVotes) {
                maxVotes = candidates[i].votes;
                winnerName = candidates[i].name;
            }
        }
    }
}
