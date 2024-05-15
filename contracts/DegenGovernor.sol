//SPDX-License-Identifier: MIT
/**
 * @title DegenGovernor
 * Company: Decrypted Labs
 * @author Rabeeb Aqdas
 * @dev Implementation of a custom governance contract for the DegenWalletDAO.
 * The contract combines various governance modules to enable advanced voting
 * and proposal functionalities. It includes settings for voting delay, period,
 * and proposal threshold, along with quorum fraction, timelock control, and NFT-based
 * eligibility for proposing and voting.
 *
 * The DegenGovernor is designed to provide robust governance mechanisms for the 
 * DegenWalletDAO, leveraging a combination of token-based voting and timelock controls
 * to ensure secure and transparent decision-making processes.
 *
 * Key Features:
 * - Voting delay and period customization.
 * - Proposal threshold to limit spam proposals.
 * - Quorum fraction to ensure sufficient participation in votes.
 * - Timelock control to manage execution delays for approved proposals.
 * - NFT-based eligibility checks for both proposing and voting.
 * - Integration with a veto mechanism.
 *
 */

pragma solidity ^0.8.20;

import "./degenWalletDAO/governance/Governor.sol";
import "./degenWalletDAO/governance/extensions/GovernorSettings.sol";
import "./degenWalletDAO/governance/extensions/GovernorCountingSimple.sol";
import "./degenWalletDAO/governance/extensions/GovernorVotes.sol";
import "./degenWalletDAO/governance/extensions/GovernorVotesQuorumFraction.sol";
import "./degenWalletDAO/governance/extensions/GovernorTimelockControl.sol";

contract DegenGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorTimelockControl
{
    constructor(
        IVotes _token,
        TimelockController _timelock,
        uint48 _votingDelay,
        uint256 _proposalThreshold,
        uint32 _votingPeriod,
        uint256 _quorumPercentage,
        address _nftAddress,
        address _vetoer,
        uint256 _tokensRequiredForVoting
    )
        Governor("DegenGovernor")
        GovernorSettings(
            _votingDelay,
            _votingPeriod,
            _proposalThreshold,
            _nftAddress,
            _vetoer,
            _tokensRequiredForVoting
        )
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(_quorumPercentage)
        GovernorTimelockControl(_timelock)
    {}

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(
        uint256 blockNumber
    )
        public
        view
        override(Governor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(
        uint256 proposalId
    )
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function proposalNeedsQueuing(
        uint256 proposalId
    ) public view override(Governor, GovernorTimelockControl) returns (bool) {
        return super.proposalNeedsQueuing(proposalId);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _queueOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint48) {
        return
            super._queueOperations(
                proposalId,
                targets,
                values,
                calldatas,
                descriptionHash
            );
    }

    function _executeOperations(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) {
        super._executeOperations(
            proposalId,
            targets,
            values,
            calldatas,
            descriptionHash
        );
    }

    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor, GovernorTimelockControl) returns (uint256) {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _veto(
        uint256 _proposalId
    ) internal override(Governor, GovernorTimelockControl) {
        return super._veto(_proposalId);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    /**
     * @dev See {IGovernor-propose}. This function has opt-in frontrunning protection, described in {_isValidDescriptionForProposer}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override returns (uint256) {
        if (!proposalNFTThresholdNotIncluded()) {
            uint256 balance = _degenHelper.balanceOf(_msgSender());
            if (balance < 1) revert NotEligibleToPropose();
        }
        return super.propose(targets, values, calldatas, description);
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(
        uint256 proposalId,
        uint8 support
    ) public override returns (uint256) {
        if (!votingNFTThresholdNotIncluded()) {
            uint256 balance = _degenHelper.balanceOf(_msgSender());
            if (balance < 1) revert NotEligibleForVoting();
        }
        uint256 weight = _getVotes(
            _msgSender(),
            proposalSnapshot(proposalId),
            _defaultParams()
        );
        if (weight < requiredTokensForVoting()) revert NotEligibleForVoting();
        return super.castVote(proposalId, support);
    }

    /**
     * @dev See {IGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public override returns (uint256) {
        if (!votingNFTThresholdNotIncluded()) {
            uint256 balance = _degenHelper.balanceOf(_msgSender());
            if (balance < 1) revert NotEligibleForVoting();
        }
        uint256 weight = _getVotes(
            _msgSender(),
            proposalSnapshot(proposalId),
            _defaultParams()
        );
        if (weight < requiredTokensForVoting()) revert NotEligibleForVoting();
        return super.castVoteWithReason(proposalId, support, reason);
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParams}.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public override returns (uint256) {
        if (!votingNFTThresholdNotIncluded()) {
            uint256 balance = _degenHelper.balanceOf(_msgSender());
            if (balance < 1) revert NotEligibleForVoting();
        }
        uint256 weight = _getVotes(
            _msgSender(),
            proposalSnapshot(proposalId),
            params
        );
        if (weight < requiredTokensForVoting()) revert NotEligibleForVoting();
        return
            super.castVoteWithReasonAndParams(
                proposalId,
                support,
                reason,
                params
            );
    }

    /**
     * @dev See {IGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        address voter,
        bytes memory signature
    ) public override returns (uint256) {
        if (!votingNFTThresholdNotIncluded()) {
            uint256 balance = _degenHelper.balanceOf(_msgSender());
            if (balance < 1) revert NotEligibleForVoting();
        }
        uint256 weight = _getVotes(
            voter,
            proposalSnapshot(proposalId),
            _defaultParams()
        );
        if (weight < requiredTokensForVoting()) revert NotEligibleForVoting();
        return super.castVoteBySig(proposalId, support, voter, signature);
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParamsBySig}.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        address voter,
        string calldata reason,
        bytes memory params,
        bytes memory signature
    ) public override returns (uint256) {
        if (!votingNFTThresholdNotIncluded()) {
            uint256 balance = _degenHelper.balanceOf(_msgSender());
            if (balance < 1) revert NotEligibleForVoting();
        }
        uint256 weight = _getVotes(voter, proposalSnapshot(proposalId), params);
        if (weight < requiredTokensForVoting()) revert NotEligibleForVoting();
        return
            super.castVoteWithReasonAndParamsBySig(
                proposalId,
                support,
                voter,
                reason,
                params,
                signature
            );
    }
}
