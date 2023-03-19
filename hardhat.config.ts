import "dotenv/config";
import {HardhatUserConfig, task, types} from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-solhint";
import "@nomiclabs/hardhat-etherscan";
import "hardhat-contract-sizer";
import "@nomicfoundation/hardhat-network-helpers";
import helpers from "@nomicfoundation/hardhat-network-helpers";
import {BigNumber} from "ethers";

const WETH = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1";
const USDC = "0xff970a61a04b1ca14834a43f5de4533ebddb5cc8";
const USDT = "0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9";

task("balance", "check balance").setAction(async ({amount}, hre) => {
    const balanceEth = await hre.ethers.getContractAt("IERC20", WETH);
    const balance = await balanceEth.balanceOf("0x5513a48f3692df1d9c793eeab1349146b2140386");
    console.log("Updated balance: ", balance);
});

task("balanceUSDC", "check balance").setAction(async (taskArgs, hre) => {
    const balanceEth = await hre.ethers.getContractAt("IERC20", USDC);
    const accounts = await hre.ethers.getSigners();
    const balance = await balanceEth.balanceOf(accounts[0].address);
    console.log("Updated balance: ", balance);
});

task("fundUSDC", "Funds account with USDC").setAction(async (taskArgs, hre) => {
    await hre.run("swap");
    await hre.run("balanceUSDC");
});

task("fundWETH", "Funds account with WETH")
    .addOptionalParam("amount", "amount to add", 1, types.float)
    .setAction(async ({amount}, hre) => {
        const wETH = await hre.ethers.getContractAt("IWETH9", WETH);
        await wETH.deposit({value: amount});

        const balanceEth = await hre.ethers.getContractAt("IERC20", WETH);
        const accounts = await hre.ethers.getSigners();
        const balance = await balanceEth.balanceOf(accounts[0].address);
        console.log("Updated balance: ", balance.toNumber());
    });

task("swap", "Swap").setAction(async (taskArgs, hre) => {
    const amount = 1000000000000;
    hre.run("fundWETH", {amount: amount});

    const exampleSwap = await hre.ethers.getContractAt("ExampleSwap", "0x720472c8ce72c2A2D711333e064ABD3E6BbEAdd3");

    const wETH = await hre.ethers.getContractAt("IERC20", WETH);

    await wETH.approve(exampleSwap.address, amount);

    await exampleSwap.exactInputSingle(amount, 1);

    await hre.run("balanceUSDC");
});

const config: HardhatUserConfig = {
    defaultNetwork: "hardhat",

    solidity: {
        compilers: [
            {
                version: "0.8.9",
                settings: {
                    optimizer: {
                        enabled: true,
                        runs: 1e8,
                    },
                },
            },
        ],
    },
    etherscan: {
        // apiKey: `${process.env.ETHERSCAN_API_KEY}`,
    },
    gasReporter: {},
    contractSizer: {
        // runOnCompile: `${process.env.REPORT_SIZE}` == "true",
    },
};

export default config;
