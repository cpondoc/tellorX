// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./TellorStaking.sol";
import "./interfaces/IController.sol";
import "./Transition.sol";
import "hardhat/console.sol";

contract Controller is TellorStaking, Transition{

    function changeControllerContract(address _newController) external{
        require(msg.sender == addresses[_GOVERNANCE_CONTRACT]);
        require(_isValid(_newController));
        addresses[_TELLOR_CONTRACT] = _newController;//name _TELLOR_CONTRACT is hardcoded in
        assembly {
            sstore(_EIP_SLOT, _newController)
        }
    }
    
    function changeGovernanceContract(address _newGovernance) external{
        require(msg.sender == addresses[_GOVERNANCE_CONTRACT]);
        require(_isValid(_newGovernance));
        addresses[_GOVERNANCE_CONTRACT] = _newGovernance;
    }

    function changeOracleContract(address _newOracle) external {
        require(msg.sender == addresses[_GOVERNANCE_CONTRACT]);
        require(_isValid(_newOracle));
        addresses[_ORACLE_CONTRACT] = _newOracle;

    }

    function changeTreasuryContract(address _newTreasury) external{
        require(msg.sender == addresses[_GOVERNANCE_CONTRACT]);
        require(_isValid(_newTreasury));
        addresses[_TREASURY_CONTRACT] = _newTreasury;

    }

    function changeUint(bytes32 _target, uint256 _amount) external{
        require(msg.sender == addresses[_GOVERNANCE_CONTRACT]);
        uints[_target] = _amount;
    }


    function migrate() external{
        require(!migrated[msg.sender], "Already migrated");
        _doMint(msg.sender, IController(addresses[_OLD_TELLOR]).balanceOf(msg.sender));
        migrated[msg.sender] = true;
    }

    function mint(address _reciever, uint256 _amount) external{
        require(msg.sender == addresses[_GOVERNANCE_CONTRACT] || msg.sender == addresses[_TREASURY_CONTRACT], "must be admin");
        _doMint(_reciever, _amount);
    }

    function verify() external pure returns(uint){
        return 9999;
    }

    function _isValid(address _contract) internal returns(bool){
        (bool _success, bytes memory _data) =
            address(_contract).call(
                abi.encodeWithSelector(0xfc735e99, "") //verify() signature
            );
        require(
            _success && abi.decode(_data, (uint256)) > 9000, //just an arbitrary number to ensure that the contract is valid
            "new contract is invalid"
        );
        return true;
    }
}