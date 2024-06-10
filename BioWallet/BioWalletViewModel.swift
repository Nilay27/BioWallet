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
    @Published var isLoading: Bool = false
    @Published var selectedCoin: Coin = Coin(id: "0x2::sui::SUI", name: "Sui", balance: "0 SUI", logo: "suiLogo", decimal: 9)
    @Published var coins: [Coin] = [
        Coin(id: "0x2::sui::SUI", name: "SUI", balance: "0 SUI", logo: "suiLogo", decimal: 9),
        Coin(id: "0x244b03664411b3f6ac7b8d770ded1002024558658178cc4179e42c527e728849::fud::FUD", name: "FUD", balance: "0 FUD", logo: "fudLogo", decimal: 5)
    ]

    let bioWalletSigner: BioWalletSigner
    let suiProvider: SuiProvider
    var suiFundingAccount: Account?

    init() {
        self.suiProvider = SuiProvider(connection: TestnetConnection())
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
                DispatchQueue.main.async {
                    self.usersWalletAddress = usersWalletAddress
                    Task{
                        await self.fetchBalance(coinType: "0x2::sui::SUI")
                    }
                    self.bioWalletSigner.setNewPublicKey(tagToPubKey: TagToPublicKeyMap(tag: tag, publicKey: p256PublicKey))
                    Task{
                        await self.prefundCreatedAccount()
                    }
                }
                
            }
        }
    }

    func fetchBalance(coinType: String) async {
        guard let coinIndex = self.coins.firstIndex(where: { $0.id == coinType }),
              let usersWalletAddress = usersWalletAddress else {
            DispatchQueue.main.async {
                if let coinIndex = self.coins.firstIndex(where: { $0.id == coinType }) {
                    self.coins[coinIndex].balance = "0.00 \(self.coins[coinIndex].name)"
                }
            }
            return
        }
        do {
            let object = try await suiProvider.getCoins(account: usersWalletAddress, coinType: coinType)
            print("object in fetchBalance", object.data.count)
            guard !object.data.isEmpty else {
                DispatchQueue.main.async {
                    self.coins[coinIndex].balance = "0.00 \(self.coins[coinIndex].name)"
                }
                return
            }
            
            var totalBalance: Double = 0
            for coin in object.data {
                if let microBalanceString = coin.balance as? String,
                   let microBalance = Double(microBalanceString) {
                    totalBalance += microBalance
                }
            }
            let formattedTotalBalance = String(format: "%.3f", totalBalance / pow(10, self.coins[coinIndex].decimal))
            print("totalBalance", formattedTotalBalance)
                self.coins[coinIndex].balance = "\(formattedTotalBalance) \(self.coins[coinIndex].name)"
        } catch {
            print("Failed to fetch balance: \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.coins[coinIndex].balance = "0.00 \(self.coins[coinIndex].name)"
            }
        }
    }


    func initFundingAccount() async {
        do {
            let suiPrivateKey: String

            if let privateKeyFromEnv = ProcessInfo.processInfo.environment["suiPrivateKey"] {
                suiPrivateKey = privateKeyFromEnv
            } else {
                throw NSError(domain: "EnvironmentVariableError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Private Key not found in environment variables."])
            }

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

            guard let usersWalletAddress = usersWalletAddress else {
                  print("wallet address not yet set")
                  return
              }
              
              let object = try await suiProvider.getCoins(account: usersWalletAddress, coinType: "0x2::sui::SUI")
              print("object", object.data)
            
            var totalBalance: Double = 0
            for coin in object.data {
                if let microBalanceString = coin.balance as? String,
                   let microBalance = Double(microBalanceString) {
                    totalBalance += microBalance
                }
            }

            let formattedTotalBalance = String(format: "%.3f", totalBalance / 1e9)
            print("totalBalance", formattedTotalBalance)
            
            if totalBalance > 0 {
               print("Account already funded with balance: \(formattedTotalBalance) SUI")
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

            let fundingObject = try await suiProvider.getCoins(account: myAddress, coinType: "0x2::sui::SUI")
            print("fundingObject", object.data[0].balance)

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
                self.isLoading = false
                Task{
                    await self.fetchBalance(coinType: "0x2::sui::SUI")
                }
                
            }
        } catch {
            print("Error: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
}
