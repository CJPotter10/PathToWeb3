import { ethers } from "ethers";
import sdk from "./1-initialize-sdk.js";
import { readFile, readFileSync } from "fs";

const app = sdk.getAppModule("0x209086EDF35Ff83Bd5a02D9a1cC65507Fe4273D4");

(async () => {
    try{
        const bundleDropModule = await app.deployBundleDropModule({
            // The collections name
            name: "InHocDAO Membership",
            description: "A DAO for sigma chi's to invest in each other",
            image: readFileSync("scripts/assets/nft-pic.png"),
            primarySaleRecipientAddress: ethers.constants.AddressZero,
        });

        console.log("successfully deployed bundleDrop module, address:", bundleDropModule.address);
        console.log("BundleDrop metadata:", await bundleDropModule.getMetadata());
    } catch(error) {
        console.error("failed to deploy buundleDrop module", error);
    }
})()