

---

# BioWallet

<img src="./BioWallet/Assets.xcassets/BioWalletLogo.imageset/Bio_Wallet%201.png" alt="BioWallet Logo" width="200" height="200">


#### **Your device is your hardware wallet, simple, secure and streamlined!**
## Demo Link

[Watch the Demo](https://youtu.be/Ihawy_Cb5iI?si=dbHM6l5ECHXhdC5U)

## Features
- **Hardware Wallet Transformation**: BioWallet securely stores your private key in the Secure Enclave of your device, transforming it into a hardware wallet. 
  - This eliminates the hassle of managing seed phrases and significantly reduces the risk of compromising your private key.
- **SUI Network Integration**: Built on the SUI network, leveraging its robust signature flexibility and support for Secp256R1 signature curve.
- **Multichain Support** : Using wormhole SDK to facilitate seamless cross-chain transactions directly from our Mobile Phones, transforming them into *Cross-Chain Hardware Wallets*. 
- **Secure Transactions**: Sign and perform transactions securely with biometric authentication using secure enclave.
- **Enhanced Security**: No more seed phrases; private keys never leave the device, ensuring top-notch security.
- **Passkey Backup**: Seamlessly interact with the wallet across your devices utilizing passkeys.
- **User-Friendly Interface**: Intuitive and easy-to-use interface with essential features.


### Upcoming Features

#### WebAuthn SDK
- **Streamlined Onboarding**: An upcoming WebAuthn SDK will make onboarding extremely streamlined. Users won't even need to install the app and can interact with webApps that integrate with our SDK directly.
    - **SUI SIP Support**: This feature will leverage the upcoming SIP ([SIP-9](https://github.com/sui-foundation/sips/pull/9/)) which will enable WebAuthn support.

#### MultiSig Wallet
- **MultiSig Support**: BioWallet will soon support MultiSig wallets, allowing for enhanced security and flexibility.
    - **Multiple Key Schemes**: The MultiSig wallet will utilize keys across different schemes including secp256r1, secp256k1, and Ed25519.

#### Recovery Methods
  - **MPC Based Recovery**: In case the device does not support passkeys/ the passkeys were deleted.
    - Multi-Party Computation (MPC) based recovery ensures you can regain access to your wallet even if you lose your device (upcoming feature).


## Integrations for SUI-OverFlow
1. [Wormhole (Multichain-Track)](#wormhole-multichain-track)
2. [BlockEden](#blockeden)

### Wormhole (Multichain-Track)
We leverage **Wormhole's Cross-Chain Protocol** to facilitate seamless cross-chain transactions directly from our Mobile Phones, transforming them into **Cross-Chain Hardware Wallets**. This integration harnesses the power of the Wormhole SDK to support versatile signature schemes and enable cross-chain functionality.

Following are the features of our integration:

- **Using Wormhole SDK in Swift**: Interacting with the Wormhole SDK in Swift for cross-chain transactions, even though the SDK is primarily in TypeScript.
  ```swift
  func buildBridgeTransaction(recipientChain: String, senderAddress: String, receiverAddress: String, amountToSend: String) async throws -> Data? {
        let urlString = "http://localhost:3000/prepareTransactionBlock"
        guard let url = URL(string: urlString) else {
            return nil
        }
        let payload: [String: Any] = [
            "recipientChain": recipientChain,
            "senderAddress": senderAddress,
            "receiverAddress": receiverAddress,
            "amountToSend": amountToSend
        ]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return nil
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            return nil
        }
        do {
            let serializedTransaction = try JSONDecoder().decode(SerializedTransaction.self, from: data)
            let transactionBlockBytes = Data(serializedTransaction.transactionBlock)
            return transactionBlockBytes
           } catch {
               print("Error decoding the transaction block: \(error)")
               return nil
        }
    }
  ```

- **Custom Node Server for Wormhole SDK**: Setting up a local Node.js server to interact with the Wormhole SDK and handle cross-chain transactions.
  ```javascript
  app.post('/prepareTransactionBlock', async (req, res) => {
    const { recipientChain, senderAddress, receiverAddress, amountToSend } = req.body;
    const wh = await wormhole("Mainnet", [evm, sui]);
    const ctx = wh.getChain("Sui");  
    ctx.config.rpc = "https://fullnode.mainnet.sui.io:443/";
    const rcv = wh.getChain(recipientChain as Chain);
    const sndTb = await ctx.getTokenBridge();    
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
    const tx = await transfer.next();
    const suiClient = await ctx.getRpc()
    if (tx.done) {
        res.status(500).json({ error: 'No transaction was created' });
    } else {
        tx.value.transaction.setSenderIfNotSet(senderAddress)
        const serializedTransaction = await tx.value.transaction.build({client: suiClient})
        const serializedTransactionArray = Array.from(serializedTransaction);
        res.json({ transactionBlock: serializedTransactionArray });
        }   
    }); 
  ```

- **Cross-Chain Transactions**: Facilitating cross-chain token transfers directly from Swift by communicating with the Node.js server that utilizes the Wormhole SDK.

- **Secure Signature Handling**: Using Secure Enclave for signing transactions, ensuring high security for cross-chain operations.

- **Transaction Preparation and Processing**: Preparing and processing transactions through the Node.js server, then signing and executing them in Swift.
  ```swift
   public func signAndExecuteBridgeTransaction(recipientChain: String, senderAddress: String, receiverAddress: String, amountToSend: String) async throws -> SuiTransactionBlockResponse{
        guard let transactionBlockBytes = try await self.buildBridgeTransaction(recipientChain: recipientChain, senderAddress: senderAddress, receiverAddress: receiverAddress, amountToSend: amountToSend) else {
            throw NSError(domain: "Failed to build bridgeTransaction", code: -1)
        }
        let transactionBlockWithIntent = RawSigner.messageWithIntent(.TransactionData, transactionBlockBytes)
        let blake2bDigest = try Blake2b.hash(size: 32, data: transactionBlockWithIntent)
        
        let signature = try await self.signDataAsync(data: blake2bDigest) // Use SecureEnclaveManager to sign the transaction block
    
        // rest of the code
        return try await self.provider.executeTransactionBlock(transactionBlock: transactionBlockBytes.base64EncodedString(), signature: serializedSignature)
    }
  ```

- **Multichain Support**: Enabling multichain calls and interactions to enhance the application's functionality across different blockchain networks.


### BlockEden
We leverage **BlockEden's Versatile API** to effectively transform our Mobile Phones into **Hardware Wallets**, this can happen because of support for versatile signatue schemes by SUI and BlockEden.

Following are the features of our use! 

**Moreover, everything is in SWIFT 😉**

- **Versatile Use of BlockEdenAPI in Swift**: Using BlockEdenAPI in Swift, despite the lack of an SDK.
  ```swift
  if let blockEdenKey = ProcessInfo.processInfo.environment["blockEdenApiKey"] {
      let blockEdenConnection = BlockEdenConnection(blockEdenKey: blockEdenKey)
      suiProvider = SuiProvider(connection: blockEdenConnection)
  }
  ```

- **Custom Connection Protocol**: Defined a custom connection protocol for BlockEden.
  ```swift
  public struct BlockEdenConnection: ConnectionProtocol {
      public var fullNode: String
      public var faucet: String
      public var graphql: String? = nil

      public init(blockEdenKey: String) {
          self.fullNode = "https://api.blockeden.xyz/sui/devnet/" + blockEdenKey
          self.faucet = "https://api.blockeden.xyz/sui/devnet/" + blockEdenKey
      }
  }
  ```

- **Transaction with SECP256R1 Signatures**: Performing transactions using SECP256R1 signatures instead of the native ED25519.

- **Balance Fetching and Coin Checking**: Fetching balances and checking all coins of an address.

- **Dry Running Transactions**: Performing dry run transactions to ensure correctness before execution.

- **Novel Signature Scheme**: Implementing a novel signature scheme to transform mobile/laptops into hardware wallets.

- **Multichain Support**: Supporting multichain calls to enhance app functionality.

### BlockVision
We leverage BlockVision's powerful blockchain API and data service to transform mobile phones into secure hardware wallets for the Sui blockchain.

- **Seamless BlockVision Integration:** Utilize BlockVision's high-availability indexing network for efficient data retrieval and complex query execution.

- **Swift Integration:** Integrate BlockVision's capabilities directly within your Swift codebase.

 - **Balance and Coin Management:** Effortlessly fetch account balances and retrieve information for all associated coins.

We also integrate the following SuiVision api into our apps:

- Account Page: View account details. (e.g., https://suivision.xyz/account/{accountaddress})
- Transaction Page: Explore transaction details. (e.g., https://suivision.xyz/txblock/{txndigest})
- Coin Page: Access information for specific coins. (e.g., https://suivision.xyz/coin/{cointype})
- NFT Collection Page: Manage and explore NFT collections. (e.g., https://suivision.xyz/nft/collection/{collectiontype})
- NFT Page: View details for individual NFTs. (e.g., https://suivision.xyz/nft/object/{objectid})
- Object Page: Access information for any object on the Sui blockchain. (e.g., https://suivision.xyz/object/{objectid})




## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Sample Methods](#sample-methods)

## Installation

### Prerequisites

- Xcode (latest version)
- Swift 5.0+
- iOS 14.0+

### Steps

1. **Clone the Repository**

    ```bash
    git clone https://github.com/yourusername/biowallet.git
    cd biowallet
    ```

2. **Open in Xcode**

    Open the project in Xcode by double-clicking on `BioWallet.xcodeproj`.

3. **Set Up Your Environment**

    - Connect your iOS device (iPad or iPhone).
    - Ensure your device is trusted and paired with your Mac.
  
4. **Setup env variable**
   - Provide the environment variable of pvt key for prefunding. 

5. **Build and Run**

    Select your connected device from the device list in Xcode and click the Run button.


## Sample Methods
### 1. Initialize the BioWalletSigner
```swift
let suiProvider = SuiProvider(connection: DevnetConnection())
let bioWalletSigner = BioWalletSigner(provider: suiProvider)
```
### 1. Sign a Message

```swift
let dataToSign = "Hello, Secure Enclave!".data(using: .utf8)!
let signature = try await biowalletSigner.signMessage(dataToSign)
```

### 2. Sign and execute a Transaction

```swift
// build a transaction:
var txb = try TransactionBlock()
try txb.setSenderIfNotSet(sender: usersWalletAddress)
let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(amount))])
try txb.transferObject(objects: [coin], address: account.address())
let res = try await bioWalletSigner.signAndExecuteTransactionBlock(&txb)
print("result", res)
```

### 3. Sign a Transaction

```swift
// build a transaction:
var txb = try TransactionBlock()
try txb.setSenderIfNotSet(sender: usersWalletAddress)
let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(amount))])
try txb.transferObject(objects: [coin], address: account.address())
// gives the serialized blockBytes and the serialized signature
// serialized signature contains flag || signature || publicKey 
// total 1 + 64 + 33 = 98 bytes worth of base64 encoded signature
let (serializedBlock, serializedSignature) = try await biowalletSigner.signAndExecuteTransactionBlock(&txb)
```

### 4. Perform a dry run to check txn validation
```swift
// build a transaction:
var txb = try TransactionBlock()
try txb.setSenderIfNotSet(sender: usersWalletAddress)
let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(amount))])
try txb.transferObject(objects: [coin], address: account.address())
let dryRunRes = try await bioWalletSigner.dryRunTransactionBlock(&txb)
print("Dry run result", dryRunRes)
//  check for error by utilizing:  dryRunRes.effects?.status.error, if empty, dry run was succesful
```


---


