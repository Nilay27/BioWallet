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
    
    const sender: UniversalOrNative<"Sui"> = new UniversalAddress(senderAddress);
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

/**
 * (async function (recipientChain:string, senderAddress: string, recieverAddress:string) {
  // EXAMPLE_WORMHOLE_INIT
  const wh = await wormhole("Mainnet", [evm, solana, aptos, algorand, cosmwasm, sui]);
  // EXAMPLE_WORMHOLE_INIT

  // EXAMPLE_WORMHOLE_CHAIN
  // Grab a ChainContext object from our configured Wormhole instance
  var ctx = wh.getChain("Sui");  
  ctx.config.rpc = "https://fullnode.mainnet.sui.io:443/"
  
  console.log("ctx", ctx)
  // EXAMPLE_WORMHOLE_CHAIN
  
  // const coreBridge = await ctx.getWormholeCore();

  // const publishTxs = coreBridge.publishMessage()
  const rcv = wh.getChain(recipientChain as Chain);
  console.log("rcv", rcv)
  // const sender = await getSigner(ctx);
  // const receiver = await getSigner(rcv);
  const sndTb = await ctx.getTokenBridge();
  console.log("sndtb", sndTb)
  // Get a Token Bridge contract client on the source
  const sender: UniversalOrNative<"Sui"> = new UniversalAddress(senderAddress);
  const recipient: ChainAddress<Chain> = {
    chain: recipientChain as Chain,
    address: new UniversalAddress(recieverAddress) // Adjust based on your actual logic
  };

  // Create a transaction stream for transfers
  const transfer = sndTb.transfer(
    sender,
    recipient,
    "native",
    amount.units(amount.parse("0.1", ctx.config.nativeTokenDecimals)),
  );
  
  console.log("transfer", transfer)
  // Sign and send the transaction
  const txids: TxHash[] = [];
  let txbuff: UnsignedTransaction<"Devnet", "Sui">[] = [];
  for await (const tx of transfer) {
    console.log("transaction", tx)
  }

  
  
})("Sui", "0xa396d3c411b9b00156f9fc20bfd7dc13c3106b1cc7f3b012263a3756757de37b","0xb40f32bd1068afa2e47de0512d3d57d1233ca1670b1154afc3fc3b102515a8c0");

 


 */
