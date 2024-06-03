export {};
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

  
  
})("Sui", "0xb40f32bd1068afa2e47de0512d3d57d1233ca1670b1154afc3fc3b102515a8c0","0xb40f32bd1068afa2e47de0512d3d57d1233ca1670b1154afc3fc3b102515a8c0");

 */
//# sourceMappingURL=index.d.ts.map