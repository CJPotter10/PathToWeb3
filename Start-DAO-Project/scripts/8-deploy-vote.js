import sdk from "./1-initialize-sdk.js";

const appModule = sdk.getAppModule("0x209086EDF35Ff83Bd5a02D9a1cC65507Fe4273D4");

(async () => {
    try {
        const voteModule = await appModule.deployVoteModule({
            name: "InHocDAO's Proposals",
            votingTokenAddress: "0x447Ea4a2cE80f5e7c80FCf494A2D7A3e36FC52AB",
            proposalStartWaitTimeInSeconds: 0,
            proposalVotingTimeInSeconds: 24*60*60,
            votingQuorumFraction: 1,
            minimumNumberOfTokensNeededToPropose: "0",
        });

        console.log("Successfully deployed vote module, address: ", voteModule.address);
    } catch(error) {
        console.error("Failed to deploy Voting Module", error);
    }
})();