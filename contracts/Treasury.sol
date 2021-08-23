// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;

import "./interfaces/IController.sol";
import "./TellorVars.sol";
import "./interfaces/IGovernance.sol";
import "hardhat/console.sol";

contract Treasury is TellorVars{
    // Storage
    uint256 public totalLocked;
    uint256 public treasuryCount;
    mapping(uint => TreasuryDetails) public treasury;
    mapping(address => uint256) treasuryFundsByUser;

    struct TreasuryUser{
        uint256 amount;
        uint256 startVoteCount;
        bool paid;
    }
    struct TreasuryDetails{
        uint256 dateStarted;
        uint256 totalAmount;
        uint256 rate;
        uint256 purchased;
        uint256 duration;
        uint256 endVoteCount;
        bool endVoteCountRecorded;
        address[] owners;
        mapping(address => TreasuryUser) accounts;
    }

    event TreasuryIssued(uint256 _id,uint256 _amount,uint256 _rate);
    event TreasuryPaid(address _investor, uint256 _amount);
    event TreasuryPurchased(address _investor,uint256 _amount);
    
    // Functions
    /**
     * @dev This is an external function that is used to deposit money into a treasury.
     * @param _id is the ID for a specific treasury instance
     * @param _amount is the amount to deposit into a treasury
    */
    function buyTreasury(uint256 _id,uint256 _amount) external {
        // Transfer sender funds to Treasury
        require(IController(TELLOR_ADDRESS).approveAndTransferFrom(msg.sender,address(this),_amount));
        treasuryFundsByUser[msg.sender]+=_amount;
        // Check for sufficient treasury funds
        TreasuryDetails storage _treas = treasury[_id];
        require(_amount <= _treas.totalAmount - _treas.purchased, "Not enough money in treasury left to purchase.");
        // Update treasury details -- vote count, purchased, amount, and owners
        address governanceContract = IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT);
        _treas.accounts[msg.sender].startVoteCount = IGovernance(governanceContract).getVoteCount();
        _treas.purchased += _amount;
        _treas.accounts[msg.sender].amount += _amount;      
        _treas.owners.push(msg.sender);
        totalLocked += _amount;
        emit TreasuryPurchased(msg.sender,_amount);
    }

    /**
     * @dev This is an external function that is used to delegate voting rights from one TRB holder to another.
     * Note that only the governance contract can call this function.
     * @param _delegate is the address that the sender gives voting rights to
    */
    function delegateVotingPower(address _delegate) external {
        require(msg.sender == IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT), "Only governance contract is allowed to delegate voting power.");
        IGovernance(msg.sender).delegate(_delegate);
    }

    //_amount of TRB, _rate in bp
    /**
     * @dev This is an external function that is used to issue a new treasury.
     * Note that only the governance contract can call this function.
     * @param _amount is the amount of total TRB that treasury stores
     * @param _rate is the treasury's interest rate in BP
     * @param _duration is the amount of time the treasury locks participants
    */
    function issueTreasury(uint256 _totalAmount, uint256 _rate, uint256 _duration) external{
        require(msg.sender == IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT), "Only governance contract is allowed to issue a treasury.");
        // Increment treasury count, and define new treasury and its details (start date, total amount, rate, etc.)
        treasuryCount++;
        TreasuryDetails storage _treas = treasury[treasuryCount];
        _treas.dateStarted = block.timestamp;
        _treas.totalAmount = _totalAmount;
        _treas.rate = _rate;
        _treas.duration = _duration;
        emit TreasuryIssued(treasuryCount,_totalAmount,_rate);
    }

    function payTreasury(address _investor,uint256 _id) external{
        //calculate number of votes in governance contract when issued
        TreasuryDetails storage treas = treasury[_id];
        require(_id <= treasuryCount);
        require(treas.dateStarted + treas.duration <= block.timestamp);
        require(!treas.accounts[_investor].paid);
        //calculate non-voting penalty (treasury holders have to vote)
        uint256 numVotesParticipated;
        uint256 votesSinceTreasury;
        address governanceContract = IController(TELLOR_ADDRESS).addresses(_GOVERNANCE_CONTRACT);
        //Find endVoteCount if not already calculated
        if(!treas.endVoteCountRecorded) {
            uint256 voteCountIter = IGovernance(governanceContract).getVoteCount();
            if(voteCountIter > 0) {
                (,uint256[8] memory voteInfo,,,,,) = IGovernance(governanceContract).getVoteInfo(voteCountIter);
                while(voteCountIter > 0 && voteInfo[1] > treas.dateStarted + treas.duration) {
                    voteCountIter--;
                    if(voteCountIter > 0) {
                        (,voteInfo,,,,,) = IGovernance(governanceContract).getVoteInfo(voteCountIter);
                    }
                }
            }
            treas.endVoteCount = voteCountIter;
            treas.endVoteCountRecorded = true;
        }
        //Add up number of votes _investor has participated in
        if(treas.endVoteCount > treas.accounts[_investor].startVoteCount){
            for(
                uint256 voteCount = treas.accounts[_investor].startVoteCount;
                voteCount < treas.endVoteCount;
                voteCount++
            ) {
                bool voted = IGovernance(governanceContract).didVote(voteCount + 1, _investor);
                if (voted) {
                    numVotesParticipated++;
                }
                votesSinceTreasury++;
            }
        }
        uint256 _mintAmount = treas.accounts[_investor].amount * treas.rate/10000;
        if(votesSinceTreasury > 0){
            _mintAmount = _mintAmount *numVotesParticipated / votesSinceTreasury;
        }
        if (_mintAmount > 0) {
            IController(TELLOR_ADDRESS).mint(address(this),_mintAmount);
        }
        totalLocked -= treas.accounts[_investor].amount;
        IController(TELLOR_ADDRESS).transfer(_investor,_mintAmount + treas.accounts[_investor].amount);
        treasuryFundsByUser[_investor] -= treas.accounts[_investor].amount;
        treas.accounts[_investor].paid = true;
        emit TreasuryPaid(_investor,_mintAmount + treas.accounts[_investor].amount);
    }

    // Getters
    /**
     * @dev This function returns the details of an account within a treasury.
     * Note: refer to 'TreasuryUser' struct.
     * @param _id is the ID of the treasury the account is stored in
     * @param _investor is the address of the account in the treasury
     * @return uint256 of the amount of TRB the account has staked in the treasury
     * @return uint256 of the start vote count of when the account deposited money into the treasury
     * @return bool of whether the treasury account has paid or not
     */
    function getTreasuryAccount(uint256 _id, address _investor) external view returns(uint256, uint256, bool){
        return (
            treasury[_id].accounts[_investor].amount,
            treasury[_id].accounts[_investor].startVoteCount,
            treasury[_id].accounts[_investor].paid
        );
    }

    /**
     * @dev This function returns the number of treasuries/TellorX staking pools.
     * @return uint256 of the number of treasuries
     */
    function getTreasuryCount() external view returns(uint256){
        return treasuryCount;
    }

    function getTreasuryDetails(uint256 _id) external view returns(uint256,uint256,uint256,uint256){
        return(treasury[_id].dateStarted,treasury[_id].totalAmount,treasury[_id].rate,treasury[_id].purchased);
    }

    /**
     * @dev This function returns the amount of deposited by a user into treasuries.
     * @param _user is the specific account within a treasury to look up
     * @return uint256 of the amount of funds the user has, in TRB
     */
    function getTreasuryFundsByUser(address _user) external view returns(uint256){
        return treasuryFundsByUser[_user];
    }

    /**
     * @dev This function returns the addresses of the owners of a treasury
     * @param _id is the ID of a specific treasury
     * @return address[] memory of the addresses of the owners of the treasury
     */
    function getTreasuryOwners(uint256 _id) external view returns(address[] memory){
        return treasury[_id].owners;
    }

    /**
     * @dev This function is used during the upgrade process to verify valid Tellor Contracts
    */
    function verify() external pure returns(uint){
        return 9999;
    }

    /**
     * @dev This function determines whether or not an investor in a treasury has paid/voted on Tellor governance proposals
     * @param _id is the ID of the treasury the account is stored in
     * @param _investor is the address of the account in the treasury
     * @return bool of whether or not the investor has paid
     */
    function wasPaid(uint256 _id, address _investor) external view returns(bool){
        return treasury[_id].accounts[_investor].paid;
    }
}
