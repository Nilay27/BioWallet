//import SwiftUI
//import LocalAuthentication
//import SuiKit
//import Blake2
//
//struct ContentView: View {
//    @State private var walletAddress: String = ""
//    @State private var amount: String = ""
//    @State private var isWalletConnected: Bool = false
//    @State private var keyTag: String = ""
//    @State private var p256PublicKey: SECP256R1PublicKey? = nil;
//    @State private var suiFundingAccount: Account? = nil;
//    @State private var suiProvider: SuiProvider = SuiProvider(connection: DevnetConnection());
//    @State private var bioWalletSigner: BioWalletSigner?
//    var body: some View {
//        VStack(spacing: 20) {
//            TextField("SUI Wallet Address", text: $walletAddress)
//                .padding()
//                .background(Color.black)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//                .textFieldStyle(PlainTextFieldStyle())
//            
//            TextField("Amount (max limit:1)", text: $amount)
//                .padding()
//                .background(Color.black)
//                .foregroundColor(.white)
//                .cornerRadius(10)
//                .textFieldStyle(PlainTextFieldStyle())
//            
//            Button(action: {
//                Task {
////                    await signTransaction()
////                    await signPersonalMessage()
////                    await signTransaction1()
//                    await signBioWalletTxn()
//                }
//            }) {
//                Text("Sign Transactions")
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.gray)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//            .disabled(keyTag.isEmpty)
//            
//            Button(action: {
//                Task {
//                    await createWallet()
//                }
//            }) {
//                Text("Connect Wallet")
//                    .padding()
//                    .frame(maxWidth: .infinity)
//                    .background(Color.purple)
//                    .foregroundColor(.white)
//                    .cornerRadius(10)
//            }
//        }
//        .padding()
//        .background(Color.black.opacity(0.8))
//        .cornerRadius(15)
//        .padding()
//        .onAppear{
//            Task{
//                bioWalletSigner = BioWalletSigner(provider: suiProvider)
//                await initFundingAccount()
//            }
//        }
//    }
//    
//    func prefundCreatedAccount() async{
//        var myAddress: String
//        do{
//            if let address = try suiFundingAccount?.address(){
//                myAddress = address
//                
//            } else {
//                throw NSError(domain: "Funding AccountError", code: -1)
//            }
//            let object = try await suiProvider.getCoins(account: myAddress,
//                        coinType:"0x2::sui::SUI")
//                        print("object", object.data[0].balance)
//            // start building transaction
//            var txb = try TransactionBlock()
//            try txb.setSender(sender: myAddress)
//            let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(10_000_000))])
//            try txb.transferObject(objects: [coin], address: walletAddress)
//            
//            // create a signer and sign transactionblock
//            guard let account = suiFundingAccount else{
//                throw NSError(domain: "Funding AccountError", code: -1)
//            }
//            let signer = RawSigner(account: account, provider: suiProvider)
//            let signedBlock = try await signer.signTransactionBlock(transactionBlock: &txb)
//            print("signedBlock bytes", signedBlock.transactionBlockBytes)
//            print("serializedSignature", signedBlock.signature)
//            let res = try await suiProvider.executeTransactionBlock(transactionBlock: signedBlock.transactionBlockBytes, signature: signedBlock.signature)
//            print("account Prefunded", res)
//        } catch{
//            print("Error: \(error)")
//        }
//        
//    }
//    
//    func signBioWalletTxn() async{
//        guard !keyTag.isEmpty else { return }
//        
//        do{
//            guard let account = suiFundingAccount else{
//                throw NSError(domain: "Funding AccountError", code: -1)
//            }
//            var txb = try TransactionBlock()
//            let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(100))])
//            try txb.transferObject(objects: [coin], address: account.address())
//            try txb.setSenderIfNotSet(sender: walletAddress)
//            let res = try await bioWalletSigner?.signAndExecuteTransactionBlock(&txb)
//            print(res)
//        }catch{
//            print("Failed to sign data: \(error)")
//        }
//    }
//    
//    func signTransaction() async {
//            guard !keyTag.isEmpty else { return }
//            let manager = SecureEnclaveManager()
////            
////            let dataToSign = "Hello, Secure Enclave!".data(using: .utf8)!
////            print("dataToSign", dataToSign)
////            let length = UInt8(dataToSign.count)
////            var newData = Data([length])
////            newData.append(dataToSign)
////            print("data after serialization", newData)
////            let messageWithIntent = RawSigner.messageWithIntent(.PersonalMessage, newData)
////            print("messageWithIntent", [UInt8](messageWithIntent))
////            
//            do {
//                // create a signer and sign transactionblock
//                guard let account = suiFundingAccount else{
//                    throw NSError(domain: "Funding AccountError", code: -1)
//                }
//                print("walletAddress", walletAddress)
////                
//                var txb = try TransactionBlock()
//                
//                let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(100))])
//                try txb.transferObject(objects: [coin], address: account.address())
//                try txb.setSenderIfNotSet(sender: walletAddress)
//                
//                let transactionBlockBytes = try await txb.build(suiProvider)
//                let transactionBlockWithIntent = await RawSigner.messageWithIntent(.TransactionData, transactionBlockBytes)
////                
////                
//                let blake2bDigest = try Blake2b.hash(size: 32, data: transactionBlockWithIntent)
//                let signature: Data = try await signDataAsync(manager: manager, data: blake2bDigest, tag: keyTag)
//                print("Data signed successfully: \([UInt8](signature))")
//                print("length of signature", signature.count)
//                // convert signature to type Signature
////                p256PublicKey.
//                guard let publicKey = p256PublicKey?.key.compressedRepresentation else {
//                            print("Public key is not available")
//                            return
//                        }
//                let correctTypeSignature = Signature(
//                    signature: signature,
//                    publickey: publicKey,
//                    signatureScheme: .SECP256R1
//                )
//                print("public key in signTransaction", publicKey.base64EncodedString())
//////                let correctTypeSignature = Signature()
////                // Use the signature as needed
//                let verificationResult = try p256PublicKey?.verifyTransactionBlock([UInt8](transactionBlockBytes), correctTypeSignature)
//                print("local verificationResult", verificationResult)
//                
//                print("sending transaction to blockchain")
//                print("serializing signature from enclave with pubKey and tx data")
//                let serializedSignature = try RawSigner.toSerializedSignature(correctTypeSignature, .secp256r1, publicKey.base64EncodedString())
//                print("serialized signature", serializedSignature)
//                print("executing transaction")
//                let res = try await suiProvider.executeTransactionBlock(transactionBlock: transactionBlockBytes.base64EncodedString(), signature: serializedSignature)
//                print("result of transaction from secure enclave", res)
//            } catch {
//                print("Failed to sign data: \(error)")
//            }
//        
//        }
//    
//    func createWallet() async {
//        do {
//            let tagToPubKeyMap = try await bioWalletSigner?.createWallet()
//            guard let address = try tagToPubKeyMap?.publicKey.toSuiAddress() else {
//                print("Public key is not available")
//                throw NSError(domain: "Public key is not available", code: -1)
//            }
//            guard let tag = tagToPubKeyMap?.tag else {
//                print("Public key is not available")
//                throw NSError(domain: "Public key is not available", code: -1)
//            }
//            keyTag = tag
//            walletAddress = address
//            print("wallet address", address)
//            await prefundCreatedAccount()
//        }catch{
//            print("Failed to generate key pair: \(error)")
//        }
////        let manager = SecureEnclaveManager()
////        let uniqueTag = UUID().uuidString
////        keyTag = uniqueTag
////        
////        do {
////            let (publicKey, uncompressedKey, compressedKey) = try await generateKeyPairAsync(manager: manager, tag: uniqueTag)
////            print("Key pair generated successfully for tag: \(uniqueTag). Public key: \(publicKey)")
////            print("Uncompressed Public Key (64 bytes): \(uncompressedKey.hexEncodedString())")
////            print("Compressed Public Key (33 bytes): \(compressedKey.hexEncodedString())")
////            
////            let p256PublicKey = try SECP256R1PublicKey(data: compressedKey)
////            self.p256PublicKey = p256PublicKey
////            // Use p256PublicKey as needed
////            print(try p256PublicKey.toSuiAddress())
////            print((p256PublicKey.key.compressedRepresentation))
////            walletAddress = try p256PublicKey.toSuiAddress()
////            await prefundCreatedAccount()
////        } catch {
////            print("Failed to generate key pair: \(error)")
////        }
//    }
//    
//    func generateKeyPairAsync(manager: SecureEnclaveManager, tag: String) async throws -> (SecKey, Data, Data) {
//        return try await withCheckedThrowingContinuation { continuation in
//            manager.generateKeyPair(tag: tag) { publicKey, uncompressedKey, compressedKey, error in
//                if let publicKey = publicKey, let uncompressedKey = uncompressedKey, let compressedKey = compressedKey {
//                    continuation.resume(returning: (publicKey, uncompressedKey, compressedKey))
//                } else {
//                    continuation.resume(throwing: error ?? NSError(domain: "SecureEnclaveManager", code: -1, userInfo: nil))
//                }
//            }
//        }
//    }
//    
//    func signDataAsync(manager: SecureEnclaveManager, data: Data, tag: String) async throws -> Data {
//            return try await withCheckedThrowingContinuation { continuation in
//                manager.signData(data: data, tag: tag) { signature, error in
//                    if let signature = signature {
//                        continuation.resume(returning: signature)
//                    } else {
//                        continuation.resume(throwing: error ?? NSError(domain: "SecureEnclaveManager", code: -1, userInfo: nil))
//                    }
//                }
//            }
//        }
//    
//    func initFundingAccount() async {
//        // Declare the variable outside the if let block
//        do {
//            let suiPrivateKey: String
//
//            
//            // Assign the value inside the if let block
//            if let privateKeyFromEnv = ProcessInfo.processInfo.environment["suiPrivateKey"] {
//                suiPrivateKey = privateKeyFromEnv
//            } else {
//                throw NSError(domain: "EnvironmentVariableError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Private Key not found in environment variables."])
//            }
//            
//            // Use the variable after ensuring it has a value
//            let privateKey = try ED25519PrivateKey(value: suiPrivateKey)
//            suiFundingAccount = try Account(privateKey: privateKey, accountType: .ed25519)
//            print("suiFundingAccount address",try  suiFundingAccount?.address())
//        } catch {
//            print("Error: \(error)")
//        }
//    }
//    
//    
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//    
//    
////    func signTransaction1() async{
////        do {
////            // Create new wallet
////           
////            print("address", try suiFundingAccount.publicKey.toSuiAddress())
////            let secureEnclaveAddress = "0xa89dc0ed0ab6389acdb8aeebebd0d50acd6b34ad0cae75f9d1a292aae781bf68"
////            // Create Signer and Provider
////            let provider = SuiProvider(connection: DevnetConnection())
////            let signer = RawSigner(account: myAccount, provider: provider)
////
////            let object = try await provider.getCoins(account: myAddress,
////            coinType:"0x2::sui::SUI")
////            print("object", object.data[0].balance)
////
////            // start building transaction
////            var txb = try TransactionBlock()
////            try txb.setSender(sender: myAddress)
////            let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(10000))])
////            try txb.transferObject(objects: [coin], address: secureEnclaveAddress)
////
////            let signedBlock = try await signer.signTransactionBlock(transactionBlock: &txb)
////
////            let res = try await provider.executeTransactionBlock(transactionBlock: signedBlock.transactionBlockBytes, signature: signedBlock.signature)
////            print("signature obtained from signedBlock", signedBlock.signature)
////            print("result of transaction", res)
////            print("length of signature", Data(base64Encoded: signedBlock.signature) ?? [])
////
////        } catch {
////            print("Error: \(error)")
////        }
////    }
////
////func signPersonalMessage() async{
////    do{
////        let newWallet = try Wallet()
////        let provider = SuiProvider(connection: DevnetConnection())
////        let signer = RawSigner(account: newWallet.accounts[0], provider: provider)
////        print("publicKey", signer.account.publicKey)
////        let dataToSign = "hello world".data(using: .utf8)!
////        print("data to sign", dataToSign)
////        let dataWithIntent = RawSigner.messageWithIntent(.PersonalMessage, dataToSign)
////        print("dataWithIntent", dataWithIntent)
////        let signature = try signer.account.signPersonalMessage([UInt8](dataToSign))
////        print("signature obtained", try signature.data())
//////        print("data that was signed", Data(base64Encoded: signature.messageBytes)?.bytes ?? [])
////        print( try signer.account.publicKey.verifyPersonalMessage([UInt8](dataToSign), signature))
////        
////    }catch {
////        print("Error: \(error)")
////    }
////}

import SuiKit


import SwiftUI

struct ContentView: View {
    @State private var isSignedIn: Bool = false
    @State private var username: String = ""
    @State private var suiProvider: SuiProvider = SuiProvider(connection: DevnetConnection())
    @State private var bioWalletSigner: BioWalletSigner? = nil

    var body: some View {
        VStack {
            if let bioWalletSigner = bioWalletSigner {
                if isSignedIn {
                    WalletView(isSignedIn: $isSignedIn,  username: $username, bioWalletSigner: bioWalletSigner)
                        .transition(.move(edge: .bottom))
                } else {
                    SignInView(isSignedIn: $isSignedIn, username: $username, bioWalletSigner: bioWalletSigner)
                        .transition(.move(edge: .bottom))
                }
            } else {
                Text("Loading...")
                    .onAppear {
                        bioWalletSigner = BioWalletSigner(provider: suiProvider)
                    }
            }
        }
        .animation(.easeInOut, value: isSignedIn)
    }
}

