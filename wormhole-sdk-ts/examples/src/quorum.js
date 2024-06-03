import { api, toChain, wormhole } from "@wormhole-foundation/sdk";
import algorand from "@wormhole-foundation/sdk/algorand";
import cosmwasm from "@wormhole-foundation/sdk/cosmwasm";
import evm from "@wormhole-foundation/sdk/evm";
import solana from "@wormhole-foundation/sdk/solana";
const skipChains = [
    "Pythnet",
    "Evmos",
    "Osmosis",
    "Kujira",
    "Klaytn",
    "Wormchain",
    "Near",
    "Sui",
    "Xpla",
    "Aptos",
    "Cosmoshub",
];
(async function () {
    const wh = await wormhole("Mainnet", [evm, solana, algorand, cosmwasm]);
    const hbc = await getHeartbeats(wh.config.api);
    for (const [chain, heights] of Object.entries(hbc)) {
        if (skipChains.includes(chain))
            continue;
        try {
            const ctx = wh.getChain(chain);
            // ..
            await ctx.getRpc();
            const chainLatest = await ctx.getLatestBlock();
            const stats = getStats(Object.values(heights));
            console.log(chain, BigInt(chainLatest) - stats.quorum);
        }
        catch (e) {
            console.error(chain, e);
        }
    }
})();
async function getHeartbeats(apiUrl) {
    const hbs = await api.getGuardianHeartbeats(apiUrl);
    const nets = hbs
        .map((hb) => {
        return hb.rawHeartbeat.networks
            .map((n) => {
            return {
                address: hb.verifiedGuardianAddr,
                chainId: n.id,
                height: BigInt(n.height),
            };
        })
            .flat();
    })
        .flat();
    const byChain = {};
    for (const status of nets) {
        // Jump
        if (status.address === "0x58CC3AE5C097b213cE3c81979e1B9f9570746AA5")
            continue;
        let chain;
        try {
            chain = toChain(status.chainId);
        }
        catch {
            continue;
        }
        if (!(chain in byChain))
            byChain[chain] = {};
        byChain[chain][status.address] = status.height;
    }
    return byChain;
}
function getStats(vals) {
    vals.sort();
    const max = vals[vals.length - 1];
    const min = vals[0];
    let sum = 0n;
    for (const v of vals) {
        sum += v;
    }
    const mean = sum / BigInt(vals.length);
    const quorum = vals[Math.floor(vals.length / 3) * 2];
    return { max: max, min: min, quorum, mean, delta: max - min };
}
//# sourceMappingURL=quorum.js.map