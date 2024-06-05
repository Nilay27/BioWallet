//
//  BioWalletViewModel.swift
//  BioWallet
//
//  Created by Kumar Nilay on 05/06/24.
//

import Foundation
import SwiftUI
import SuiKit

class BioWalletViewModel: ObservableObject {
    @Published var username: String = ""
    @Published var isSignedIn: Bool = false
    @Published var usersWalletAddress: String?
    @Published var balance: String = "0.00 SUI"
    @Published var isLoading: Bool = false
    
    let bioWalletSigner: BioWalletSigner
    let suiProvider: SuiProvider
    var suiFundingAccount: Account?

    init() {
        self.suiProvider = SuiProvider(connection: DevnetConnection())
        self.bioWalletSigner = BioWalletSigner(provider: suiProvider)
        Task {
            await initFundingAccount()
        }
    }
    
    func signIn(username: String) {
        self.username = username
        self.isSignedIn = true
        Task {
            await fetchPublicKeyFromUserDefaults()
        }
    }
    
    func signOut() {
        self.username = ""
        self.isSignedIn = false
        self.usersWalletAddress = nil
        self.balance = "0.00 SUI"
    }
    
    func fetchPublicKeyFromUserDefaults() async {
        if let storedUserMap = UserDefaults.standard.dictionary(forKey: "userMap") as? [String: [String: String]],
           let userInfo = storedUserMap[username],
           let publicKeyHex = userInfo["publicKey"],
           let tag = userInfo["tag"] {
            if let p256PublicKey = try? SECP256R1PublicKey(value: publicKeyHex) {
                guard let usersWalletAddress = try? p256PublicKey.toSuiAddress() else {
                    return
                }
                self.usersWalletAddress = usersWalletAddress
                self.bioWalletSigner.setNewPublicKey(tagToPubKey: TagToPublicKeyMap(tag: tag, publicKey: p256PublicKey))
                await fetchBalance()
                await prefundCreatedAccount()
            }
        }
    }

    func fetchBalance() async {
        guard let usersWalletAddress = usersWalletAddress else {
            self.balance = "0.00 SUI"
            return
        }
        do {
            let object = try await suiProvider.getCoins(account: usersWalletAddress, coinType: "0x2::sui::SUI")
            guard !object.data.isEmpty else {
                self.balance = "0.00 SUI"
                return
            }
            
            if let microSuiBalanceString = object.data[0].balance as? String,
               let microSuiBalance = Double(microSuiBalanceString) {
                let suiBalance = microSuiBalance / 1_000_000_000.0
                let formattedBalance = String(format: "%.3f", suiBalance)
                self.balance = "\(formattedBalance) SUI"
            } else {
                self.balance = "0.000 SUI"
            }
        } catch {
            print("Failed to fetch balance: \(error.localizedDescription)")
            self.balance = "0.00 SUI"
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
            print("entered prefunding account")
            await fetchBalance()
            let currentBalance = self.balance
            print("currentBalance", currentBalance)
            print("providerConnection", suiProvider.connection)
            if currentBalance != "0.00 SUI" {
                print("Account already funded with balance: \(currentBalance)")
                return
            }
            
            DispatchQueue.main.async {
                self.isLoading = true
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
            guard let usersWalletAddress = usersWalletAddress else{
                print("wallet address not yet set")
                return
            }
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
                self.isLoading = false
            }
            await fetchBalance()
        } catch {
            print("Error: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}

