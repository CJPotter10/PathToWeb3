import sdk from "./1-initialize-sdk.js";

const app = sdk.getAppModule("0x209086EDF35Ff83Bd5a02D9a1cC65507Fe4273D4");

(async () => {
    try {
        const tokenModule = await app.deployTokenModule({
            name: "InHocDAO Governance Token",
            symbol: "ΣΧ",
        });
        console.log(
            "Successfully deployed token module, address: ", 
            tokenModule.address,
        );
    } catch(error) {
        console.error("failed to deploy token module", error);
    }
})();