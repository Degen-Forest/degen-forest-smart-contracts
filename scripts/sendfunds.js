
const { ethers } = require("hardhat");
const { verify } = require("./verifyContract");


const deployerAddress = "0xeF63aF768f7aAFb393EBa6ac0Bf602040e6490d1";     //for goerli
const person1 = "0x7A675d2485924E19A7C43E540B08b8f4d7426884";                //for goerli
const person2 = "0x808f0597D8B83189ED43d61d40064195F71C0D15";                //for goerli
const person3 = "0xf3545A1eaD63eD1A6d8b6E63d68D937cdBf1aeE4";                //for goerli
const person4 = "0x5cbD5063DdaE154c546860e2A4D2C16E2e1C786c";                //for goerli
const person5 = "0xa13e152ED443c52DF0c33612E80904Ce849db3Ae";                //for goerli
const person6 = "0x1260e408d9E1Ad2f2293Fb092D840BF252c68833";                //for goerli
                                    

async function main() {
 // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  
    } 

    ////////////////////////////////////////////Moola Token/////////////////////////////////////////////
    const moola = await ethers.getContractAt("Moola","0xA21D3F133Fee58408a55375C0E8723A08EAD0dea")
   

    ////////////////////////////////////////////Function Calling/////////////////////////////////////////////

    console.log("Calling Moola Functions........", await moola.balanceOf(deployerAddress))
    // await moola.transfer(person1,ethers.utils.parseEther("100000"))
    await moola.transfer(person2,ethers.utils.parseEther("200000"))
    await moola.transfer(person3,ethers.utils.parseEther("4000000"))
    await moola.transfer(person4,ethers.utils.parseEther("500000"))
    await moola.transfer(person5,ethers.utils.parseEther("300000"))
    await moola.transfer(person6,ethers.utils.parseEther("1000000"))

    await moola.delegate(deployerAddress,{gasLimit: 5000000});
    console.log("Done!")

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run scripts/testdeploy.js --network hardhat
