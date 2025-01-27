// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

interface IOracle{
    function getReportTimestampByIndex(bytes32 _id, uint256 _index) external view returns(uint256);
    function getValueByTimestamp(bytes32 _id, uint256 _timestamp) external view returns(bytes memory);
    function getBlockNumberByTimestamp(bytes32 _id, uint256 _timestamp) external view returns(uint256);
    function getReporterByTimestamp(bytes32 _id, uint256 _timestamp) external view returns(address);
    function miningLock() external view returns(uint256);
    function removeValue(bytes32 _id, uint256 _timestamp) external;
    function getReportsSubmittedByAddress(address _reporter) external view returns(uint256);
    function getTipsByUser(address _user) external view returns(uint256);
    function addTip(bytes32 _id, uint256 _tip) external;
    function submitValue(bytes32 _id, bytes calldata _value) external;
    function burnTips() external;
    function verify() external pure returns(uint);
    function changeMiningLock(uint256 _newMiningLock) external;
    function changeTimeBasedReward(uint256 _newTimeBasedReward) external;
    function getTipsById(bytes32 _id) external view returns(uint256);
    function getTimestampCountById(bytes32 _id) external view returns(uint256);
    function getTimestampIndexByTimestamp(bytes32 _id, uint256 _timestamp) external view returns(uint256);
    function getCurrentValue(bytes32 _id) external view returns(bytes memory);
    function getTimeOfLastNewValue() external view returns(uint256);
}