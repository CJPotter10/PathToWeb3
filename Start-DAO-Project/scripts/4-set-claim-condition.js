import { BundleDropModule } from "@3rdweb/sdk";
import sdk from "./1-initialize-sdk.js"

const bundleDrop = sdk.getBundleDropModule(
    "0xa1d68b67a53b2bc130e0A3e696C11D7f5a96A8f0"
);

(async () => {
    try {
        const claimConditionFactory = bundleDrop.getClaimConditionFactory();
        claimConditionFactory.newClaimPhase({
            startTime: new Date(),
            maxQuantity: 50_000,
            maxQuantityPerTransaction: 1,
        });

        await bundleDrop.setClaimCondition(0, claimConditionFactory);
        console.log("Successfully set claim conditions");
    } catch(error) {
        console.error("Failed to set claim condition", error);
    }
    
})()