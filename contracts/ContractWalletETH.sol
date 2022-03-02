//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";


contract ContractWalletETH is Initializable {

    // declare events
    event TransactionProposed(uint transactionID, address indexed sender);
    event Deposit(address indexed sender, uint value);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Execution(uint indexed transactionId, address indexed to, uint indexed amount);
    event ExecutionFailure(uint indexed transactionId);
    event PaidInFull(uint indexed amountPaidInFull);
    // Declare constants


    // Declare mappings/storage
    Transaction[] public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    
    address payable public client;
    address payable public freelancer;
    address payable public WorkDAO;
    uint public required = 2;
    uint public transactionCount = 0;
    address[] public users;
    bool public isLumpSumFlag;
    uint public totalPayout;
    uint public numberOfSuccessfulTransactions = 0;
    bytes32 public acceptanceCriteriaHash;
    bool public isInitialized;
    address public factoryAddress;
    bool public lockFactoryAddress;

    // Royalty info
    address payable public ROYALTY_ADDRESS;
    uint public royaltyPercent = 5;

    struct Transaction {
        address destination;
        uint value;
        bool executed;
        uint numOfConfirmations;
    }

    //modifiers
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0x0));
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == address(WorkDAO));
        _;
    }

    modifier isValidUser(address _address) {
        require(msg.sender == client || msg.sender == freelancer || msg.sender == WorkDAO || msg.sender == factoryAddress, "Not a valid address");
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactionId < transactions.length, "transaction does not exist");
        _;
    }
        
    modifier notExecuted(uint transactionId) {
        require(transactions[transactionId].executed == false, "This transaction has already been executed");
        _;
    }
        
    modifier notConfirmed(uint transactionId, address sender) {
        if(msg.sender != factoryAddress) {
            require(!confirmations[transactionId][msg.sender], "You have already confirmed this transaction");
        } else {
            require(!confirmations[transactionId][sender], "You have already confirmed this transaction");
        }
        _;
    }

    modifier isConfirmed(uint transactionId) {
        require(transactions[transactionId].numOfConfirmations == 2, "This transaction does not have enough signatures to execute. Must have 2 addresses confirm.");
        _;
    }

    modifier isUnlocked() {
        require(!lockFactoryAddress, "The factory address has already been set");
        _;
    }

    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    function setFactoryAddress(address factory) 
        public 
        isUnlocked
    {
        factoryAddress = factory;
        lockFactoryAddress = true;
    }

    function init(address payable _client, address payable _freelancer, address payable _DAO, bool _isLumpSumFlag, uint _totalPayout, address factory, address _royaltyAddress) 
        external 
        initializer
    {
        client  = _client;
        users.push(client);
        freelancer = _freelancer;
        users.push(_freelancer);
        WorkDAO = _DAO;
        users.push(_DAO);
        isLumpSumFlag = _isLumpSumFlag;
        totalPayout = _totalPayout;
        setFactoryAddress(factory);
        ROYALTY_ADDRESS = payable(_royaltyAddress);
    }

    constructor() initializer {}

    // allows for users to deposit money into the smart contract
    function deposit() external payable returns (bool success, uint balance) {
        success = true;
        balance = getBalance();
        emit Deposit(msg.sender, msg.value);
    }

    // function to change the wallet associated with the client
    function changeClient(address payable _newClient)
        onlyDAO
        public
        notNull(_newClient)
    {
        client = _newClient;
    }

    function changeFreelancer(address payable _newProvider) 
        onlyDAO
        notNull(_newProvider)
        public
    {
        freelancer = _newProvider;
    }

    function proposeTransaction(address payable _to, uint _value, address txSender)
        isValidUser(msg.sender)
        public
        returns (
            uint transactionId,
            address sender
        )
    {
        if(isLumpSumFlag) {
            require(_value == totalPayout, "This is a one time payment the value has to be the whole amount");
        }
        transactionId = transactions.length;
        transactions.push(
            Transaction({
                destination: _to,
                value: _value,
                executed: false,
                numOfConfirmations: 0
            })
        );
        confirmTransaction(transactionId, txSender);
        return(transactionId, msg.sender);
    }

    function confirmTransaction(uint transactionId, address sender)
        public
        isValidUser(msg.sender)
        transactionExists(transactionId)
        notExecuted(transactionId)
        notConfirmed(transactionId, sender)
        returns (uint Confirmations)
    {
        Transaction storage transaction = transactions[transactionId];
        transaction.numOfConfirmations += 1;
        confirmations[transactionId][msg.sender] = true;
        Confirmations = transaction.numOfConfirmations;
    }

    function executeTransaction(uint transactionId) 
        public 
        isValidUser(msg.sender)
        transactionExists(transactionId)
        notExecuted(transactionId)
        isConfirmed(transactionId)
        returns (
            uint id,
            address destination,
            uint balance
        )
    {
        Transaction storage transaction = transactions[transactionId];
        require(transaction.numOfConfirmations >= 2, "cannot execute transaction");
        transaction.executed = true;
        uint royaltyAmount_temp = transaction.value * royaltyPercent;
        uint royaltyAmount = royaltyAmount_temp / 100;

        (bool royaltySuccess, ) = ROYALTY_ADDRESS.call{value: royaltyAmount }("");
        require(royaltySuccess, "royalty transaction failed");
        (bool destinationSuccess, ) = payable(transaction.destination).call{value: transaction.value}("");
        require(destinationSuccess, "User transaction failed");
        emit Execution(transactionId, transaction.destination, transaction.value);
        balance = getBalance();
        return (
            transactionId,
            transaction.destination, 
            balance
        );
    }

    function revokeConfirmation(uint transactionId)
        public
        isValidUser(msg.sender)
        notExecuted(transactionId)
    {
        Transaction storage transaction = transactions[transactionId];
        require(confirmations[transactionId][msg.sender], "transaction has not yet been confirmed to revoke confirmation");
        
        transaction.numOfConfirmations -= 1;
        confirmations[transactionId][msg.sender] = false;

        emit Revocation(msg.sender, transactionId);
    }
    
    function getClient() public view returns (address) {
        return client;
    }

    function getFreelancer() public view returns (address) {
        return freelancer;
    }

    function getTransactionCount() public view returns (uint) {
        return transactions.length;
    }

    function getAcceptanceCriteriaHash() public view returns (bytes32) {
        return acceptanceCriteriaHash;
    }

    function getTransaction(uint transactionId)
        public 
        view
        isValidUser(msg.sender)
        returns (
            address destination,
            uint value,
            bool executed,
            uint numOfConfirmations
        )
    {
        Transaction storage transaction = transactions[transactionId];
        return (
            transaction.destination,
            transaction.value,
            transaction.executed,
            transaction.numOfConfirmations
        );
    }
}
