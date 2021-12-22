import { ethers } from "ethers";
import sdk from "./1-initialize-sdk.js";

const voteModule = sdk.getVoteModule("0xDe590a5829997C21819E65BDEFfE9AB87b38d512");

const tokenModule = sdk.getTokenModule("0x447Ea4a2cE80f5e7c80FCf494A2D7A3e36FC52AB");

(async () => {
    try {
        // give treasury power to mint additional token if needed
        await tokenModule.grantRole("minter", voteModule.address);

        console.log("Successfully gave vote module permssions to act on token module");
    } catch (error) {
        console.error("Failed to give Voting Module power to control treasury", error);
        process.exit(1);
    }

    try {
        const ownedTokenBalance = await tokenModule.balanceOf(process.env.WALLET_ADDRESS);
        const ownedAmount = ethers.BigNumber.from(ownedTokenBalance.value);
        const percent90 = ownedAmount.div(100).mul(90);

        await tokenModule.transfer(voteModule.address, percent90);

        console.log("Successfully transferred tokens to vote module");
    } catch(error) {
        console.error("Failed to transfer tokens to vote module", error);
    }
})();