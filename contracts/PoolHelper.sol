// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
import { IPool } from "@aave/core-v3/contracts/interfaces/IPool.sol";
contract PoolHelper {

  /**
   * @dev Returns the amount of tokens in existence.
   */
  function totalSupply() external view returns (uint256){}
 function mint(uint256 amount) public returns (bool) {}
  /**
   * @dev Returns the token decimals.
   */
  function decimals() external view returns (uint8){}

  /**
   * @dev Returns the token symbol.
   */
  function symbol() external view returns (string memory){}

  /**
  * @dev Returns the token name.
  */
  function name() external view returns (string memory){}

  /**
   * @dev Returns the bep token owner.
   */
  function getOwner() external view returns (address){}

  /**
   * @dev Returns the amount of tokens owned by `account`.
   */
  function balanceOf(address account) external view returns (uint256){}


  function transfer(address recipient, uint256 amount) external returns (bool){}

  function allowance(address _owner, address spender) external view returns (uint256){}

  
  function approve(address spender, uint256 amount) external returns (bool){}


  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool){}

function approveDelegation(address delegatee, uint256 amount) external{}

  function borrow(
    address asset,
    uint256 amount,
    uint256 interestRateMode,
    uint16 referralCode,
    address onBehalfOf
  ) external{}

    function setUserUseReserveAsCollateral(
    address asset,
    bool useAsCollateral
  ) external{}

  





}


