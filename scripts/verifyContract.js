const {run} = require("hardhat")


const verify = async (contractAddress, args, config) => {
    // console.log("Verifying Contract........")
    try{
        if(config) {
            await run("verify:verify",{
                address : contractAddress,
                constructorArguments:args,
            })
        }else {
            await run("verify:verify",{
                address : contractAddress,
                constructorArguments:args,
                contract: "contracts/Treasury.sol:Treasury"
            }) 
        }
    }catch(err){
        if(err.message.toLowerCase().includes('already verified')){
            console.log("Already Verified!")
        }else {
            console.log(err)
        }
    }
}

module.exports = {verify};