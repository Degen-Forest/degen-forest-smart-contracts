// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (governance/extensions/GovernorSettings.sol)

pragma solidity ^0.8.20;

import {Governor} from "../Governor.sol";

interface IDEGENAPE {
    function balanceOf(address _owner) external returns(uint256);
}

/**
 * @dev Extension of {Governor} for settings updatable through governance.
 */
abstract contract GovernorSettings is Governor {
    // amount of token
    uint256 private _proposalThreshold;
    // amount of token required for voting
    uint256 private _requiredTokensForVoting;
    // timepoint: limited to uint48 in core (same as clock() type)
    uint48 private _votingDelay;
    // duration: limited to uint32 in core
    uint32 private _votingPeriod;
    // action: true or false 
    bool private _proposalNFTThreshold;
    // action: true or false 
    bool private _votingNFTThreshold;
    // interface to check NFT balance
    IDEGENAPE internal _degenHelper;


    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);
    event ProposalNFTThresholdSet(bool oldProposalNFTThreshold, bool newProposalNFTThreshold);
    event VotingNFTThresholdSet(bool oldVotingNFTThreshold, bool newVotingNFTThreshold);
    event RequiredTokenAmountForVotingSet(uint256 oldRequiredTokensForVoting, uint256 newRequiredTokensForVoting);
    event VetoerUpdated(address prevVetoer, address newVetoer);

    /**
     * @dev Initialize the governance parameters.
     */
    constructor(uint48 initialVotingDelay, uint32 initialVotingPeriod, uint256 initialProposalThreshold, address _nftAddress,address _vetoerAddr,uint256 _tokensRequiredForVoting) {
        _setVotingDelay(initialVotingDelay);
        _setVotingPeriod(initialVotingPeriod);
        _setProposalThreshold(initialProposalThreshold);
        _setVetoer(_vetoerAddr);
        _setRequiredTokensForVoting(_tokensRequiredForVoting);
        _degenHelper = IDEGENAPE(_nftAddress);

    }

    /**
     * @dev See {IGovernor-votingDelay}.
     */
    function votingDelay() public view virtual override returns (uint256) {
        return _votingDelay;
    }

    /**
     * @dev See {IGovernor-proposalNFTThresholdNotIncluded}.
     */
    function proposalNFTThresholdNotIncluded() public view virtual override returns (bool) {
        return _proposalNFTThreshold;
    }

    /**
     * @dev See {IGovernor-votingNFTThresholdNotIncluded}.
     */
    function votingNFTThresholdNotIncluded() public view virtual override returns (bool) {
        return _votingNFTThreshold;
    }

    /**
     * @dev See {IGovernor-requiredTokensForVoting}.
     */
    function requiredTokensForVoting() public view virtual returns (uint256) {
        return _requiredTokensForVoting;
    }

    /**
     * @dev See {IGovernor-votingPeriod}.
     */
    function votingPeriod() public view virtual override returns (uint256) {
        return _votingPeriod;
    }

    /**
     * @dev See {Governor-proposalThreshold}.
     */
    function proposalThreshold() public view virtual override returns (uint256) {
        return _proposalThreshold;
    }

    /**
     * @dev Update the voting delay. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingDelaySet} event.
     */
    function setVotingDelay(uint48 newVotingDelay) public virtual onlyGovernance {
        _setVotingDelay(newVotingDelay);
    }

    /**
     * @dev change the proposalNFTThreshold. This operation can only be performed through a governance proposal.
     *
     * Emits a {ProposalNFTThresholdSet} event.
     */
    function setProposalNFTThreshold(bool _newAction) public virtual onlyGovernance {
        emit ProposalNFTThresholdSet(_proposalNFTThreshold,_newAction);
        _proposalNFTThreshold = _newAction;
    }

    /**
     * @dev change the proposalNFTThreshold. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingNFTThresholdSet} event.
     */
    function setVotingNFTThreshold(bool _newAction) public virtual onlyGovernance {
        emit VotingNFTThresholdSet(_votingNFTThreshold,_newAction);
        _votingNFTThreshold = _newAction;
    }

    /**
     * @dev change the requiredTokensForVoting. This operation can only be performed through a governance proposal.
     *
     * Emits a {RequiredTokenAmountForVotingSet} event.
     */
    function setRequiredTokensForVoting(uint256 _newAmount) public virtual onlyGovernance {
        _setRequiredTokensForVoting(_newAmount);
    }

    /**
     * @dev Updates the vetoer. This operation can only be performed through a governance proposal.
     *
     * Emits a {VetoerUpdated} event.
     */
    function updateVetoer(address _newVetoer) public virtual onlyGovernance {
       _setVetoer(_newVetoer);
    }

    /**
     * @dev Update the voting period. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function setVotingPeriod(uint32 newVotingPeriod) public virtual onlyGovernance {
        _setVotingPeriod(newVotingPeriod);
    }

    /**
     * @dev Update the proposal threshold. This operation can only be performed through a governance proposal.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function setProposalThreshold(uint256 newProposalThreshold) public virtual onlyGovernance {
        _setProposalThreshold(newProposalThreshold);
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _setVotingDelay(uint48 newVotingDelay) internal virtual {
        emit VotingDelaySet(_votingDelay, newVotingDelay);
        _votingDelay = newVotingDelay;
    }

    /**
     * @dev Internal setter for the vetoer.
     *
     * Emits a {VetoerUpdated} event.
     */
    function _setVetoer(address _newVetoer) internal virtual {
        emit VetoerUpdated(_vetoer, _newVetoer);
        _vetoer = _newVetoer;
    }

    /**
     * @dev Internal setter for the voting period.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function _setVotingPeriod(uint32 newVotingPeriod) internal virtual {
        if (newVotingPeriod == 0) {
            revert GovernorInvalidVotingPeriod(0);
        }
        emit VotingPeriodSet(_votingPeriod, newVotingPeriod);
        _votingPeriod = newVotingPeriod;
    }

    /**
     * @dev Internal setter for the proposal threshold.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function _setProposalThreshold(uint256 newProposalThreshold) internal virtual {
        emit ProposalThresholdSet(_proposalThreshold, newProposalThreshold);
        _proposalThreshold = newProposalThreshold;
    }

    /**
     * @dev Internal setter for the amount of votes required for voting.
     *
     * Emits a {RequiredTokenAmountForVotingSet} event.
     */
    function _setRequiredTokensForVoting(uint256 _newAmount) internal virtual {
        emit RequiredTokenAmountForVotingSet(_requiredTokensForVoting,_newAmount);
        _requiredTokensForVoting = _newAmount;
    }

}
