// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract MultiSig{
    address[] public owner;
    uint public numOfConformationRequired;

    struct Transaction {
        address to;
        uint value;
        bool executed;
    }

    mapping (uint => mapping(address=>bool)) isConfirmed;
    Transaction[] public transcations;
    event TransactionSubmitted(address to, uint amount, uint transactionId);
    event TransactionConfirmed(uint transactionId);
    event TransactionExecuted(uint transactionId);

    modifier onlyOwner(){
        require(ownerCheck(), "you are not an owner");
        _;
    }
    
    constructor(address[] memory owners, uint _numOfConformationRequired){
        require(owners.length > 1, "Atleast two owners required");
        require(_numOfConformationRequired > 1 && _numOfConformationRequired <= owners.length, "Invalid confirmations");

        for(uint i=0; i<owners.length; i++){
            require(owners[i] != address(0), "Invalid owner address");
            owner.push(owners[i]);
        }

        numOfConformationRequired = _numOfConformationRequired;
    }

    function ownerCheck()private view returns(bool){
        for(uint i =0; i < owner.length; i++){
            if(owner[i] == msg.sender){
                return true;
            }
        }
        return false;
    }

    function submitTransaction(address _to) public payable {
        require(_to != address(0), "Invalid address");
        require(msg.value > 0, "Value must be greater than zero");

        uint transactionId = transcations.length;
        transcations.push(Transaction(_to, msg.value, false));
        emit TransactionSubmitted(_to, msg.value, transactionId);
    }

    function confirmTransaction(uint _transactionId) public onlyOwner{
        require(_transactionId < transcations.length, "Invlaid transaction Id");
        require(!isConfirmed[_transactionId][msg.sender], "Transaction already confirmed");
        isConfirmed[_transactionId][msg.sender] = true;
        emit TransactionConfirmed(_transactionId);
        if(isTransactionConfirmed(_transactionId)){
            executeTransaction(_transactionId);
        }
    }

    function executeTransaction(uint _transactionId) public payable{
        require(_transactionId < transcations.length, "Invlaid transaction Id");
        require(!transcations[_transactionId].executed, "Transaction already executed");
        (bool success, ) = transcations[_transactionId].to.call{value :transcations[_transactionId].value}("");
        require(success, "Transaction Execution failed");
        transcations[_transactionId].executed = true;
        emit TransactionExecuted(_transactionId);
    } 

    function isTransactionConfirmed(uint _transactionId) internal view returns(bool){
        require(_transactionId < transcations.length, "Invlaid transaction Id");
        uint confirmatonCount;

        for(uint i=0; i < owner.length; i++){
            if(isConfirmed[_transactionId][owner[i]]){
                confirmatonCount++;
                }
        }
        return confirmatonCount >= numOfConformationRequired;
    }
}