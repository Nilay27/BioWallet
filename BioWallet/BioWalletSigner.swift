//
//  BioWalletSigner.swift
//  Bio-Wallet
//
//  Created by Kumar Nilay on 29/05/24.
//

import SuiKit
import Foundation
import Blake2

struct TagToPublicKeyMap {
    let tag: String
    let publicKey: SECP256R1PublicKey
}

class BioWalletSigner {
    private let secureEnclaveManager: SecureEnclaveManager
    public var provider: SuiProvider
    public var faucetProvider: FaucetClient
    public var tag: String = ""
    public var p256PublicKey: SECP256R1PublicKey? = nil

    public init(provider: SuiProvider) {
        self.provider = provider
        self.faucetProvider = FaucetClient(connection: provider.connection)
        self.secureEnclaveManager = SecureEnclaveManager()
    }

    public func getAddress() throws -> String {
        // start signature serialization
        guard let address = try p256PublicKey?.toSuiAddress() else {
            print("Public key is not available")
            throw NSError(domain: "Public key is not available", code: -1)
        }
        return address
    }
    
    public func createWallet() async throws -> TagToPublicKeyMap {
        let uniqueTag = UUID().uuidString
        let (_, _, compressedKey) = try await generateKeyPairAsync(manager: self.secureEnclaveManager, tag: uniqueTag)
        let p256PublicKey = try SECP256R1PublicKey(data: compressedKey)
        self.p256PublicKey = p256PublicKey
        self.tag = uniqueTag
        return TagToPublicKeyMap( tag: uniqueTag, publicKey: p256PublicKey)
    }

    public func signDataAsync(data: Data) async throws -> Data {
        return try await withCheckedThrowingContinuation { continuation in
            self.secureEnclaveManager.signData(data: data, tag: self.tag) { signature, error in
                if let signature = signature {
                    continuation.resume(returning: signature)
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "SecureEnclaveManager", code: -1, userInfo: nil))
                }
            }
        }
    }
    
    public func generateKeyPairAsync(manager: SecureEnclaveManager, tag: String) async throws -> (SecKey, Data, Data) {
        return try await withCheckedThrowingContinuation { continuation in
            manager.generateKeyPair(tag: tag) { publicKey, uncompressedKey, compressedKey, error in
                if let publicKey = publicKey, let uncompressedKey = uncompressedKey, let compressedKey = compressedKey {
                    continuation.resume(returning: (publicKey, uncompressedKey, compressedKey))
                } else {
                    continuation.resume(throwing: error ?? NSError(domain: "SecureEnclaveManager", code: -1, userInfo: nil))
                }
            }
        }
    }

    public func requestSuiFromFaucet(_ address: String) async throws -> FaucetCoinInfo {
        return try await self.faucetProvider.funcAccount(address)
    }

    public func signMessage(_ input: Data) async throws -> String {
        let length = UInt8(input.count)
        var newData = Data([length])
        newData.append(input)
        let messageWithIntent = RawSigner.messageWithIntent(.PersonalMessage, newData)
        let blake2bDigest = try Blake2b.hash(size: 32, data: messageWithIntent)
        // Use SecureEnclaveManager to sign the message
        let signature = try await self.signDataAsync(data: blake2bDigest)
        
        // start signature serialization
        guard let publicKey = p256PublicKey?.key.compressedRepresentation else {
            print("Public key is not available")
            throw NSError(domain: "Public key is not available", code: -1)
        }
        let correctSignature = try self.getCorrectSignatureType(signature: signature, publicKey: publicKey)
        let serializedSignature = try RawSigner.toSerializedSignature(correctSignature, .secp256r1, publicKey.base64EncodedString())
        return serializedSignature
    }

    public func prepareTransactionBlock(_ transactionBlock: inout TransactionBlock) async throws -> Data {
        try transactionBlock.setSenderIfNotSet(sender: try self.getAddress())
        return try await transactionBlock.build(self.provider)
    }

    public func signTransactionBlock(transactionBlock: inout TransactionBlock) async throws -> (String, String) {
        // build transaction block with intent and take hash
        let transactionBlockBytes = try await self.prepareTransactionBlock(&transactionBlock)
        let transactionBlockWithIntent = RawSigner.messageWithIntent(.TransactionData, transactionBlockBytes)
        let blake2bDigest = try Blake2b.hash(size: 32, data: transactionBlockWithIntent)
        
        // Use SecureEnclaveManager to sign the transaction block
        let signature = try await self.signDataAsync(data: blake2bDigest)
        
        // start signature serialization
        guard let publicKey = p256PublicKey?.key.compressedRepresentation else {
            print("Public key is not available")
            throw NSError(domain: "Public key is not available", code: -1)
        }
        let correctSignature = try self.getCorrectSignatureType(signature: signature, publicKey: publicKey)
        let serializedSignature = try RawSigner.toSerializedSignature(correctSignature, .secp256r1, publicKey.base64EncodedString())
        
        return (
            transactionBlockBytes: transactionBlockBytes.base64EncodedString(),
            signature: serializedSignature
        )
        
    }
    

    public func signAndExecuteTransactionBlock(
        _ transactionBlock: inout TransactionBlock,
        _ options: SuiTransactionBlockResponseOptions? = nil,
        _ requestType: SuiRequestType? = nil
    ) async throws -> SuiTransactionBlockResponse {
        let (serializedBlock, serializedSignature) = try await self.signTransactionBlock(transactionBlock: &transactionBlock)
        return try await self.provider.executeTransactionBlock(transactionBlock: serializedBlock, signature: serializedSignature)
    }

    public func getTransactionBlockDigest(_ tx: inout TransactionBlock) async throws -> String {
        return try await tx.getDigest(self.provider)
    }

    public func dryRunTransactionBlock(_ transactionBlock: inout TransactionBlock) async throws -> SuiTransactionBlockResponse {
        try transactionBlock.setSenderIfNotSet(sender: try self.getAddress())
        let dryRunTxBytes = try await transactionBlock.build(self.provider)
        return try await self.provider.dryRunTransactionBlock(transactionBlock: [UInt8](dryRunTxBytes))
    }

    public func dryRunTransactionBlock(_ transactionBlock: String) async throws -> SuiTransactionBlockResponse {
        guard let dryRunTxBytes = Data.fromBase64(transactionBlock) else { throw SuiError.failedData }
        return try await self.provider.dryRunTransactionBlock(transactionBlock: [UInt8](dryRunTxBytes))
    }

    public func dryRunTransactionBlock(_ transactionBlock: Data) async throws -> SuiTransactionBlockResponse {
        return try await self.provider.dryRunTransactionBlock(transactionBlock: [UInt8](transactionBlock))
    }
    
    public func getCorrectSignatureType(signature: Data, publicKey: Data) throws -> Signature{
        let correctTypeSignature = Signature(
            signature: signature,
            publickey: publicKey,
            signatureScheme: .SECP256R1
        )
        return correctTypeSignature
        
    }
    
    public func setNewPublicKey(tagToPubKey: TagToPublicKeyMap) {
        self.tag = tagToPubKey.tag
        self.p256PublicKey = tagToPubKey.publicKey
        print("set current Public Key")
    }
}

