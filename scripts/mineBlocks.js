

async function main() {

console.log("Started Mining........")
    for(let i = 0 ; i < 200 ; i ++) {
        await network.provider.request({
            method: "evm_mine",
            params:[]
        })
    }
    console.log("Mining Completed!")

  // console.log("Incrementing Time.....");
  // await network.provider.send("evm_increaseTime", [3600])
  // console.log("Incrementing Done!");  
}



main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
