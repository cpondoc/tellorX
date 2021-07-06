// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface ITellor{
    //Controller
    function addresses(bytes32) external returns(address);
    function uints(bytes32) external returns(uint256);
    function burn(uint256 _amount) external;
    function changeDeity(address _newDeity) external;
    function changeOwner(address _newOwner) external;
    function changeTellorContract(address _tContract) external;
    function changeControllerContract(address _newController) external;
    function changeGovernanceContract(address _newGovernance) external;
    function changeOracleContract(address _newOracle) external;
    function changeTreasuryContract(address _newTreasury) external;
    function changeUint(bytes32 _target, uint256 _amount) external;
    function migrate() external;
    function mint(address _reciever, uint256 _amount) external;
    function init(address _governance, address _oracle, address _treasury) external;
    function getLastNewValueById(uint256 _requestId) external view returns (uint256, bool);
    function retrieveData(uint256 _requestId, uint256 _timestamp) external view returns (uint256);
    function getNewValueCountbyRequestId(uint256 _requestId) external view returns (uint256);
    function getAddressVars(bytes32 _data) external view returns (address);
    function getUintVar(bytes32 _data) external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function allowance(address _user, address _spender) external view  returns (uint256);
    function allowedToTrade(address _user, uint256 _amount) external view returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function approveAndTransferFrom(address _from, address _to, uint256 _amount) external returns(bool);
    function balanceOf(address _user) external view returns (uint256);
    function balanceOfAt(address _user, uint256 _blockNumber)external view returns (uint256);
    function transfer(address _to, uint256 _amount)external returns (bool success);
    function transferFrom(address _from,address _to,uint256 _amount) external returns (bool success) ;
    function depositStake() external;
    function requestStakingWithdraw() external;
    function withdrawStake() external;
    function changeStakingStatus(address _reporter, uint _status) external;
    function slashMiner(address _reporter, address _disputer) external;
    function getStakerInfo(address _staker) external view returns (uint256, uint256);
    //Governance
    enum VoteResult {FAILED,PASSED,INVALID}
    function addApprovedFunction(bytes4 _func) external;
    function changeTypeInformation(uint256 _id,uint256 _quorum, uint256 _duration) external;
    function beginDispute(uint256 _requestId,uint256 _timestamp) external;
    function delegate(address _delegate) external;
    function delegateOfAt(address _user, uint256 _blockNumber) external view returns (address);
    function executeVote(uint256 _id) external;
    function proposeVote(address _contract,bytes4 _function, bytes calldata _data, uint256 _timestamp) external;
    function tallyVotes(uint256 _id) external;
    function updateMinDisputeFee() external;
    function verify() external pure returns(uint);
    function vote(uint256 _id, bool _supports, bool _invalidQuery) external;
    function voteFor(address[] calldata _addys,uint256 _id, bool _supports, bool _invalidQuery) external;
    function getDelegateInfo(address _holder) external view returns(address,uint);
    function isFunctionApproved(bytes4 _func) external view returns(bool);
    function getVoteRounds(bytes32 _hash) external view returns(uint256[] memory);
    function getVoteInfo(uint256 _id) external view returns(bytes32,uint256[9] memory,bool[2] memory,VoteResult,bytes memory,bytes4,address[2] memory);
    function getDisputeInfo(uint256 _id) external view returns(uint256,uint256,bytes memory, address);
    function getOpenDisputesOnId(uint256 _id) external view returns(uint256);
    function getTypeDetails(uint256 _type) external view returns(uint256, uint256);
    function didVote(uint256 _id, address _voter) external view returns(bool);
    //Oracle
    function getReportTimestampByIndex(uint256 _requestId, uint256 _index) external view returns(uint256);
    function getValueByTimestamp(uint256 _requestId, uint256 _timestamp) external view returns(bytes memory);
    function getBlockNumberByTimestamp(uint256 _requestId, uint256 _timestamp) external view returns(uint256);
    function getReporterByTimestamp(uint256 _requestId, uint256 _timestamp) external view returns(address);
    function miningLock() external view returns(uint256);
    function removeValue(uint256 _requestId, uint256 _timestamp) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function getTipsByUser(address _user) external view returns(uint256);
    function addTip(uint256 _id, uint256 _tip) external;
    function addNewId(bytes calldata _details) external;
    function submitValue(uint256 _id, bytes calldata _value) external;
    function burnTips() external;
    function changeMiningLock(uint256 _newMiningLock) external;
    function getTipsById(uint _id) external view returns(uint256);
    function getReportDetails(uint256 _id) external view returns(bytes memory);
    function getTimestampCountByID(uint256 _id) external view returns(uint256);
    function getTimestampIndexByTimestamp(uint256 _id, uint256 _timestamp) external view returns(uint256);
    //Treasury
    function issueTreasury(uint256 _amount, uint256 _rate, uint256 _duration) external;
    function payTreasury(address _investor,uint256 _id) external;
    function buyTreasury(uint256 _id,uint256 _amount) external;
    function delegateVotingPower(address _delegate) external;
    function getTreasuryDetails(uint256 _id) external view returns(uint256,uint256,uint256,uint256);
    function getTreasuryAccount(uint256 _id, address _investor) external view returns(uint256);
    function getTreasuryOwners(uint256 _id) external view returns(address[] memory);
    function wasPaid(uint256 _id, address _investor) external view returns(bool);
    //Test functions
    function changeAddressVar(bytes32 _id, address _addy) external;
}