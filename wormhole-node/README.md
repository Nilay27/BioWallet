# Wormhole Node

This repository contains the `wormhole-node`, a local Node.js server that facilitates cross-chain transactions by interfacing with the Wormhole SDK. It is designed to work in conjunction with the BioWallet Swift SDK, enabling secure and efficient cross-chain token transfers.

## Table of Contents
- [Wormhole Node](#wormhole-node)
  - [Table of Contents](#table-of-contents)
  - [Installation](#installation)
  - [Usage](#usage)
  - [API Endpoints](#api-endpoints)
    - [Prepare Transaction](#prepare-transaction)
    - [Process Transaction](#process-transaction)
  - [Example cURL Requests](#example-curl-requests)
    - [Prepare Transaction](#prepare-transaction-1)
  - [Integration with BioWallet](#integration-with-biowallet)
    - [Swift SDK Functions](#swift-sdk-functions)
      - [`signAndExecuteBridgeTransaction`](#signandexecutebridgetransaction)
    - [`buildBridgeTransaction`](#buildbridgetransaction)
    - [Usage in Swift](#usage-in-swift)

## Installation

To set up the `wormhole-node`, follow these steps:

1. Install the necessary dependencies:
    ```sh
    npm install
    ```

2. Start the server:
    ```sh
    tsc && node dist/index.js    
    ```

The server will run on `http://localhost:3000`.

## Usage

The `wormhole-node` server expects JSON input for preparing and processing cross-chain transactions. The server interacts with the Wormhole SDK to create transaction details that are then signed and executed by the BioWallet Swift SDK.

## API Endpoints

### Prepare Transaction

**Endpoint**: `POST /prepareTransactionBlock`

**Description**: Prepares transaction details for cross-chain token transfer.

**Request Body**:
```json
{
  "senderAddress": "string",
  "recipientAddress": "string",
  "chainOfRecipient": "string",
  "amount": "string"
}
```

**Response**: Returns the prepared transaction details to be signed.

### Process Transaction

**Endpoint**: `POST /processSignedTransaction`

**Description**: Processes the signed transaction and completes the transfer.

**Request Body**:
```json
{
  "chain": "string",
  "txid": "string"
}
```

**Response**: Confirms the transaction processing.

## Example cURL Requests

### Prepare Transaction

```sh
curl -X POST http://localhost:3000/prepareTransactionBlock \
  -H "Content-Type: application/json" \
  -d '{
        "senderAddress": "0xSenderAddress",
        "recipientAddress": "0xRecipientAddress",
        "chainOfRecipient": "Sui",
        "amount": "1000"
      }'
```


## Integration with BioWallet

In the BioWallet Swift SDK, the `bridgeToken` function is designed to interact with the `wormhole-node` server. Here’s a brief overview of how the integration works:

### Swift SDK Functions

#### `signAndExecuteBridgeTransaction`

This function in the BioWallet Swift SDK initiates the process of preparing, signing, and executing a cross-chain transaction. 

```swift
public func signAndExecuteBridgeTransaction(recipientChain: String, senderAddress: String, receiverAddress: String, amountToSend: String) async throws -> SuiTransactionBlockResponse {
    guard let transactionBlockBytes = try await self.buildBridgeTransaction(recipientChain: recipientChain, senderAddress: senderAddress, receiverAddress: receiverAddress, amountToSend: amountToSend) else {
        throw NSError(domain: "Failed to build bridgeTransaction", code: -1)
    }
    let transactionBlockWithIntent = RawSigner.messageWithIntent(.TransactionData, transactionBlockBytes)
    let blake2bDigest = try Blake2b.hash(size: 32, data: transactionBlockWithIntent)
    
    // Use SecureEnclaveManager to sign the transaction block
    let signature = try await self.signDataAsync(data: blake2bDigest)

    // Start signature serialization
    guard let publicKey = p256PublicKey?.key.compressedRepresentation else {
        throw NSError(domain: "Public key is not available", code: -1)
    }
    let correctSignature = try self.getCorrectSignatureType(signature: signature, publicKey: publicKey)
    let serializedSignature = try RawSigner.toSerializedSignature(correctSignature, .secp256r1, publicKey.base64EncodedString())
    
    return try await self.provider.executeTransactionBlock(transactionBlock: transactionBlockBytes.base64EncodedString(), signature: serializedSignature)
}
```

### `buildBridgeTransaction`

This function calls the `wormhole-node` server to get the transaction data which is then signed and executed.

```swift
func buildBridgeTransaction(recipientChain: String, senderAddress: String, receiverAddress: String, amountToSend: String) async throws -> Data? {
        let urlString = "http://localhost:3000/prepareTransactionBlock"
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return nil
        }

        let payload: [String: Any] = [
            "recipientChain": recipientChain,
            "senderAddress": senderAddress,
            "receiverAddress": receiverAddress,
            "amountToSend": amountToSend
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            print("Error: cannot create JSON from payload")
            return nil
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        print("data", data)

        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            print("Error: Invalid HTTP response")
            return nil
        }
        
           // Decode the JSON data into SerializedTransaction
        do {
               let serializedTransaction = try JSONDecoder().decode(SerializedTransaction.self, from: data)
               print("Received serialized transaction block")

               // Convert the array of UInt8 to Data
               let transactionBlockBytes = Data(serializedTransaction.transactionBlock)
            
              
               return transactionBlockBytes
           } catch {
               print("Error decoding the transaction block: \(error)")
               return nil
           }
    }
```

### Usage in Swift

```swift
var result = try await bioWalletSigner.signAndExecuteBridgeTransaction(
    recipientChain: recipientChain,
    senderAddress: senderAddress,
    receiverAddress: receiverAddress,
    amountToSend: amountToSend
)
print("result", result)
```