//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ContractWalletETH.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";


contract ContractCloneFactory {

    // Events
    event ContractProposed(uint indexed ProposalId, address indexed sender, address indexed to);
    event ContractConfirmed(uint indexed ProposalId, address indexed sender, uint indexed confirmations);
    event ProxyDeployed(address indexed proxyAddress, uint indexed instanceId, uint indexed ProposalId);
    event TransactionProposed(uint indexed transactionId, uint indexed contractId, address indexed sender);
    event TransactionConfirmed(uint indexed transactionId, uint indexed contractId, address indexed sender);
    event TransactionExecuted(uint indexed transactionId, uint indexed contractId, uint indexed balance);


    mapping(address => bool) public isInstantiation;
    mapping(address => mapping(address => ContractWalletETH)) public instantiations;
    mapping(uint => Proposal) public proposals;
    mapping(address => mapping(uint => bool)) public confirmations;

    uint public instantiationCount;
    address payable public DAO;
    ContractWalletETH public ProjectContract;
    address public contractWalletImplementation;
    Proxy[] public allProxyInstances;
    uint public numOfProxies;
    address payable public RoyaltyAddress;



    struct Proposal {
        address payable client;
        address payable freelancer;
        bool oneTimePayment;
        uint totalPayout;
        uint confirmations;
        bool deployed;
    }

    struct Proxy {
        address proxyAddress;
        address client;
        address freelancer;
    }

    constructor(address implementationAddress, address _royaltyAddress) {
        contractWalletImplementation = implementationAddress;
        instantiationCount = 0;
        numOfProxies = 0;
        RoyaltyAddress = payable(_royaltyAddress);
    }

    function proposeContract (address payable clientAddress, address payable freelancerAddress, bool _oneTimePayment, uint _totalPayout) 
        public 
        returns (uint id)
    {
        address otherUser;
        if(msg.sender == address(clientAddress)) {
            otherUser = address(freelancerAddress);
        } else {
            otherUser = address(clientAddress);
        }
        Proposal memory newProposal = Proposal(clientAddress, freelancerAddress, _oneTimePayment,  _totalPayout, 0, false);
        proposals[instantiationCount] = newProposal;
        id = instantiationCount;
        emit ContractProposed(id, msg.sender, otherUser);
        confirmProposal(instantiationCount);
        instantiationCount += 1;
    }

    function confirmProposal(uint _proposalId) 
        public
    {
        Proposal storage proposal = proposals[_proposalId];
        require(msg.sender == address(proposal.client) || msg.sender == address(proposal.freelancer), "You are not a user involed with this proposal");
        require(!confirmations[msg.sender][_proposalId], "Sorry you have already confirmed this proposal");
        confirmations[msg.sender][_proposalId] = true;
        proposal.confirmations += 1;
        emit ContractConfirmed(_proposalId, msg.sender, proposal.confirmations);
        //if(proposal.confirmations == 2) {
            //deployContract(_proposalId);
        //}
    }

    function deployContract(uint _proposalId)
        public

        returns (address wallet, uint ContractId)
    {
        Proposal storage proposal = proposals[_proposalId];
        require(proposal.confirmations == 2, "Sorry both parties have not approved for this Proposal to be deployed");
        require(proposal.deployed == false, "A contract has already been deployed for this proposal");
        wallet = Clones.clone(contractWalletImplementation);
        emit ProxyDeployed(wallet, numOfProxies, _proposalId);
        ContractId = numOfProxies;
        ContractWalletETH(wallet).init(proposal.client, proposal.freelancer, DAO, false, proposal.totalPayout, address(this), RoyaltyAddress);
        proposal.deployed = true;
        allProxyInstances.push(Proxy(wallet, proposal.client, proposal.freelancer));
        return (wallet, ContractId);
    }

    function getProposal(uint _proposalId) 
        public
        view
        returns (
            address client,
            address freelancer,
            bool oneTimePayment,
            uint totalPayout,
            uint Confirmations,
            bool deployed
        )
    {
        Proposal storage proposal = proposals[_proposalId];
        return (
            proposal.client,
            proposal.freelancer,
            proposal.oneTimePayment,
            proposal.totalPayout,
            proposal.confirmations,
            proposal.deployed
        );
    }

    function getProxyObject(uint contractId) 
        public
        view
        returns (
            address proxyAddress,
            address client,
            address freelancer
        )
    {
        Proxy memory proxyObject = allProxyInstances[contractId];
        return (
            proxyObject.proxyAddress,
            proxyObject.client,
            proxyObject.freelancer
        );
    }

    function callProposeTransaction(uint contractId, address payable to, uint value)
        public
        returns (
            uint transactionId,
            address sender
        )
    {
        (address proxy, address client, address freelancer) = getProxyObject(contractId);
        require(msg.sender == client || msg.sender == freelancer || msg.sender == DAO, "Sorry you can only call functions on your own project");
        (transactionId, sender) = ContractWalletETH(proxy).proposeTransaction(to, value, msg.sender);
        emit TransactionProposed(transactionId, contractId, msg.sender);
    }

    function callConfirmTransaction(uint transactionId, uint contractId)
        public
        returns (uint numOfConfirmations)
    {
        (address proxy, address client, address freelancer) = getProxyObject(contractId);
        require(msg.sender == client || msg.sender == freelancer || msg.sender == DAO, "Sorry you can only call functions on your own project");
        numOfConfirmations = ContractWalletETH(proxy).confirmTransaction(transactionId, msg.sender);
        emit TransactionConfirmed(transactionId, contractId, msg.sender);
    }

    function callExecuteTransaction(uint transactionId, uint contractId) 
        public
        returns (
            uint transId,
            address destination,
            uint balance
        )
    {
        (address proxy, address client, address freelancer) = getProxyObject(contractId);
        require(msg.sender == client || msg.sender == freelancer || msg.sender == DAO, "Sorry you can only call functions on your own project");
        (transactionId, destination, balance) = ContractWalletETH(proxy).executeTransaction(transactionId);
        require(destination != address(0), "The call must have reverted as an id was not returned");
        emit TransactionExecuted(transactionId, contractId, balance);
        return(transactionId, destination, balance);
    }

    function callGetBalance(uint contractId)
        public
        view
        returns (uint balance)
    {
        (address proxy, address client, address freelancer) = getProxyObject(contractId);
        require(msg.sender == client || msg.sender == freelancer || msg.sender == DAO, "Sorry you can only call functions on your own project");
        balance = ContractWalletETH(proxy).getBalance();
    }

    function depositIntoInstance( uint contractId)
        payable
        public
        returns (uint balance, bool success)
    {
        (address proxy, address client, address freelancer) = getProxyObject(contractId);
        require(msg.sender == client || msg.sender == freelancer || msg.sender == DAO, "Sorry you can only call functions on your own project"); 
        (success, balance) = ContractWalletETH(proxy).deposit{ value: msg.value }();
        require(success, "This deposit did not work");
        return (balance, success);
    }
}