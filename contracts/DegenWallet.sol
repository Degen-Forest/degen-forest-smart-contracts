//SPDX-License-Identifier: MIT

/// Company: Decrypted Labs
/// @title Degen Middleware
/// @author Rabeeb Aqdas
/// @notice You can use this contract for swapping, lending, borrowing, repaying and withdrawing Collateral
/// @dev All function calls are currently implemented without side effects
pragma solidity ^0.8.20;
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function wrap(uint256 _stETHAmount) external returns (uint256);

    function unwrap(uint256 _wstETHAmount) external returns (uint256);

    function depositETH(
        address,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(address, uint256 amount, address to) external payable;

    function withdraw(uint wad) external;
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function approve(address spender, uint256 value) external returns (bool);
}

error DegenWallet__SameAsBefore(uint256 tax);
error DegenWallet__NotEnoughBalance();
error DegenWallet__ValueCantBeZero();
error DegenWallet__TransferFailed();
error DegenWallet__NotEnoughCollatoral(uint256 _amount);
error DegenWallet__InvalidAddress();
error DegenWallet__TransactionFailed();

contract DegenWallet is Ownable {
    ///////////////////////////////////////////State Variables///////////////////////////////////////////////////////////////////
    uint256 private plateFormfee;
    address payable private immutable WALLET;
    address public constant POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
    address public constant stEth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public constant wstEth = 0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0;
    address public constant oneInchRouter =
        0x1111111254EEB25477B68fb85Ed929f73A960582;
    address public constant ethAddr =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address public constant WETHGate =
        0xD322A49006FC828F9B5B37Ab215F99B4E5caB19C;

    receive() external payable {}

    constructor(
        uint256 _tax,
        address payable _wallet,
        address _treasury
    ) Ownable(_treasury) {
        plateFormfee = _tax;
        WALLET = _wallet;
    }

    ////////////////////////////////////////////Main Functions///////////////////////////////////////////////////////////////////

    ///@notice Supplies an `amount` of underlying asset into the reserve, receiving in return overlying aTokens using AAVE Protocol
    /// @param _token The address of the underlying asset to supply
    /// @param _amount The amount to be supplied
    function lendTokenOnAave(address _token, uint256 _amount) external payable {
        address _sender = _msgSender();
        if (_token == address(0)) revert DegenWallet__InvalidAddress();

        if (_isNative(_token)) {
            uint256 amount_ = msg.value;

            if (amount_ == 0) revert DegenWallet__ValueCantBeZero();
            (uint256 _amountAfterFee, uint256 _fee) = _calculationForFee(
                amount_
            );
            _sendETH(_fee);
            IERC20(WETHGate).depositETH{value: _amountAfterFee}(
                address(0),
                _sender,
                0
            );
        } else {
            IERC20 _helper = IERC20(_token);
            if (_amount > _helper.balanceOf(_sender))
                revert DegenWallet__NotEnoughBalance();
            _helper.transferFrom(_sender, address(this), _amount);
            (uint256 _amountAfterFee, uint256 _fee) = _calculationForFee(
                _amount
            );

            _helper.transfer(WALLET, _fee);

            if (_token == stEth) {
                _token = wstEth;
                _helper.approve(_token, _amountAfterFee);
                _helper = IERC20(_token);
                uint256 res = _helper.wrap(_amountAfterFee);
                _amountAfterFee = res;
            }
            _helper.approve(POOL, _amountAfterFee);
            IPool(POOL).supply(_token, _amountAfterFee, _sender, 0);
        }
    }

    /// @notice Withdraws an `amount` of underlying asset from the reserve, burning the equivalent aTokens owned using AAVE Protocol
    /// @param _asset The address of the underlying asset to withdraw
    /// @param _amount The underlying amount to be withdrawn
    function withdrawCollateral(address _asset, uint256 _amount) external {
        if (_asset == address(0)) revert DegenWallet__InvalidAddress();
        address _sender = _msgSender();

        address _stEth = stEth;
        address _wstEth = wstEth;
        address _WETH = WETH;
        address _pool = POOL;
        _asset = _asset == _stEth ? _wstEth : _asset;
        address aTokenAddress = IPool(_pool)
            .getReserveData(_asset)
            .aTokenAddress;
        IERC20 _helper = IERC20(aTokenAddress);
        if (_amount > _helper.balanceOf(_sender))
            revert DegenWallet__NotEnoughBalance();
        _helper.transferFrom(_sender, address(this), _amount);
        _asset == _WETH
            ? _helper.approve(WETHGate, _amount)
            : _helper.approve(_pool, _amount);

        if (_asset == _WETH) {
            (uint256 _amountAfterFee, uint256 _fee) = _calculationForFee(
                _amount
            );

            IERC20(WETHGate).withdrawETH(_asset, _amountAfterFee, _sender);
            IERC20(WETHGate).withdrawETH(_asset, _fee, WALLET);
        } else {
            uint256 amount = IPool(_pool).withdraw(
                _asset,
                _amount,
                address(this)
            );

            if (_asset == _wstEth) {
                uint256 value = IERC20(_wstEth).unwrap(amount);
                IERC20 helper_ = IERC20(_stEth);
                (uint256 _amountAfterFee, uint256 _fee) = _calculationForFee(
                    value
                );
                helper_.transfer(_sender, _amountAfterFee);

                helper_.transfer(WALLET, _fee);
            } else {
                IERC20 helper_ = IERC20(_asset);
                (uint256 _amountAfterFee, uint256 _fee) = _calculationForFee(
                    amount
                );

                helper_.transfer(_sender, _amountAfterFee);

                helper_.transfer(WALLET, _fee);
            }
        }
    }

    /// @notice Allows users to borrow a specific `amount` of the reserve underlying asset, provided that the borrower using AAVE Protocol
    /// @param _asset The address of the underlying asset to borrow
    /// @param _amount The amount to be borrowed
    function borrowOnAave(
        address _asset,
        uint256 _amount,
        uint256 interestRateMode
    ) external {
        if (_asset == address(0)) revert DegenWallet__InvalidAddress();
        address _sender = _msgSender();

        IERC20 _helper = IERC20(_asset);
        IPool(POOL).borrow(_asset, _amount, interestRateMode, 0, _sender);
        (uint256 _amountAfterFee, uint256 _fee) = _calculationForFee(_amount);
        _helper.transfer(_sender, _amountAfterFee);

        _helper.transfer(WALLET, _fee);
    }

    /// @notice Repays a borrowed `amount` on a specific reserve, burning the equivalent debt tokens owned using AAVE Protocol
    /// @param _asset The address of the borrowed underlying asset previously borrowed
    /// @param _interestRateMode The interest rate mode at of the debt the user wants to repay: 1 for Stable, 2 for Variable
    /// @param _amount The amount to repay
    function repayDebt(
        address _asset,
        uint256 _interestRateMode,
        uint256 _amount
    ) external payable {
        if (_asset == address(0)) revert DegenWallet__InvalidAddress();
        address _sender = _msgSender();
        IERC20 _helper = IERC20(_asset);
        address _pool = POOL;
        if (_amount > _helper.balanceOf(_sender))
            revert DegenWallet__NotEnoughBalance();
        _helper.transferFrom(_sender, address(this), _amount);
        (uint256 _amountAfterFee, uint256 _fee) = _calculationForFee(_amount);

        _helper.transfer(WALLET, _fee);

        _helper.approve(_pool, _amountAfterFee);
        uint256 repaidAmount = IPool(_pool).repay(
            _asset,
            _amountAfterFee,
            _interestRateMode,
            _sender
        );
        uint256 amountToBeGiven = _amount - (repaidAmount + _fee);
        if (amountToBeGiven > 0) _helper.transfer(_sender, amountToBeGiven);
    }

    /// @notice @notice Performs a swap, delegating all calls encoded in `data` to `executor` using 1inch Protocol
    /// @param _fromToken The address of the token with which you want to swap
    /// @param _amount The amount to swap
    /// @param _oneInchDataParam Encoded calls that `caller` should execute in between of swaps
    function oneInchSwap(
        address _fromToken,
        uint256 _amount,
        bytes calldata _oneInchDataParam
    ) external payable {
        address _sender = _msgSender();
        _amount = msg.value > 0 ? msg.value : _amount;
        (uint256 _amountAfterFee, uint256 _fee) = _calculationForFee(_amount);

        if (_isNative(_fromToken)) {
            _sendETH(_fee);
        } else {
            IERC20 _helper = IERC20(_fromToken);
            if (_amount > _helper.balanceOf(_sender))
                revert DegenWallet__NotEnoughBalance();
            _helper.transferFrom(_sender, address(this), _amount);
            _helper.approve(oneInchRouter, _amount);

            _helper.transfer(WALLET, _fee);
        }
        uint256 amountToBeSent = msg.value > 0 ? _amountAfterFee : 0;
        (bool success, ) = oneInchRouter.call{value: amountToBeSent}(
            _oneInchDataParam
        );
        if (!success) revert DegenWallet__TransactionFailed();
    }

    /// @notice Do the calculation for fee deduction
    /// @dev  Private function only for contract
    /// @param _amount The amount from which the fee will deduct
    /// @return _amountAfterFee The amount after fee deduction
    /// @return _fee The amount which is deducted by the contract in terms of fee
    function _calculationForFee(
        uint256 _amount
    ) private view returns (uint256 _amountAfterFee, uint256 _fee) {
        _fee = (_amount * plateFormfee) / 10000;
        _amountAfterFee = _amount - _fee;
    }

    /// @notice Use to send ethereum to the WALLET
    /// @dev  Private function only for contract
    /// @param _amount The amount which will send to the WALLET
    function _sendETH(uint256 _amount) private {
        (bool success, ) = WALLET.call{value: _amount}("");
        if (!success) revert DegenWallet__TransferFailed();
    }

    /////////////////////////////////////////Only Owner Functions///////////////////////////////////////////////////////////////////

    /// @notice Change the fee percentage of platform
    /// @dev  Ristrict to only owner of the contract
    /// @param _newPlateFormfee New fee in the form of bips
    function changeTax(uint256 _newPlateFormfee) external onlyOwner {
        require(_newPlateFormfee < 10000, "Tax can't be 100%");
        uint256 _oldPlateFormfee = plateFormfee;
        if (_oldPlateFormfee == _newPlateFormfee)
            revert DegenWallet__SameAsBefore(_oldPlateFormfee);
        plateFormfee = _newPlateFormfee;
    }

    ///////////////////////////////////////////View Functions///////////////////////////////////////////////////////////////////

    /// @notice Tell either the asset is eth or not
    /// @dev  Returns Boolean Value.
    /// @param _token The asset which you want to check
    /// @return bool true if asset is eth
    function _isNative(address _token) private pure returns (bool) {
        return (_token == address(0) || _token == ethAddr);
    }

    /// @notice Tell the fee of PlateForm
    /// @dev  Returns bips. e.g 69 ==> 0.69%
    /// @return plateFormfee in bips
    function getPlateFormfee() external view returns (uint256) {
        return plateFormfee;
    }

    /// @notice Tell the fee wallet address
    /// @dev  Returns wallet address in which fee will send
    /// @return WALLET address
    function getWallet() external view returns (address) {
        return WALLET;
    }
}
