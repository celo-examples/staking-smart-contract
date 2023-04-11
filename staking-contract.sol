// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StakingMechanism {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public timeStaked;

    uint256 public minimumStake = 100 ether;
    uint256 public rewardRate = 1 ether;
    uint256 public minimumStakeTime = 7 days;
    uint256 public constant maximumStakeDuration = 30 days;

    address public owner;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only the contract owner can call this function"
        );
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setMinimumStake(uint256 newMinimumStake) public onlyOwner {
        minimumStake = newMinimumStake;
    }

    function setRewardRate(uint256 newRewardRate) public onlyOwner {
        rewardRate = newRewardRate;
    }

    function stake() public payable {
        require(
            msg.value >= minimumStake,
            "Staking amount must be at least 100 ether"
        );
        balances[msg.sender] += msg.value;
        timeStaked[msg.sender] = block.timestamp;
        emit Staked(msg.sender, msg.value);
    }

    function balanceOf(address user) public view returns (uint256) {
        return balances[user];
    }

    function unstake() public {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "No balance to unstake");
        uint256 _timeStaked = timeStaked[msg.sender];
        uint256 timeElapsed = block.timestamp - _timeStaked;
        require(
            timeElapsed >= minimumStakeTime,
            "You must wait at least 7 days before unstaking"
        );
        uint256 reward = rewardRate * timeElapsed;
        balances[msg.sender] = 0;
        timeStaked[msg.sender] = 0;
        emit Unstaked(msg.sender, balance, reward);
        payable(msg.sender).transfer(balance + reward);
    }

    function withdraw() public onlyOwner {
        payable(owner).transfer(address(this).balance);
    }

    function withdrawReward() public {
        uint256 balance = balances[msg.sender];
        uint256 _timeStaked = timeStaked[msg.sender];
        uint256 timeElapsed = block.timestamp - _timeStaked;
        uint256 reward = rewardRate * timeElapsed;
        require(reward > 0, "No rewards to withdraw");
        balances[msg.sender] = balance;
        timeStaked[msg.sender] = block.timestamp;
        payable(msg.sender).transfer(reward);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner address is invalid");
        owner = newOwner;
    }

    function extendStakeDuration() public {
        uint256 _timeStaked = timeStaked[msg.sender];
        uint256 timeElapsed = block.timestamp - _timeStaked;
        require(
            timeElapsed < maximumStakeDuration,
            "You cannot extend your stake duration any further"
        );
        uint256 remainingTime = maximumStakeDuration - timeElapsed;
        require(
            remainingTime >= minimumStakeTime,
            "You must wait at least 7 days before extending your stake duration again"
        );
        uint256 extensionReward = rewardRate * remainingTime;
        balances[msg.sender] += extensionReward;
        timeStaked[msg.sender] = block.timestamp;
    }

    function splitStake(uint256[] memory amounts) public {
        uint256 totalAmount = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            require(
                amounts[i] >= minimumStake,
                "Staking amount must be at least 100 ether"
            );
            totalAmount += amounts[i];
        }
        require(totalAmount == balances[msg.sender], "Invalid stake amounts");
        balances[msg.sender] = 0;
        timeStaked[msg.sender] = 0;
        for (uint256 i = 0; i < amounts.length; i++) {
            balances[msg.sender] += amounts[i];
            timeStaked[msg.sender] = block.timestamp;
            emit Staked(msg.sender, amounts[i]);
        }
    }
}
