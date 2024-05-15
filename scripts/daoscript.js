
const { ethers } = require("hardhat");
const abi = require("../utils/abi.json");

const USDC = '0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48' //USDC
const stEth = '0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84' //stETH  
const wstEth = '0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0' //wstETH  
const wEth = '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2' //wETH  
const owner = '0x10350802eF8643B15596567c85a6868399C3940e' //token Holder
const eth = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE'  //eth address for 1inch
const srcReceiver = '0x3208684f96458c540Eb08F6F01b9e9afb2b7d4f0'  //src receiver
const POOL = "0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2";
const oneInchRouter = "0x1111111254EEB25477B68fb85Ed929f73A960582";
// const _wallet = "0xbF11F4610F3F23A3311eAD53046583aC23470Fae";
const _wallet = "0xbeC6419cD931e29ef41157fe24C6928a0C952f0b";               //treasury address
const usdt = "0xdac17f958d2ee523a2206206994597c13d831ec7"
// const deployerAddress = "0x7A675d2485924E19A7C43E540B08b8f4d7426884";     //for goerli
const deployerAddress = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";        //for localhost
const addrZero = '0x0000000000000000000000000000000000000000'               
const devAddress = "0xeF63aF768f7aAFb393EBa6ac0Bf602040e6490d1";
const founderAddress = "0xeF63aF768f7aAFb393EBa6ac0Bf602040e6490d1";
const person1 = "0xeF63aF768f7aAFb393EBa6ac0Bf602040e6490d1";                //for goerli
// const proposalThresold = ethers.utils.parseEther("100");                     //100 tokens required to make proposal
const proposalThresold = ethers.utils.parseEther("1000000");                     //1M tokens required to make proposal
const taxFee = 69;                                                           // 0.69%
const votingDelay = 5;                                                       // 1 minute
const minimumDelay = 60;                                                     // 1 minute  
const votingPeriod = 50;                                                     // 10 minutes
const quorumPercentage = 5;                                                  // 5% of totalSupply

async function main() {
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

  console.log("Impersonation Done")

    console.log("DEPLOYING CONTRACTS.......................");    

    ////////////////////////////////////////////Moola Token/////////////////////////////////////////////
    const Moola = await ethers.getContractFactory("Moola")
    const moola = await Moola.deploy()
    await moola.deployed()
    console.log("Moola Address", moola.address)

    ////////////////////////////////////////////Degen Forest NFT/////////////////////////////////////////////
        const DegenForest = await ethers.getContractFactory("DegenForest")
        const forest = await DegenForest.deploy()
        await forest.deployed()
        console.log("DegenForest Address", forest.address)

    ////////////////////////////////////////////Burn Contract/////////////////////////////////////////////

    const Burn = await ethers.getContractFactory("Burn")
    const burn = await Burn.deploy(moola.address)
    await burn.deployed()
    console.log("Burn Address", burn.address)

    ////////////////////////////////////////////Treasury/////////////////////////////////////////////

    const Treasury = await ethers.getContractFactory("Treasury");
    const treasury = await Treasury.deploy(minimumDelay,[],[],deployerAddress);
    await treasury.deployed();
    console.log("Treasury Address", treasury.address);

    ////////////////////////////////////////////DegenGovernor/////////////////////////////////////////////

    const  DegenGovernor = await ethers.getContractFactory("DegenGovernor");
    const degenGovernor = await DegenGovernor.deploy(moola.address, treasury.address,votingDelay,proposalThresold,votingPeriod,quorumPercentage,forest.address);
    await degenGovernor.deployed();
    console.log("DegenGovernor Address", degenGovernor.address);

    ////////////////////////////////////////////PaymentSplitter/////////////////////////////////////////////
 
    const PaymentSplitter = await ethers.getContractFactory("PaymentSplitter")
    const splitter = await PaymentSplitter.deploy(treasury.address,devAddress,burn.address,founderAddress)
    await splitter.deployed()
    console.log("PaymentSplitter Address", splitter.address)

    ////////////////////////////////////////////Degen Wallet/////////////////////////////////////////////

    const DegenWallet = await ethers.getContractFactory("DegenWallet");
    const wallet = await DegenWallet.deploy(taxFee,splitter.address,treasury.address);
    await wallet.deployed();
    console.log("DegenWallet Address", wallet.address);
    ////////////////////////////////////////////Staking Contract/////////////////////////////////////////////
  
    const Staking = await ethers.getContractFactory("Staking");
    const staking = await Staking.deploy(wallet.address);
     await staking.deployed();
     console.log("Staking Address", staking.address);

   

    ////////////////////////////////////////////Governor Setup/////////////////////////////////////////////
   
    console.log("Setting up DAO........")
    const proposerRole = await treasury.PROPOSER_ROLE()
    const executorRole = await treasury.EXECUTOR_ROLE()
    const adminRole = await treasury.DEFAULT_ADMIN_ROLE()
    await treasury.grantRole(proposerRole,degenGovernor.address)
    await treasury.grantRole(executorRole,addrZero)
    await treasury.revokeRole(adminRole,deployerAddress)
    console.log("DAO has been setup........")

    
////////////////////////////////////////////////USDC////////////////////////////////////////////////////
usdcContract = await ethers.getContractAt("USDC",USDC);
const connection = usdcContract.connect(signer)
const value1 = ethers.utils.parseUnits('4000','6');   
await connection.transfer(deployer.getAddress(),value1)

    ////////////////////////////////////////////Function Calling/////////////////////////////////////////////

////lending USD
console.log("Lending USD");

console.log('Owner Balance',await connection.balanceOf(owner)) 
const dept = new ethers.Contract(POOL, abi,deployer)

const value = ethers.utils.parseUnits('2000','6');   

const userBalBefore = await usdcContract.balanceOf(deployer.getAddress())
console.log("User USDC Balance ==============>",userBalBefore.toString())   

const contractBalBefore = await usdcContract.balanceOf(wallet.address)
console.log("Contract USDC Balance Before ==============>",contractBalBefore.toString())   

const balanceBefore1 = await dept.getReserveData(USDC)
const atokenAAVE = await ethers.getContractAt("USDC",balanceBefore1[8])  
console.log("User aUSDC Balance Before ==============>",await atokenAAVE.balanceOf(deployer.getAddress()))

 await usdcContract.approve(wallet.address,value)

//  await wallet.lendTokenOnAave(USDC,value)

 console.log("Lending DONE!");

console.log("User aUSDC Balance After ============>",await atokenAAVE.balanceOf(deployer.getAddress()))

const contractBalAfter = await usdcContract.balanceOf(wallet.address)
console.log("Contract USDC Balance After ==========>",contractBalAfter.toString())   

const userBalAfter = await usdcContract.balanceOf(deployer.getAddress())
console.log("User USDC Balance After ==============>",userBalAfter.toString())  

// //// borrow asset
// console.log("Borrow asset");
// const args = {
//   asset: USDC,
//   value: ethers.utils.parseUnits("100","6"),
//   type: 2,
// }
// const res = await dept.getReserveData(args.asset);
// const tokenToBe = args.type == 1 ? res.stableDebtTokenAddress : res.variableDebtTokenAddress
// const response = await dept.getUserAccountData(deployer.getAddress())
// console.log("response======>",response)                                        
// await dept.setUserUseReserveAsCollateral(USDC,true) 
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

// console.log("Repaying Asset");
// await usdcContract.approve(wallet.address,res2.totalDebtBase)
// await wallet.repayDebt(args.asset,args.type,((res2.totalDebtBase / 100) + 10000000))
// const res3 = await dept.getUserAccountData(deployer.getAddress())
// console.log("res3",res3)
// const bal3 = await usdcContract.balanceOf(deployer.getAddress())
// console.log("User Balance After Repay",bal3);


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
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run scripts/testdeploy.js --network hardhat
