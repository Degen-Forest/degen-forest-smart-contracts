// SPDX-License-Identifier: MIT

/// Company: Decrypted Labs
/// @title Moola
/// @author Rabeeb Aqdas
/// @notice This contract can be use to claim, mint, burn MOOLA tokens
/// @dev All function calls are currently implemented without side effects
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Votes.sol";

/**
 * @dev Error indicating that the caller is not authorized to act.
 */
error Moola__NotAuthorizer();

/**
 * @dev Error indicating that the same action cannot be performed multiple times.
 */
error Moola__SameAction();

/**
 * @dev Error indicating that a transfer of funds failed.
 */
error Moola__TransferFailed();

/**
 * @dev Error indicating that the balance is zero.
 */
error Moola__ZeroBalance();

/**
 * @dev Error indicating that the data is invalid.
 */
error Moola__InvalidData();

contract Moola is ERC20, ERC20Burnable, ERC20Permit, ERC20Votes, Ownable {
    //////////////////////////////////////////State Variables///////////////////////////////////////////////////////////////////

    /**
     * @dev Mapping to track the amount claimable by each user.
     */
    mapping(address => uint256) public amountToClaim;

    /**
     * @dev Mapping to track the total amount claimed by each user.
     */
    mapping(address => uint256) public totalClaimed;

    /**
     * @dev Mapping to track authorized addresses.
     */
    mapping(address => bool) private _authorizers;

     /**
     * @dev Emitted when an authorizer is updated.
     * @param _by The address performing the update.
     * @param _user The address of the authorized user.
     * @param _action The authorization status (true for authorized, false for unauthorized).
     */
    event AuthorizerUpdated(
        address indexed _by,
        address indexed _user,
        bool _action
    );

    /// @notice Ensures an authorized address calls the function
    /// @param _sender The address attempting to call the function
    /// @dev Reverts with NotAuthorizer if the caller is not authorized
    modifier onlyAuthorizer(address _sender) {
        if (!_authorizers[_sender]) revert Moola__NotAuthorizer();
        _;
    }

    /// 
    /// @dev Constructor for the Moola contract.
    ///      - Inherits from ERC20 for basic ERC20 functionality.
    ///      - Inherits from ERC20Permit for permit functionality.
    ///      - Inherits from Ownable for ownership functionality.
    /// 
    constructor()
        ERC20("Moola", "MOOLA")
        ERC20Permit("Moola")
        Ownable(_msgSender())
    {
        _mint(_msgSender(), 600_000_000 * 1e18);
    }

    /**
     * @dev Allows a user to claim their pending rewards.
     *      - The user's pending rewards are minted to their account.
     *      - The amount claimed is added to the total claimed by the user.
     *      - Reverts if the user has no pending rewards to claim.
     */
    function claim() external {
        address _sender = _msgSender();
        uint256 amount = amountToClaim[_sender];
        if(amount == 0) revert Moola__ZeroBalance();
        amountToClaim[_sender] = 0;
        totalClaimed[_sender] += amount;            
        _mint(_sender, amount);
    }

    /// @notice Admin can set Users and there Claimable Rewards
    /// @dev  Ristrict to only owner of the contract
    /// @param userAddress Array of user addresss
    /// @param amount Array of amount that needs to be claim
    function setUsersAndAmounts(
        address[] calldata userAddress,
        uint256[] calldata amount
    ) external onlyAuthorizer(_msgSender()) {
        if((userAddress.length != amount.length) || (userAddress.length > 100)) revert Moola__InvalidData();
        for (uint256 i; i < userAddress.length; ++i) { 
            amountToClaim[userAddress[i]] +=  amount[i];
        }
    }

    /// @notice Owner can claim the other erc20 tokens and ETH from the contract.
    /// @dev  Ristrict to only owner of the contract
    /// @param _token address of new validator
    function claimStuckTokens(address _token) external onlyOwner {
        require(_token != address(this), "No rug pulls :)");
        address _sender = _msgSender();
        if (_token == address(0)) {
            uint256 balance = address(this).balance;
            if(balance == 0) revert Moola__ZeroBalance();
           (bool success, ) = payable(_sender).call{value: balance}("");
           if(!success) revert Moola__TransferFailed();

        }else {
        IERC20 _erc20Helper = IERC20(_token);
        uint256 balance = _erc20Helper.balanceOf(address(this));
        if(balance == 0) revert Moola__ZeroBalance();
        _erc20Helper.transfer(_sender, balance);
        }

    }

    /// @notice Updates the authorizer status of a user
    /// @dev Only the contract owner can call this function, enforced by `onlyOwner` modifier.
    ///      Reverts with SameAction if the status is already set to the intended value.
    ///      Emits an AuthorizerUpdated event upon a successful update.
    /// @param _user The address of the user to update the authorizer status for
    /// @param _action The authorizer status to set for the user; true for authorized, false for unauthorized
    /// @custom:modifier onlyOwner Ensures that only the contract owner can execute this function
    function updateAuthorizer(address _user, bool _action) external onlyOwner {
        if (_authorizers[_user] == _action) revert Moola__SameAction();
        _authorizers[_user] = _action;
        emit AuthorizerUpdated(_msgSender(), _user, _action);
    }

    /// @notice Checks if a user is authorized
    /// @dev This function checks the authorization status of a user based on the `_authorizers` mapping
    /// @param _user The address of the user to check for authorization
    /// @return bool True if the user is authorized, false otherwise
    function isAuthorized(address _user) external view returns (bool) {
        return _authorizers[_user];
    }


    // The following functions are overrides required by Solidity.

    function _update(
        address from,
        address to,
        uint256 value
    ) internal override(ERC20, ERC20Votes) {
        super._update(from, to, value);
    }

    function nonces(
        address owner
    ) public view override(ERC20Permit, Nonces) returns (uint256) {
        return super.nonces(owner);
    }
}
