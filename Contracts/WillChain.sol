// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract WillChain {
    address public owner;
    struct Will {
        address testator;
        address beneficiary;
        uint256 amount;
        bool isExecuted;
        uint256 unlockTime;
    }

    mapping(address => Will) public wills;

    event WillCreated(address indexed testator, address indexed beneficiary, uint256 amount, uint256 unlockTime);
    event WillExecuted(address indexed testator, address indexed beneficiary, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyTestator(address _testator) {
        require(msg.sender == _testator, "Not the testator");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createWill(address _beneficiary, uint256 _unlockTime) external payable {
        require(msg.value > 0, "Will must have funds");
        require(_unlockTime > block.timestamp, "Unlock time must be in future");

        Will memory newWill = Will({
            testator: msg.sender,
            beneficiary: _beneficiary,
            amount: msg.value,
            isExecuted: false,
            unlockTime: _unlockTime
        });

        wills[msg.sender] = newWill;

        emit WillCreated(msg.sender, _beneficiary, msg.value, _unlockTime);
    }

    function executeWill(address _testator) external {
        Will storage will = wills[_testator];
        require(!will.isExecuted, "Will already executed");
        require(block.timestamp >= will.unlockTime, "Unlock time not reached");
        require(msg.sender == will.beneficiary, "Only beneficiary can claim");

        will.isExecuted = true;
        payable(will.beneficiary).transfer(will.amount);

        emit WillExecuted(_testator, will.beneficiary, will.amount);
    }

    function getWill(address _testator) external view returns (address, uint256, bool, uint256) {
        Will memory will = wills[_testator];
        return (will.beneficiary, will.amount, will.isExecuted, will.unlockTime);
    }
}

