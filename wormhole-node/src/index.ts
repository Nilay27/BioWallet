import express from 'express';
import bodyParser from 'body-parser';
import { wormhole, Chain, UniversalOrNative, UniversalAddress, ChainAddress, amount, TxHash } from "@wormhole-foundation/sdk";
import evm from "@wormhole-foundation/sdk/evm";
import sui from "@wormhole-foundation/sdk/sui";

const app = express();
const PORT = process.env.PORT || 3000;

app.use(bodyParser.json());

app.post('/prepareTransactionBlock', async (req, res) => {
    try {
        const { recipientChain, senderAddress, receiverAddress, amountToSend } = req.body;
        console.log("Request received with body:", req.body);
        
        // Initialize the Wormhole SDK
        const wh = await wormhole("Testnet", [evm, sui]);
        const ctx = wh.getChain("Sui");  
        ctx.config.rpc = "https://fullnode.testnet.sui.io:443/";
        console.log("Context initialized for Sui:", ctx);
    
        const rcv = wh.getChain(recipientChain as Chain);
        console.log("Recipient chain context:", rcv);

        const sndTb = await ctx.getTokenBridge();
        console.log("Sender TokenBridge context:", sndTb);
        
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
        console.log("Transfer initiated:", transfer);

        // Get the first transaction block for simplicity
        const tx = await transfer.next();
        console.log("Transaction block received:", tx);
        
        const suiClient = await ctx.getRpc();
        if (tx.done) {
            console.error("No transaction created.");
            res.status(500).json({ error: 'No transaction was created' });
        } else {
            // Return the transaction block to the client
            tx.value.transaction.setSenderIfNotSet(senderAddress);
            console.log("Sender set as:", senderAddress);
            const serializedTransaction = await tx.value.transaction.build({ client: suiClient });
            // Convert Uint8Array to a regular array
            const serializedTransactionArray = Array.from(serializedTransaction);
            res.json({ transactionBlock: serializedTransactionArray });
        }
    } catch (error) {
        if (error instanceof Error) {
            console.error("Error occurred:", error);
            res.status(500).json({ error: error.message });
        } else {
            console.error("Unknown error occurred:", error);
            res.status(500).json({ error: 'An unknown error occurred' });
        }
    }
});

// Health check endpoint to verify server is running
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});
