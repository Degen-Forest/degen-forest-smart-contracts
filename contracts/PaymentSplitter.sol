// SPDX-License-Identifier: MIT

/// Company: Decrypted Labs
/// @title PaymentSplitter
/// @author Rabeeb Aqdas
/// @notice This contract is useful for swapping assets into ETH and for the distribution of ETH to different addresses
/// @dev All function calls are currently implemented without side effects
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";

interface IWETH9 {
    function withdraw(uint wad) external;
}

error PaymentSplitter__TransferFailed();
error PaymentSplitter__NotEnoughBalance();
error PaymentSplitter__Invalid_Address();

contract PaymentSplitter is Ownable {
    //////////////////////////////////////////State Variables///////////////////////////////////////////////////////////////////

    ISwapRouter private constant swapRouter =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private treasury;
    address private devWallet;
    address private burn;
    address private founder;
    address public validator;
    uint24 public constant POOLFEE = 3000;

    modifier onlyValidator() {
        require(validator == _msgSender(), "Not Authorized!");
        _;
    }

    constructor(
        address _validator,
        address _treasury,
        address _devWallet,
        address _burn,
        address _founder
    ) Ownable(_msgSender()) {
        validator = _validator;
        treasury = _treasury;
        devWallet = _devWallet;
        burn = _burn;
        founder = _founder;
    }

    receive() external payable {}

    /////////////////////////////////////////Only Validator Function///////////////////////////////////////////////////////////////////

    /// @notice Swap tokens that are available into ETH and distribute them as per the distribution
    /// @dev  Ristrict to only validator of the contract
    /// @param _tokenIn address of token which validator want to give
    function swapTokenToETH(address _tokenIn) external onlyValidator {
        uint256 amountIn = IERC20(_tokenIn).balanceOf(address(this));
        if (amountIn == 0) revert PaymentSplitter__NotEnoughBalance();
        if (
            IERC20(_tokenIn).allowance(address(this), address(swapRouter)) <
            amountIn
        ) {
            TransferHelper.safeApprove(
                _tokenIn,
                address(swapRouter),
                type(uint256).max
            );
        }
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: WETH9,
                fee: POOLFEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        uint256 amountOut = swapRouter.exactInputSingle(params);
        IWETH9(WETH9).withdraw(amountOut);
        paymentDispersion();
    }

    /////////////////////////////////////////Only Owner Function///////////////////////////////////////////////////////////////////

    /// @notice Swap tokens that are available in the contract into another tokens
    /// @dev  Ristrict to only owner of the contract
    /// @param _tokenIn address of token which owner want to give
    /// @param _tokenOut address of token which owner want to take
    /// @param _poolFee fee of the pool
    function swapTokenToToken(
        address _tokenIn,
        address _tokenOut,
        uint24 _poolFee
    ) external onlyOwner {
        uint256 amountIn = IERC20(_tokenIn).balanceOf(address(this));
        if (amountIn == 0) revert PaymentSplitter__NotEnoughBalance();
        if (
            IERC20(_tokenIn).allowance(address(this), address(swapRouter)) <
            amountIn
        ) {
            TransferHelper.safeApprove(
                _tokenIn,
                address(swapRouter),
                type(uint256).max
            );
        }
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: _tokenIn,
                tokenOut: _tokenOut,
                fee: _poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
        swapRouter.exactInputSingle(params);
    }

    /// @notice Change the validator of the contract
    /// @dev  Ristrict to only owner of the contract
    /// @param _newValidator address of new validator
    function changeValidator(address _newValidator) external onlyOwner {
        if (_newValidator == address(0))
            revert PaymentSplitter__Invalid_Address();
        validator = _newValidator;
    }

    /////////////////////////////////////////Private Function///////////////////////////////////////////////////////////////////

    /// @dev Distribute the ETH that are available in the contract into four addresses
    /// Distributions : (33% to treasury, 33% to devWallet, 33% to burnContract, 1% to founder)
    function paymentDispersion() private {
        uint256 _amount = address(this).balance;
        if (_amount > 0) {
            uint256 _firstDivision = (_amount * 33) / 100;
            uint256 _secondDivision = (_amount * 1) / 100;
            (bool success1, ) = treasury.call{value: _firstDivision}("");

            if (!success1) revert PaymentSplitter__TransferFailed();
            (bool success2, ) = devWallet.call{value: _firstDivision}("");

            if (!success2) revert PaymentSplitter__TransferFailed();
            (bool success3, ) = burn.call{value: _firstDivision}("");

            if (!success3) revert PaymentSplitter__TransferFailed();
            (bool success4, ) = founder.call{value: _secondDivision}("");

            if (!success4) revert PaymentSplitter__TransferFailed();
        }
    }
}
