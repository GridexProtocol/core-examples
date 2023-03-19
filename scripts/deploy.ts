import {ethers} from "hardhat";

async function main() {
    const ExampleSwap = await ethers.getContractFactory("ExampleSwap");
    const exampleSwap = await ExampleSwap.deploy("0x426B751AbA5f49914bFbD4A1E45aEE099d757733");

    await exampleSwap.deployed();

    console.log(`ExampleSwap deployed to ${exampleSwap.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
