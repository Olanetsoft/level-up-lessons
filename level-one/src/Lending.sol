// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract Lending {

    address public owner;

    constructor() {
        // Set the contract deployer as the owner
        owner = msg.sender;
    }

    // Modifier that only allows the owner of the contract to execute the function
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }


    // create a mapping to track users balances
    mapping(address => uint) public balances;
    // create a mapping to track borrowed amount
    mapping(address => uint) public borrowedAmount;

    // mapping to track when a user borrowed
    mapping(address => uint) public borrowTime;


    // constant for interet calculation
    uint256 public constant INTEREST_RATE = 2;
    // constant for time calculation
    uint256 public constant SECONDS_PER_YEAR = 31536000;

    // add events for different activities
    event Borrow(address indexed borrower, uint amount);
    event Deposit(address indexed depositor, uint amount);
    event Withdraw(address indexed withdrawer, uint amount);
    event PayOff(address indexed borrower, uint amount);

    // check if the user has enough value to send
    modifier hasEnoughValue(uint _amount) {
        require(msg.value >= _amount, "Not enough value sent");
        _;
    }

    // Check to make sure user does not send less than 0.01 ether
    modifier hasEnoughEther() {
        require(msg.value >= 0.01 ether, "Minimum deposit is 0.01 ether");
        _;
    }

    // check if the user has enough balance to withdraw
    modifier hasEnoughBalance(uint _amount) {
        require(balances[msg.sender] >= _amount, "Not enough balance");
        _;
    }

    // check if the user has an active loan
    modifier hasActiveLoan() {
        require(borrowedAmount[msg.sender] > 0, "No active loan");
        _;
    }

    // check if the user has enough collateral
    modifier hasEnoughCollateral() {
        require(balances[msg.sender] >= borrowedAmount[msg.sender], "Not enough collateral");
        _;
    }

    function deposit() public payable hasEnoughValue(msg.value) hasEnoughEther() {
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint _amount) external hasEnoughBalance(_amount) {
        balances[msg.sender] -= _amount;
        
        emit Withdraw(msg.sender, _amount);
        payable(msg.sender).transfer(_amount);
 
    }

    function borrow(uint _amount) external payable hasEnoughCollateral() {
        require(borrowedAmount[msg.sender] == 0, "Pay off your loan first");
        require(address(this).balance >= _amount, "Contract does not have enough funds to lend, sorry");

        // set the borrowed amount
        borrowedAmount[msg.sender] += _amount;

        // set the borrow time
        borrowTime[msg.sender] = block.timestamp;

        // emit the borrow event
        emit Borrow(msg.sender, _amount);

        // transfer the amount to the user from the contract
        payable(msg.sender).transfer(_amount);
    }

    function payOff() external payable hasActiveLoan() {
    // Calculate the interest
    uint interest = (borrowedAmount[msg.sender] * INTEREST_RATE * (block.timestamp - borrowTime[msg.sender])) / SECONDS_PER_YEAR;
    uint totalAmount = borrowedAmount[msg.sender] + interest;

    require(msg.value >= totalAmount, "Not enough value sent");

    uint overpayment = msg.value - totalAmount; // Calculate any overpayment

    // Reset the borrowed amount and borrow time
    borrowedAmount[msg.sender] = 0;
    borrowTime[msg.sender] = 0;

    // Refund any overpayment
    if (overpayment > 0) {
        payable(msg.sender).transfer(overpayment);
    }

    // Emit the pay off event
    emit PayOff(msg.sender, totalAmount);
}


    // fallback function to receive ether when sent to the contract directly 
    // I don't think i need this in this execise, haha 
    //i learnt it the hard way the first time i ever deployed a contract and my money got stuck on the contract
    // receive() external payable {}

    // function to get the balance of the contract
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    // withdraw the balance of the contract to the owner
    function withdrawBalance() external onlyOwner() {
        payable(msg.sender).transfer(getBalance());
    }
}