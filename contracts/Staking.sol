//SPDX-License-Identifier: MIT

/// Company: Decrypted Labs
/// @title Degen Staking
/// @author Rabeeb Aqdas
/// @notice You can use this contract for staking ETH
/// @dev All function calls are currently implemented without side effects
pragma solidity ^0.8.19;
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function balanceOf(address user) external view returns (uint256);

    function submit(address _referral) external payable returns (uint256);
}

interface IDegenWallet {
    function getPlateFormfee() external view returns (uint256);

    function getWallet() external view returns (address);
}

error DegenWallet__ValueCantBeZero();
error DegenWallet__TransferFailed();
error DegenWallet__NotEnoughTokens(uint256 _amount);

contract Staking is Ownable {
    //////////////////////////////////////////State Variables///////////////////////////////////////////////////////////////////

    IDegenWallet private _helper;
    address public constant stEth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;

    receive() external payable {}

    constructor(
        address _initialOwner,
        address _degenWallet
    ) Ownable(_initialOwner) {
        _helper = IDegenWallet(_degenWallet);
    }

    /////////////////////////////////////////Main Function///////////////////////////////////////////////////////////////////

    /// @notice Do the staking of stETH in the contract . e.g. 1ETH = 1stETH (fee exclusive)
    function stakeStEth() external payable {
        uint256 _amount = msg.value;
        IERC20 _helperStEth = IERC20(stEth);
        uint256 _contractBal = _helperStEth.balanceOf(address(this));
        if (_amount == 0) revert DegenWallet__ValueCantBeZero();
        if (_amount > _contractBal)
            revert DegenWallet__NotEnoughTokens(_contractBal);
        (uint256 _amountAfterFee, ) = _calculationForFee(_amount);
        _sendETH(_amount);
        _helperStEth.transfer(_msgSender(), _amountAfterFee);
    }

    /// @notice Withdraws the stETH from the contract
    /// @dev  Only owner can call this function
    /// @param _amount The amount which you want to withdraw
    function withdrawStEth(uint256 _amount) external onlyOwner {
        IERC20 _helperStEth = IERC20(stEth);
        uint256 _contractBal = _helperStEth.balanceOf(address(this));
        if (_amount == 0) revert DegenWallet__ValueCantBeZero();
        if (_amount > _contractBal)
            revert DegenWallet__NotEnoughTokens(_contractBal);
        _helperStEth.transfer(_msgSender(), _amount);
    }

    /////////////////////////////////////////Private Function///////////////////////////////////////////////////////////////////

    /// @notice Do the calculation for fee deduction
    /// @dev  Private function only for contract
    /// @param _amount The amount from which the fee will deduct
    /// @return _amountAfterFee The amount after fee deduction
    /// @return _fee The amount which is deducted by the contract in terms of fee
    function _calculationForFee(
        uint256 _amount
    ) private view returns (uint256 _amountAfterFee, uint256 _fee) {
        _fee = (_amount * _helper.getPlateFormfee()) / 10000;
        _amountAfterFee = _amount - _fee;
    }

    /// @notice Use to send ethereum to the wallet
    /// @dev  Private function only for contract
    /// @param _amount The amount which will send to the wallet
    function _sendETH(uint256 _amount) private {
        address wallet = _helper.getWallet();
        (bool success, ) = wallet.call{value: _amount}("");
        if (!success) revert DegenWallet__TransferFailed();
    }

    //@temp function, the only will deposit steth in the contract, so remove this function later after testing
    function test() external payable {
        IERC20(stEth).submit{value: msg.value}(address(0));
    }
}
