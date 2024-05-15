// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers } = require("hardhat");
const abi = require("../utils/abi.json");

const USDC = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"; //USDC
const stEth = "0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84"; //stETH
const wstEth = "0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0"; //wstETH
const wEth = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2"; //wETH
const owner = "0x10350802eF8643B15596567c85a6868399C3940e"; //token Holder
const addrZero = "0x0000000000000000000000000000000000000000";
const eth = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE"; //eth address for 1inch
const srcReceiver = "0x3208684f96458c540Eb08F6F01b9e9afb2b7d4f0"; //src receiver
const POOL = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2";
const oneInchRouter = "0x1111111254EEB25477B68fb85Ed929f73A960582";
// const _wallet = "0xbF11F4610F3F23A3311eAD53046583aC23470Fae";
const _wallet = "0xbeC6419cD931e29ef41157fe24C6928a0C952f0b"; //treasury address
const usdt = "0xdac17f958d2ee523a2206206994597c13d831ec7";
const founderAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";

const mainnetTestDeployer = "0x7aa433f3255C595F2e1c29a11a341a349211Fe3c";


async function main() {
  // try {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  const [deployer] = await ethers.getSigners();

  //Impersonation
  const tx = {
    to: owner,
    value: ethers.utils.parseEther("100"),
  };

  //Sending Money
  await deployer.sendTransaction(tx);

  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [owner],
  });

  const signer = await ethers.getSigner(owner);


  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [mainnetTestDeployer],
  });

  const mainnetTestDeployer_Imp = await ethers.getSigner(mainnetTestDeployer);

  console.log("Impersonation Done");

  ////////////////////////////////////////////Moola Token/////////////////////////////////////////////
  const Moola = await ethers.getContractFactory("Moola");
  const moola = await Moola.deploy();
  await moola.deployed();
  console.log("Moola Address", moola.address);

  ////////////////////////////////////////////Burn Contract/////////////////////////////////////////////

  const Burn = await ethers.getContractFactory("TestE");
  const burn = await Burn.deploy(founderAddress, moola.address);
  await burn.deployed();
  console.log("Burn Address", burn.address);

  ////////////////////////////////////////////PaymentSplitter/////////////////////////////////////////////

  const PaymentSplitter = await ethers.getContractFactory("PaymentSplitter");
  const splitter = await PaymentSplitter.deploy(
    founderAddress,
    founderAddress,
    founderAddress,
    burn.address,
    founderAddress
  );
  await splitter.deployed();
  console.log("PaymentSplitter Address", splitter.address);
  // const splitter = await ethers.getContractAt("TestG","0x65e28d4Aa21A34ADE6c87FFEc9A17A9b62004626")


  //////////////////////////////////////Deploying DegenWallet////////////////////////////////////////////

  DegenWallet = await ethers.getContractFactory("TestB");
  const taxFee = 69;
  const wallet = await DegenWallet.deploy(taxFee, splitter.address, _wallet);
  await wallet.deployed();
  console.log("DegenWallet Address", wallet.address);
  // const wallet = await ethers.getContractAt("TestB","0x7b88501622B85ffa4aa66920b99cfbE0264E19c9")

  //////////////////////////////////////Deploying Staking ////////////////////////////////////////////////

  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(founderAddress, wallet.address);
  await staking.deployed();
  console.log("Staking Address", staking.address);

  ////////////////////////////////////////////////USDC////////////////////////////////////////////////////
  usdcContract = await ethers.getContractAt("USDC", USDC);
  stethContract = await ethers.getContractAt("USDC", stEth);
  wstethContract = await ethers.getContractAt("USDC", wstEth);
  wethContract = await ethers.getContractAt("USDC", wEth);
  const connection = usdcContract.connect(signer);
  const value1 = ethers.utils.parseUnits("4000", "6");
  await connection.transfer(deployer.getAddress(), value1);

  ////////////////////////////////////////////Calling Function////////////////////////////////////////////

  //!======================== LEND USD To get ETH ==================================
  
  console.warn(" ==================== Lending USD ==================== ");
  
  console.log("USDC Owner Balance", await connection.balanceOf(owner));

  
  
  // console.log("Wallet eth Balance Before ==========",await wallet.balanceOf());
  // console.log("Deployer eth Balance Before ==========",await deployer.balanceOf());
  

  const dept = new ethers.Contract(POOL, abi, deployer);
  const value = ethers.utils.parseUnits("2000", "6");
  const assetReserveData = await dept.getReserveData(USDC);
  
  
  const atokenAAVE = await ethers.getContractAt("USDC", assetReserveData[8]);
  console.log("Wallet USDC Balance Before ==========",await usdcContract.balanceOf(wallet.address));
  console.log("Deployer USDC Balance Before ==========",await usdcContract.balanceOf(deployer.getAddress()));
  console.log("Deployer aUSDC Balance Before ==============>",await atokenAAVE.balanceOf(deployer.getAddress()));


  await usdcContract.approve(wallet.address, value);
  await wallet.lendTokenOnAave(USDC, value);


  console.warn(" ==================== Lending USD DONE ==================== ");
  
  console.log("Wallet USDC Balance After ==========",await usdcContract.balanceOf(wallet.address));
  console.log("Deployer USDC Balance After ==========",await usdcContract.balanceOf(deployer.getAddress()));
  console.log("Deployer aUSDC Balance After ==============>",await atokenAAVE.balanceOf(deployer.getAddress()));
  
  
  //!======================== BORROW ETH ===========================================
  
  console.warn(" ==================== Borrowing ETH ==================== ");
  const argsEth = {
    asset: wEth,
    value: ethers.utils.parseUnits("0.1","18"),
    type: 2,
  }
  console.log("argsEth",argsEth);
  const assetData = await dept.getReserveData(argsEth.asset);
  console.log("getReserveData======>",assetData)
  const debtTokenAddress = argsEth.type == 1 ? assetData.stableDebtTokenAddress : assetData.variableDebtTokenAddress
  console.log("debtTokenAddress======>",debtTokenAddress)
  const debtTokenEth =  await ethers.getContractAt("PoolHelper",debtTokenAddress);
  
  
  const responseEth = await dept.getUserAccountData(deployer.getAddress())
  console.log("getUserAccountData responseEth======>",responseEth)
  
  console.log("Deployer USDC Balance Before",await usdcContract.balanceOf(deployer.getAddress()));
  // console.log("Deployer wETH Balance Before",await wethContract.balanceOf(deployer.getAddress()));
  console.log("Deployer aUSDC Balance Before ==============>",await atokenAAVE.balanceOf(deployer.getAddress()));

  console.log("Wallet USDC Balance Before",await usdcContract.balanceOf(wallet.address));
  // console.log("Wallet wETH Balance Before",await wethContract.balanceOf(wallet.address));
  
  await dept.setUserUseReserveAsCollateral(USDC,true)
  await debtTokenEth.approveDelegation(wallet.address,argsEth.value)
  await wallet.borrowOnAave(argsEth.asset,argsEth.value,argsEth.type)
  
  console.warn(" ==================== Borrowing ETH Done ==================== ");
  
  console.log("Deployer USDC Balance After",await usdcContract.balanceOf(deployer.getAddress()));
  // console.log("Deployer wETH Balance After",await wethContract.balanceOf(deployer.getAddress()));
  console.log("Deployer aUSDC Balance After ==============>",await atokenAAVE.balanceOf(deployer.getAddress()));

  console.log("Wallet USDC Balance After",await usdcContract.balanceOf(wallet.address));
  // console.log("Wallet wETH Balance After",await wethContract.balanceOf(wallet.address));
  
  
  //!======================== REPAY ETH ==========================================


  
  
  //!======================== ETH ENDS ===========================================
  
  ////lending USD

  // console.log("Lending USD");

  // console.log("Owner Balance", await connection.balanceOf(owner));
  // const dept = new ethers.Contract(POOL, abi, deployer);

  // const value = ethers.utils.parseUnits("2000", "6");

  // const userBalBefore = await usdcContract.balanceOf(deployer.getAddress());
  // console.log("User USDC Balance ==============>", userBalBefore.toString());

  // const contractBalBefore = await usdcContract.balanceOf(wallet.address);
  // console.log(
  //   "Contract USDC Balance Before ==============>",
  //   contractBalBefore.toString()
  // );

  // const balanceBefore1 = await dept.getReserveData(USDC);
  // const atokenAAVE = await ethers.getContractAt("USDC", balanceBefore1[8]);
  // console.log(
  //   "User aUSDC Balance Before ==============>",
  //   await atokenAAVE.balanceOf(deployer.getAddress())
  // );

  // await usdcContract.approve(wallet.address, value);

  // await wallet.lendTokenOnAave(USDC, value);

  // console.log("Lending DONE!");

  // console.log(
  //   "User aUSDC Balance After ==============>",
  //   await atokenAAVE.balanceOf(deployer.getAddress())
  // );

  // const contractBalAfter = await usdcContract.balanceOf(wallet.address);
  // console.log(
  //   "Contract USDC Balance After ==============>",
  //   contractBalAfter.toString()
  // );

  // const userBalAfter = await usdcContract.balanceOf(deployer.getAddress());
  // console.log(
  //   "User USDC Balance After ==============>",
  //   userBalAfter.toString()
  // );

  // testing swapping by uniswap V3
  // const splitterUSDCBal = await usdcContract.balanceOf(splitter.address);
  // const splitterWETHBal = await wethContract.balanceOf(splitter.address);
  // console.log("Splitter USDC Balance", splitterUSDCBal.toString());
  // console.log("Splitter WETH Balance", splitterWETHBal.toString());
  // await splitter.connect(mainnetTestDeployer_Imp).swapTokenToETH(USDC);
  // console.log("DONE", await ethers.provider.getBalance(splitter.address));
  // console.log("DONE", await wethContract.balanceOf(splitter.address));

  // //// borrow asset
  // console.log("============= Borrow asset ============= ");
  // const args = {
  //   asset: USDC,
  //   value: ethers.utils.parseUnits("10","6"),
  //   type: 2,
  // }
  // const res = await dept.getReserveData(args.asset);
  // console.log("getReserveData======>",res)
  // const tokenToBe = args.type == 1 ? res.stableDebtTokenAddress : res.variableDebtTokenAddress
  // console.log("tokenToBe======>",tokenToBe)
  // const response = await dept.getUserAccountData(deployer.getAddress())
  // console.log("getUserAccountData response======>",response)
  // await dept.setUserUseReserveAsCollateral(USDC,true)
  // const debtToken =  await ethers.getContractAt("PoolHelper",tokenToBe);
  // await debtToken.approveDelegation(wallet.address,args.value)
  // const bal = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("User Balance Before",bal);
  // console.log("args",args);
  // await wallet.borrowOnAave(args.asset,args.value,args.type)
  // const res2 = await dept.getUserAccountData(deployer.getAddress())
  // console.log("res2",res2)
  // const bal2 = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("User Balance After",bal2);

  // const bal4 = await usdcContract.balanceOf(wallet.address)
  // console.log("Wallet Balance After lend",bal4);
  

  // ///Repaying Asset

  // console.log("Repaying Asset");
  // await usdcContract.approve(wallet.address,res2.totalDebtBase)
  // // await wallet.repayDebt(args.asset,args.type,((res2.totalDebtBase / 100) + 10000000))
  // await wallet.repayDebt(args.asset,args.type, 12000000)
  // const res3 = await dept.getUserAccountData(deployer.getAddress())
  // console.log("res3",res3)
  // const bal3 = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("User Balance After Repay",bal3);

  // const bal5 = await usdcContract.balanceOf(wallet.address)
  // console.log("Wallet Balance After Repay",bal5);

  // // ///Withdraw Collateral USDC
  // console.log("Withdraw Collateral USDC");
  // const atoken = await dept.getReserveData(USDC);
  // const aToken = await ethers.getContractAt("USDC",atoken[8]);
  // const balanceAfter = await aToken.balanceOf(deployer.getAddress())
  // const tx2 = await aToken.approve(wallet.address, balanceAfter.toString())
  // await tx2.wait(2);
  // console.log("balanceAfter",balanceAfter.toString());
  // await wallet.withdrawCollateral(USDC,balanceAfter.toString())

  // const useraUSDC = await aToken.balanceOf(deployer.getAddress())
  // console.log("User aUSDC Balance After==============>",useraUSDC.toString())
  // const userBalAfter2 = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("User USDC Balance After ==============>",userBalAfter2.toString())

  ///////////////////////////////////////////Lido Staking////////////////////////////////////////////
  //lending steth
  // const dept = new ethers.Contract(POOL, abi,deployer)

  // const ressteth = await stethContract.balanceOf(staking.address)
  // console.log("Contract stETH Before",ressteth.toString())

  // await staking.test({value: ethers.utils.parseEther("1000")})
  // console.log("Lending DONE!");

  // const res1 = await stethContract.balanceOf(staking.address)
  // console.log("Contract stETH After",res1.toString())

  // const res2steth = await stethContract.balanceOf(deployer.getAddress())
  // console.log("User stETH Before",res2steth.toString())

  // await staking.stakeStEth({value: ethers.utils.parseEther("100")})

  // const res3steth = await stethContract.balanceOf(deployer.getAddress())
  // console.log("User stETH After",res3steth.toString())
  // console.log("Wallet",await ethers.provider.getBalance(_wallet))

  /////Staking with stETH
  // await stethContract.approve(wallet.address, ethers.utils.parseEther("10"))

  // const balanceBefore = await dept.getReserveData(wstEth)
  // const atokenAAVE = await ethers.getContractAt("USDC",balanceBefore[8])
  // console.log("User awstEth Balance Before ==============>",await atokenAAVE.balanceOf(deployer.getAddress()))

  // const res4 = await stethContract.balanceOf(wallet.address)
  // console.log("Degen stETH Before",res4.toString())

  // await wallet.lendTokenOnAave(stEth,ethers.utils.parseEther("10"))

  // const balanceAfter = await atokenAAVE.balanceOf(deployer.getAddress())
  // console.log("User awstEth Balance After ==============>",balanceAfter)

  // const res5 = await stethContract.balanceOf(wallet.address)
  // console.log("Contract stETH After",res5.toString())
  // console.log("Wallet",await ethers.provider.getBalance(wallet.address))

  //// borrow asset

  // const args = {
  //   asset: USDC,
  //   value: ethers.utils.parseUnits("100","6"),
  //   type: 2,
  // }
  // const res = await dept.getReserveData(args.asset);
  // const tokenToBe = args.type == 1 ? res.stableDebtTokenAddress : res.variableDebtTokenAddress
  // const response = await dept.getUserAccountData(deployer.getAddress())
  // console.log("response======>",response)
  // await dept.setUserUseReserveAsCollateral(wstEth,true)
  // const debtToken =  await ethers.getContractAt("PoolHelper",tokenToBe);
  // await debtToken.approveDelegation(wallet.address,args.value)
  // const bal = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("User Balance Before",bal);
  // await wallet.borrowOnAave(args.asset,args.value,args.type)
  // const res2 = await dept.getUserAccountData(deployer.getAddress())
  // console.log("res2",res2)
  // const bal2 = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("User Balance After",bal2);
  // console.log("Wallet",await ethers.provider.getBalance(_wallet))

  ///Repaying Asset

  // await usdcContract.approve(wallet.address,res2.totalDebtBase)
  // await wallet.repayDebt(args.asset,args.type,((res2.totalDebtBase / 100) + 1000000))
  // const res3 = await dept.getUserAccountData(deployer.getAddress())
  // console.log("res3",res3)
  // const bal3 = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("User Balance After Repay",bal3);

  // console.log("Wallet",await ethers.provider.getBalance(_wallet))

  // ///Withdraw Collateral stETH

  // const atoken = await dept.getReserveData(wstEth);
  // const aToken = await ethers.getContractAt("USDC",atoken[8]);
  // await aToken.approve(wallet.address, balanceAfter.toString())
  // console.log("HERE")
  // await wallet.withdrawCollateral(stEth,balanceAfter.toString())
  // const userastETHAfter = await aToken.balanceOf(deployer.getAddress())
  // console.log("User astETH Balance ==============>",userastETHAfter.toString())
  // const stETH = await stethContract.balanceOf(deployer.getAddress())
  // console.log("Contract stETH After",stETH.toString())

  // //lending ETH

  // const dept = new ethers.Contract(POOL, abi,deployer)

  // console.log("User ETH Balance Before ==============>",await deployer.getBalance())
  // const balanceBefore = await dept.getReserveData(wEth)
  // const atokenAAVE = await ethers.getContractAt("USDC",balanceBefore[8])

  // console.log("User aweth Balance Before ==============>",await atokenAAVE.balanceOf(deployer.getAddress()))
  // await wallet.lendTokenOnAave(addrZero,0,{value:ethers.utils.parseEther("100")})
  // console.log("User aweth Balance After ==============>",await atokenAAVE.balanceOf(deployer.getAddress()))

  // //testing swapping by uniswap V3
  // const splitterUSDCBal = await usdcContract.balanceOf(splitter.address)
  // console.log("Splitter USDC Balance", splitterUSDCBal.toString())
  // // await splitter.swapTokenToETH(USDC)
  // console.log("DONE",await ethers.provider.getBalance(splitter.address))

  // //borrow asset

  // const args = {
  //   asset: USDC,
  //   value: ethers.utils.parseUnits("100","6"),
  //   type: 2,
  // }
  // const res = await dept.getReserveData(args.asset);
  // const tokenToBe = args.type == 1 ? res.stableDebtTokenAddress : res.variableDebtTokenAddress
  // const response = await dept.getUserAccountData(deployer.getAddress())
  // console.log("response======>",response)
  // await dept.setUserUseReserveAsCollateral(wEth,true)
  // const debtToken =  await ethers.getContractAt("PoolHelper",tokenToBe);
  // await debtToken.approveDelegation(wallet.address,args.value)
  // const bal = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("User Balance Before",bal);
  // await wallet.borrowOnAave(args.asset,args.value,args.type)
  // const res2 = await dept.getUserAccountData(deployer.getAddress())
  // console.log("res2",res2)
  // const bal2 = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("User Balance After",bal2);

  // ///Repaying Asset

  // await usdcContract.approve(wallet.address,res2.totalDebtBase)
  // await wallet.repayDebt(args.asset,args.type,((res2.totalDebtBase / 100) + 1000000))
  // const res3 = await dept.getUserAccountData(deployer.getAddress())
  // console.log("res3",res3)
  // const bal3 = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("User Balance After Repay",bal3);

  ////Withdraw Collateral ETH

  // const atoken = await dept.getReserveData(wEth);
  // const aToken = await ethers.getContractAt("USDC",atoken[8]);
  // const tx2 = await aToken.approve(wallet.address, ethers.utils.parseEther("10"))
  // await tx2.wait(2);
  // await wallet.withdrawCollateral(wEth,ethers.utils.parseEther("100"))
  // const useraWETHAfter = await aToken.balanceOf(deployer.getAddress())
  // console.log("User aWETH Balance After==============>",useraWETHAfter.toString())
  // console.log("User ETH Balance After ==============>",await deployer.getBalance())

  ///////////////////////////////////////////1Inch Protocol////////////////////////////////////////////
  // console.log("Starting swapping")

  ////ETH TO USDC

  //  const dataForETHTOUSD = "0xf78dc2530000000000000000000000007aa433f3255c595f2e1c29a11a341a349211fe3c00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000005a358219dea000000000000000000000000000000000000000000000000000000000000458a3100000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000180000000000000003b6d03403aa370aacf4cb08c7e1e7aa8e8ff9418d73c7e0f8b1ccac8"

  // const balB = await usdcContract.balanceOf(deployer.getAddress())
  // console.log("Contract Bal Before", await usdcContract.balanceOf(wallet.address));

  //  console.log("Before",balB);
  // await wallet.oneInchSwap(eth,ethers.utils.parseEther("10"),dataForETHTOUSD,{value: ethers.utils.parseEther("10")})

  //  console.log('Transaction successfull');
  //  const AfterB = await usdcContract.balanceOf(deployer.getAddress())
  //  console.log("After",AfterB);
  //  console.log("Contract Bal After", await usdcContract.balanceOf(wallet.address));

  ///USDC TO ETH

  //  const dataForUSDTOETH = "0xbc80f1a8000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266000000000000000000000000000000000000000000000000000000003b3180e0000000000000000000000000000000000000000000000000086e7612dc1b64910000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000120000000000000000000000088e6a0c2ddd26feeb64f039a2c41296fcb3f56408b1ccac8"

  // await usdcContract.approve(wallet.address,ethers.utils.parseUnits("1000","6"))
  // console.log('Before',await deployer.getBalance());
  // await wallet.oneInchSwap(USDC,ethers.utils.parseUnits("1000","6"),dataForUSDTOETH)
  // console.log('Transaction successfull');
  // console.log('After',await deployer.getBalance());

  //USDC TO USDT

  // const dataForUSDTOUSDT = "0x12aa3caf000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd09000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec7000000000000000000000000e37e799d5077682fa0a244d46e5649f71457bd09000000000000000000000000f39fd6e51aad88f6f4ce6ab8827279cfffb92266000000000000000000000000000000000000000000000000000000003b3180e0000000000000000000000000000000000000000000000000000000003aa6e8df0000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000014e0000000000000000000000000000000000000000000000000000000001305126ea5b523263bea6a5574858528bd591a3c2bea0f6a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000438ed17390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000003aa6e8df00000000000000000000000000000000000000000000000000000000000000a00000000000000000000000001111111254eeb25477b68fb85ed929f73a96058200000000000000000000000000000000000000000000000000000000651bccc30000000000000000000000000000000000000000000000000000000000000002000000000000000000000000a0b86991c6218b36c1d19d4a2e9eb0ce3606eb48000000000000000000000000dac17f958d2ee523a2206206994597c13d831ec70000000000000000000000000000000000008b1ccac8"

  // usdtContract = await ethers.getContractAt("USDC",usdt)
  // await usdcContract.approve(wallet.address,ethers.utils.parseUnits("1000","6"))
  // console.log('Before',await usdtContract.balanceOf(deployer.getAddress()));
  // await wallet.oneInchSwap(USDC,ethers.utils.parseUnits("1000","6"),dataForUSDTOUSDT)
  // console.log('Transaction successfull');
  // console.log('After',await usdtContract.balanceOf(deployer.getAddress()));
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run scripts/maindeploy.js --network hardhat
