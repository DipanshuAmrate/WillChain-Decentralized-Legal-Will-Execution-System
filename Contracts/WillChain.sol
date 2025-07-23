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
    event BeneficiaryUpdated(address indexed testator, address indexed oldBeneficiary, address indexed newBeneficiary);
    event UnlockTimeExtended(address indexed testator, uint256 oldTime, uint256 newTime);
    event WillCancelled(address indexed testator, uint256 refundedAmount);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

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

    // ---------------- Additional Useful Functions ----------------

    // Allows the testator to update the beneficiary before execution
    function updateBeneficiary(address _newBeneficiary) external {
        Will storage will = wills[msg.sender];
        require(!will.isExecuted, "Will already executed");
        require(will.amount > 0, "Will not found");

        address oldBeneficiary = will.beneficiary;
        will.beneficiary = _newBeneficiary;

        emit BeneficiaryUpdated(msg.sender, oldBeneficiary, _newBeneficiary);
    }

    // Allows testator to extend unlock time (not reduce it)
    function extendUnlockTime(uint256 _newUnlockTime) external {
        Will storage will = wills[msg.sender];
        require(!will.isExecuted, "Will already executed");
        require(_newUnlockTime > will.unlockTime, "New time must be greater than current");

        uint256 oldTime = will.unlockTime;
        will.unlockTime = _newUnlockTime;

        emit UnlockTimeExtended(msg.sender, oldTime, _newUnlockTime);
    }

    // Allows testator to cancel will and refund ETH before execution
    function cancelWill() external {
        Will storage will = wills[msg.sender];
        require(!will.isExecuted, "Will already executed");
        require(will.amount > 0, "No will to cancel");

        uint256 refund = will.amount;
        will.amount = 0;
        will.isExecuted = true;

        payable(msg.sender).transfer(refund);

        emit WillCancelled(msg.sender, refund);
    }

    // View complete will details including testator
    function getAllWillDetails(address _testator) external view returns (
        address testator,
        address beneficiary,
        uint256 amount,
        bool isExecuted,
        uint256 unlockTime
    ) {
        Will memory will = wills[_testator];
        return (will.testator, will.beneficiary, will.amount, will.isExecuted, will.unlockTime);
    }

    // Admin function: Transfer ownership of the contract
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Invalid address");
        address oldOwner = owner;
        owner = _newOwner;

        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    // --------------------------------------------------------------------
    // 🔚 All above are newly added utility functions with events and checks
}
