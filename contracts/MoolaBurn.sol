// SPDX-License-Identifier: MIT

/// Company: Decrypted Labs
/// @title Moola Burn
/// @author Rabeeb Aqdas
/// @notice This contract is useful for the validator and onwer of the contract to burn the supply on MOOLA tokens
/// @dev All function calls are currently implemented without side effects
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/access/Ownable.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

interface IMOOLA {
    function burn(uint256 amount) external;
}

interface IWETH9 {
   function deposit() external payable;
}

error Burn__NotEnoughBalance();
error Burn__Invalid_Address();
contract MoolaBurn is Ownable {
 //////////////////////////////////////////State Variables///////////////////////////////////////////////////////////////////

    ISwapRouter private constant swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);    
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private moola;
    address public validator;   
    uint24 private constant POOLFEE = 3000;   

  receive() external payable {}

modifier onlyValidator() {
    require(validator == _msgSender(),"Not Authorized!");
    _;
}

  constructor(address _validator,address _moola) Ownable(_msgSender()) {
    validator = _validator;
    moola = _moola;
  }

/////////////////////////////////////////Only Validator Function///////////////////////////////////////////////////////////////////
 

    /// @notice Swap ETH to MOOLA tokens and burn them all
    /// @dev  Ristrict to only validator of the contract
    /// @param _amountToBeBurn amount that needs to be burn
  function swapEthForMoola(uint256 _amountToBeBurn) external onlyValidator {
    address _WETH9 = WETH9;
    address _moola = moola;
   if(_amountToBeBurn > address(this).balance) revert Burn__NotEnoughBalance();   
    IWETH9(_WETH9).deposit{value: _amountToBeBurn}();
     if(IERC20(_WETH9).allowance(address(this),address(swapRouter)) < _amountToBeBurn) {
    TransferHelper.safeApprove(_WETH9, address(swapRouter), type(uint256).max);
   }
   
    ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: _WETH9,
                tokenOut: _moola,
                fee: POOLFEE,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: _amountToBeBurn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });
    uint256 amountOut = swapRouter.exactInputSingle(params);  
    IMOOLA(_moola).burn(amountOut);
  }

/////////////////////////////////////////Only Owner Function///////////////////////////////////////////////////////////////////

    /// @notice Change the validator of the contract
    /// @dev  Ristrict to only owner of the contract
    /// @param _newValidator address of new validator
function changeValidator(address _newValidator) external onlyOwner {
    if(_newValidator == address(0)) revert Burn__Invalid_Address();
    validator = _newValidator;
}
}
