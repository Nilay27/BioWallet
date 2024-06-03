import SwiftUI
import SuiKit

enum TransactionStatus {
    case none
    case success
    case failure
}

struct WalletView: View {
    @Binding var isSignedIn: Bool
    @Binding var username: String
    @State private var walletAddress: String = ""
    @State private var amount: String = ""
    @State private var balance: String = "0.00 SUI"
    @State private var usersWalletAddress: String = ""{
        didSet {
            if !usersWalletAddress.isEmpty {
                Task {
                    await prefundCreatedAccount()
                }
            }
        }
    }
    @State private var isWalletConnected: Bool = false
    @State private var keyTag: String = ""
    @State private var p256PublicKey: SECP256R1PublicKey? = nil
    @State private var suiFundingAccount: Account? = nil
    @State private var suiProvider: SuiProvider = SuiProvider(connection: DevnetConnection())
    @State private var isLoading: Bool = false
    @State private var transactionResult: String = ""
    @State private var transactionStatus: TransactionStatus = .none
    @State private var showAlert: Bool = false
    var bioWalletSigner: BioWalletSigner
    
    var body: some View {
            GeometryReader { geometry in
                VStack(spacing: 20) {
                    HeaderView(username: username, address: usersWalletAddress, balance: balance, onRefresh: {
                        Task {
                            try await fetchBalance()
                        }
                    })
                    if isLoading {
                        ProgressView("Prefunding Account...")
                            .foregroundColor(.white)
                            .padding()
                    }
                    TextField("SUI Wallet Address", text: $walletAddress)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding([.leading, .trailing])
                    
                    TextField("Amount (max limit:\(balance))", text: $amount)
                        .padding()
                        .background(Color.black)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .textFieldStyle(PlainTextFieldStyle())
                        .padding([.leading, .trailing])
                    
                    Button(action: {
                        Task {
                            await signBioWalletTxn()
                        }
                    }) {
                        Text("Sign Transactions")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding([.leading, .trailing])
                    }
                    .disabled(keyTag.isEmpty)
                    
                    Button(action: {
                        isSignedIn = false
                    }) {
                        Text("Sign Out")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding([.leading, .trailing])
                    }
                    
                    if transactionStatus == .success {
                        VStack {
                            Text("Transaction Successful:")
                            Link("Show in explorer", destination: URL(string: transactionResult)!)
                                .font(.title3)
                        }
                        .padding()
                        .transition(.slide)
                    }
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .background(Color.black.opacity(0.8))
                .onAppear {
                    Task {
                        await initFundingAccount()
                        fetchPublicKeyFromUserDefaults()
                    }
                }
                .overlay(
                    Group {
                        if showAlert {
                            VStack {
                                Image(systemName: transactionStatus == .success ? "checkmark.circle" : "xmark.circle")
                                    .resizable()
                                    .frame(width: 50, height: 50)
                                    .foregroundColor(transactionStatus == .success ? .green : .red)
                                Text(transactionStatus == .success ? "Transaction Successful" : "Transaction Failed")
                                    .font(.largeTitle)
                                    .padding()
                                    .foregroundColor(.black)
                                if transactionStatus == .failure {
                                    Text(transactionResult)
                                        .padding()
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(Color.red)
                                }
                                Button(action: {
                                    showAlert = false
                                }) {
                                    Text("OK")
                                        .font(.title2)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(10)
                                }
                            }
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                            .shadow(radius: 10)
                            .transition(.opacity)
                        }
                    }
                )
            }
        }


    func fetchPublicKeyFromUserDefaults() {
        if let storedUserMap = UserDefaults.standard.dictionary(forKey: "userMap") as? [String: [String: String]],
           let userInfo = storedUserMap[username],
           var publicKeyHex = userInfo["publicKey"],
            let tag = userInfo["tag"] {
            if let p256PublicKey = try? SECP256R1PublicKey(value: publicKeyHex) {
                DispatchQueue.main.async {
                    self.p256PublicKey = p256PublicKey
                    self.keyTag = tag
                    print("keyTag", tag)
                    guard let usersWalletAddress = try? p256PublicKey.toSuiAddress() else {
                        return
                    }
                    self.usersWalletAddress = usersWalletAddress
                    print("Set usersWalletAddress in state: \(usersWalletAddress)")
                    bioWalletSigner.setNewPublicKey(tagToPubKey: TagToPublicKeyMap(tag: tag, publicKey: p256PublicKey))
                }
            } else {
            }
        } else {
        }
    }
    
    func fetchBalance() async throws -> String {
        let object = try await suiProvider.getCoins(account: usersWalletAddress, coinType: "0x2::sui::SUI")
        print("Fetched object:", object)
        // Check if the data array is empty
        guard !object.data.isEmpty else {
            print("No coins found for the account")
            balance = "0.00 SUI"
            return balance
        }
        
        if let microSuiBalanceString = object.data[0].balance as? String,
           let microSuiBalance = Double(microSuiBalanceString) {
            let suiBalance = microSuiBalance / 1_000_000_000.0
            let formattedBalance = String(format: "%.3f", suiBalance)
            balance = "\(formattedBalance) SUI"
            return balance
        } else {
            balance = "0.000 SUI"
            return balance
        }
    }
    
    private func signBioWalletTxn() async {
           print("KeyTag", keyTag)
           guard !keyTag.isEmpty else {
               print("keyTag is empty")
               return
           }

           do {
               guard let account = suiFundingAccount else {
                   throw NSError(domain: "Funding AccountError", code: -1)
               }
               
               var txb = try TransactionBlock()
               guard let sendingAmount = Double(self.amount) else {
                   print("Error in amount", self.amount)
                   return
               }
               
               let scaledAmount = sendingAmount * 1e9
               let sendingAmountInMist = UInt64(scaledAmount)
               let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(sendingAmountInMist))])
               try txb.transferObject(objects: [coin], address: account.address())
               try txb.setSenderIfNotSet(sender: usersWalletAddress)
               let dryRunRes = try await bioWalletSigner.dryRunTransactionBlock(&txb)
               
               if let error = dryRunRes.effects?.status.error {
                   print("dryRunRes Error:", error)
                   DispatchQueue.main.async {
                       self.transactionStatus = .failure
                       self.transactionResult = error // Directly using the error string
                       self.showAlert = true
                   }
               } else {
                   print("dryRunRes Success")
                   let res = try await bioWalletSigner.signAndExecuteTransactionBlock(&txb)
                   print(res)
                   DispatchQueue.main.async {
                       self.transactionStatus = .success
                       self.transactionResult = "https://suiscan.xyz/devnet/tx/\(res.digest)" // Set this to your actual transaction result link
                       self.showAlert = true
                   }
               }
//               var result = try await bioWalletSigner.signAndExecuteBridgeTransaction(
//                recipientChain: "Sui",
//                senderAddress: "0xb40f32bd1068afa2e47de0512d3d57d1233ca1670b1154afc3fc3b102515a8c0",
//                receiverAddress: "0xb40f32bd1068afa2e47de0512d3d57d1233ca1670b1154afc3fc3b102515a8c0",
//                amountToSend: "0.1"
//            )
//               print("result", result)
           } catch {
               print("Failed to sign data: \(error)")
               DispatchQueue.main.async {
                   self.transactionStatus = .failure
                   self.transactionResult = error.localizedDescription
                   self.showAlert = true
               }
           }
       }

    
    func initFundingAccount() async {
        do {
            let suiPrivateKey: String

            // Assign the value inside the if let block
            if let privateKeyFromEnv = ProcessInfo.processInfo.environment["suiPrivateKey"] {
                suiPrivateKey = privateKeyFromEnv
            } else {
                throw NSError(domain: "EnvironmentVariableError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Private Key not found in environment variables."])
            }

            // Use the variable after ensuring it has a value
            let privateKey = try ED25519PrivateKey(value: suiPrivateKey)
            suiFundingAccount = try Account(privateKey: privateKey, accountType: .ed25519)
            print("suiFundingAccount address", try suiFundingAccount?.address())
        } catch {
            print("Error: \(error)")
        }
    }
    
    func prefundCreatedAccount() async {
        do {
            print("entered prefunding acocunt")
            let currentBalance = try await fetchBalance()
            print("currentBalance", currentBalance)
            if currentBalance != "0.00 SUI" {
                print("Account already funded with balance: \(currentBalance)")
                return
            }
            
            DispatchQueue.main.async {
                isLoading = true
            }

            var myAddress: String
            if let address = try suiFundingAccount?.address() {
                myAddress = address
            } else {
                throw NSError(domain: "Funding AccountError", code: -1)
            }

            let object = try await suiProvider.getCoins(account: myAddress, coinType: "0x2::sui::SUI")
            print("object", object.data[0].balance)

            var txb = try TransactionBlock()
            try txb.setSender(sender: myAddress)
            let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(100_000_000))])
            try txb.transferObject(objects: [coin], address: usersWalletAddress)

            guard let account = suiFundingAccount else {
                throw NSError(domain: "Funding AccountError", code: -1)
            }
            let signer = RawSigner(account: account, provider: suiProvider)
            let signedBlock = try await signer.signTransactionBlock(transactionBlock: &txb)
            print("signedBlock bytes", signedBlock.transactionBlockBytes)
            print("serializedSignature", signedBlock.signature)
            let res = try await suiProvider.executeTransactionBlock(transactionBlock: signedBlock.transactionBlockBytes, signature: signedBlock.signature)
            print("account Prefunded", res)
            
            DispatchQueue.main.async {
                isLoading = false
            }
            try await fetchBalance()
        } catch {
            print("Error: \(error)")
            DispatchQueue.main.async {
                isLoading = false
            }
        }
    }
}

struct WalletView_Previews: PreviewProvider {
    @State static var isSignedIn = true
    @State static var username = "qwerty"
    static var previews: some View {
        let suiProvider = SuiProvider(connection: DevnetConnection())
        let bioWalletSigner = BioWalletSigner(provider: suiProvider)
        WalletView(isSignedIn: $isSignedIn, username: $username, bioWalletSigner: bioWalletSigner)
    }
}
