import sdk from "./1-initialize-sdk.js";
import { readFileSync } from "fs";

const bundleDrop = sdk.getBundleDropModule(
    "0xa1d68b67a53b2bc130e0A3e696C11D7f5a96A8f0"
);

(async () => {
    try {
        await bundleDrop.createBatch([
            {
                name: "Badge of a Sigma Chi",
                description: "This NFT will grant you access into the community of InHocDAO",
                image:readFileSync("scripts/assets/badge.jpg")
            },
        ]);
        console.log("Successfully created a new NFT in the drop!");
    } catch(error) {
        console.error("failed to create the new NFT", error);
    }
})()