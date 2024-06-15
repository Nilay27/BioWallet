// index.ts
import express from 'express';
import bodyParser from 'body-parser';
import { wormhole, Chain, UniversalOrNative, UniversalAddress, ChainAddress, amount, TxHash } from "@wormhole-foundation/sdk";
import evm from "@wormhole-foundation/sdk/evm";
import sui from "@wormhole-foundation/sdk/sui";


const app = express();
const PORT = 3000;

app.use(bodyParser.json());

app.post('/prepareTransactionBlock', async (req, res) => {
    try {
        const { recipientChain, senderAddress, receiverAddress, amountToSend } = req.body;
        console.log("req.body", req.body)
        
        // Initialize the Wormhole SDK
        const wh = await wormhole("Testnet", [evm, sui]);
        const ctx = wh.getChain("Sui");  
        ctx.config.rpc = "https://fullnode.testnet.sui.io:443/";
        console.log("ctx", ctx)
    
        const rcv = wh.getChain(recipientChain as Chain);
        console.log("rcv", rcv)

        const sndTb = await ctx.getTokenBridge();
        console.log("sndtb", sndTb)
        
        const sender: UniversalOrNative<typeof recipientChain & Chain> = new UniversalAddress(senderAddress);
        const recipient: ChainAddress<Chain> = {
            chain: recipientChain as Chain,
            address: new UniversalAddress(receiverAddress)
        };

        const transfer = sndTb.transfer(
            sender,
            recipient,
            "native",
            amount.units(amount.parse(amountToSend, ctx.config.nativeTokenDecimals)),
        );
        console.log("transfer", transfer)
        // Get the first transaction block for simplicity
        const tx = await transfer.next();
        console.log("tx", tx)
        const suiClient = await ctx.getRpc()
        if (tx.done) {
            res.status(500).json({ error: 'No transaction was created' });
        } else {
            // Return the transaction block to the client
            tx.value.transaction.setSenderIfNotSet(senderAddress)
            console.log("sender set as", senderAddress)
            const serializedTransaction = await tx.value.transaction.build({client: suiClient})
            // Convert Uint8Array to a regular array
            const serializedTransactionArray = Array.from(serializedTransaction);
            res.json({ transactionBlock: serializedTransactionArray });
        }

    } catch (error) {
        console.error("Error occurred:", error);
        res.status(500).json({ error: error.message || 'An error occurred' });
    }

    // const txids: TxHash[] = [];
    // const sampleTxn: string = "6D22xuBNm6raJ8kcU1PEdpcH2s8FfZZVaGa7dhLUMhFY"
    // txids.push(sampleTxn)
    // console.log("Txids", txids)
    // const txs = txids.map((txid) => ({ chain: ctx.chain, txid }));
    // console.log("txs", txs)
    // // Get the wormhole message id from the transaction
    // const [whm] = await ctx.parseTransaction(txs[txs.length - 1]!.txid);
    // console.log("Wormhole Messages: ", whm);
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
