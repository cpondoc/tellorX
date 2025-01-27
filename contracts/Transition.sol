// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./tellor3/TellorStorage.sol";
import "./TellorVars.sol";
import "./interfaces/IOracle.sol";
import "hardhat/console.sol";

contract Transition is TellorStorage,TellorVars{

     //links to the Oracle contract.  Allows parties (like Liquity) to continue to use the master address to acess values.
        //all parties should be reading values through this address
    
    function init(address _governance, address _oracle, address _treasury) external{
        //run this once migrated over.  This changes the underlying storage
        require(msg.sender == addresses[_OWNER]);
        require(addresses[_GOVERNANCE_CONTRACT] == address(0), "Only good once");
        uints[_STAKE_AMOUNT] = 100e18;
        uints[_SWITCH_TIME] = block.timestamp;
        addresses[_GOVERNANCE_CONTRACT] = _governance;
        addresses[_ORACLE_CONTRACT] = _oracle;
        addresses[_TREASURY_CONTRACT] = _treasury;
    }


    function getLastNewValueById(uint256 _requestId)
        external
        view
        returns (uint256, bool)
    {
        //try new contract first
        uint256 _timeCount =IOracle(addresses[_ORACLE_CONTRACT]).getTimestampCountById(bytes32(_requestId));
        if (_timeCount != 0) {
            return (
                retrieveData(
                    _requestId,
                    IOracle(addresses[_ORACLE_CONTRACT]).getReportTimestampByIndex(bytes32(_requestId),_timeCount- 1)
                ),
                true
            );
        } else {
                Request storage _request = requestDetails[_requestId];
                if (_request.requestTimestamps.length != 0) {
                    return (
                        retrieveData(
                            _requestId,
                            _request.requestTimestamps[
                                _request.requestTimestamps.length - 1
                            ]
                        ),
                        true
                    );
                } else {
                    return (0, false);
                }
        }
    }

    /**
     * @dev Counts the number of values that have been submitted for the request
     * if called for the currentRequest being mined it can tell you how many miners have submitted a value for that
     * request so far
     * @param _requestId the requestId to look up
     * @return uint count of the number of values received for the requestId
     */
    function getNewValueCountbyRequestId(uint256 _requestId)
        external
        view
        returns (uint256)
    {
        //defaults to new one, but will give old value if new mining has not started
        uint256 _val = IOracle(addresses[_ORACLE_CONTRACT]).getTimestampCountById(bytes32(_requestId));
        if(_val > 0){
            return _val;
        }
        else{
            return requestDetails[_requestId].requestTimestamps.length;
        }
    }

        /**
     * @dev Gets the timestamp for the value based on their index
     * @param _requestId is the requestId to look up
     * @param _index is the value index to look up
     * @return uint256 timestamp
     */
    function getTimestampbyRequestIDandIndex(uint256 _requestId, uint256 _index)
        external
        view
        returns (uint256)
    {
        try IOracle(addresses[_ORACLE_CONTRACT]).getReportTimestampByIndex(bytes32(_requestId),_index) returns (uint256 _val){
            return _val;
        }
        catch{
            return requestDetails[_requestId].requestTimestamps[_index];
        }
    }

    /**
     * @dev Retrieve value from oracle based on timestamp
     * @param _requestId being requested
     * @param _timestamp to retrieve data/value from
     * @return value for timestamp submitted
     */
    function retrieveData(uint256 _requestId, uint256 _timestamp)
        public
        view
        returns (uint256)
    {
        if(_timestamp < uints[_SWITCH_TIME]){
                return requestDetails[_requestId].finalValues[_timestamp];
        }
        return _sliceUint(IOracle(addresses[_ORACLE_CONTRACT]).getValueByTimestamp(bytes32(_requestId), _timestamp));
    }

    //Getters
    /**
     * @dev Allows users to access the number of decimals
     */
    function decimals() external pure returns (uint8) {
        return 18;
    }
    
    /**
     * @dev allows Tellor to read data from the addressVars mapping
     * @param _data is the keccak256("variable_name") of the variable that is being accessed.
     * These are examples of how the variables are saved within other functions:
     * addressVars[keccak256("_owner")]
     * addressVars[keccak256("tellorContract")]
     * @return address of the requested variable
     */
    function getAddressVars(bytes32 _data) external view returns (address) {
        return addresses[_data];
    }

    /**
     * @dev Getter for the variables saved under the TellorStorageStruct uints variable
     * @param _data the variable to pull from the mapping. _data = keccak256("variable_name")
     * where variable_name is the variables/strings used to save the data in the mapping.
     * The variables names in the TellorVariables contract
     * @return uint of specified variable
     */
    function getUintVar(bytes32 _data) external view returns (uint256) {
        return uints[_data];
    }

    /**
     * @dev Allows users to access the token's name
     */
    function name() external pure returns (string memory) {
        return "Tellor Tributes";
    }

    /**
     * @dev Allows users to access the token's symbol
     */
    function symbol() external pure returns (string memory) {
        return "TRB";
    }
    
    /**
     * @dev Getter for the total_supply of oracle tokens
     * @return uint total supply
     */
    function totalSupply() external view returns (uint256) {
        return uints[_TOTAL_SUPPLY];
    }

    /**
     * @dev Getter for if the party is migrated
     * @param _addy address of party
     * @return if the party is migrated
     */
    function isMigrated(address _addy) external view returns (bool) {
        return migrated[_addy];
    }

    
    /**
     * @dev this function is solely for the parachute contract
     */
    function getNewCurrentVariables() external view returns (bytes32 _c,uint256[5] memory _r,uint256 _diff,uint256 _tip){
        _r = [uint256(1),uint256(1),uint256(1),uint256(1),uint256(1)];
        _diff = 0;
        _tip = 0;
        _c = keccak256(abi.encode(IOracle(addresses[_ORACLE_CONTRACT]).getTimeOfLastNewValue()));
    }
    
    /**
     * @dev This allows Tellor X to fallback to the old Tellor if there are current open disputes (or disputes on old Tellor values)
     */
    fallback() external {
        address addr = 0xdDB59729045d2292eeb8Ff96c46B8db53B88Daa2;//hardcode this in?
        bytes4 _function;
        for (uint i = 0; i < 4; i++) {
            _function |= bytes4(msg.data[i] & 0xFF) >> (i * 8);
        }
        require(_function == bytes4(bytes32(keccak256("beginDispute(uint256,uint256,uint256)")))||
        _function == bytes4(bytes32(keccak256("vote(uint256,bool)"))) ||
        _function == bytes4(bytes32(keccak256("tallyVotes(uint256)"))) ||
        _function == bytes4(bytes32(keccak256("unlockDisputeFee(uint256)"))),"function should be allowed"); //should autolock out after a week (no disputes can begin past a week)
        (bool result, ) =  addr.delegatecall(msg.data);
            assembly {
                returndatacopy(0, 0, returndatasize())
                switch result
                    // delegatecall returns 0 on error.
                    case 0 {
                        revert(0, returndatasize())
                    }
                    default {
                        return(0, returndatasize())
                    }
           }
    }

    //Internal    
    function _sliceUint(bytes memory b) internal pure returns (uint256 _x){
        uint256 number;
        for(uint256 i=0;i<b.length;i++){
            number = number + uint256(uint8(b[i]))*(2**(8*(b.length-(i+1))));
        }
        return number;
    }
}