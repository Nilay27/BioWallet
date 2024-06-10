//
//  TransferView.swift
//  BioWallet
//
//  Created by Kumar Nilay on 05/06/24.
//

import Foundation
import SwiftUI
import SuiKit


class Coin: Identifiable, Hashable {
    let id: String
    let name: String
    var balance: String
    let logo: String
    let decimal: Double

    init(id: String, name: String, balance: String, logo: String, decimal: Double) {
        self.id = id
        self.name = name
        self.balance = balance
        self.logo = logo
        self.decimal = decimal
    }

    static func == (lhs: Coin, rhs: Coin) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    func setBalance(newBalance: String) {
        self.balance = newBalance
    }
}

struct TransferView: View {
    @EnvironmentObject var viewModel: BioWalletViewModel
    @State private var walletAddress: String = ""
    @State private var amount: String = ""
    @State private var isLoading: Bool = false
    @State private var transactionStatus: TransactionStatus? = nil
    @State private var transactionResult: String = ""
    @State private var showAlert: Bool = false
    @State private var isDropdownOpen = false

    var body: some View {
            VStack {
                Spacer()
                DropdownMenu(isOpen: $isDropdownOpen, label: {
                    HStack {
                        CoinPickerItem(coin: viewModel.selectedCoin)
                    }
                    .background(Color.black.opacity(0.2))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }) {
                    VStack(spacing: 0) { // Ensure no spacing between items
                        ForEach(viewModel.coins) { coin in
                            CoinPickerItem(coin: coin)
                                .padding(.vertical, 10) // Consistent padding for all items
                                .background(viewModel.selectedCoin == coin ? Color.black.opacity(0.2) : Color.white)
                                .onTapGesture {
                                    withAnimation {
                                        viewModel.selectedCoin = coin
                                        isDropdownOpen = false
                                        Task {
                                            await viewModel.fetchBalance(coinType: coin.id)
                                        }
                                    }
                                }
                        }
                    }
                    .background(Color.black)
                    .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
                    .cornerRadius(8)
                    .shadow(radius: 4)
                    .padding(.top, 5)
                }
                .padding()

                TextField("SUI Wallet Address", text: $walletAddress)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding([.leading, .trailing])

                TextField("Amount (max limit: \(viewModel.selectedCoin.balance ?? "0"))", text: $amount)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding([.leading, .trailing])

                if isLoading {
                    ProgressView("Processing Transaction...")
                        .foregroundColor(.white)
                        .padding()
                } else {
                    Button(action: {
                        Task {
                            await signBioWalletTxn(walletAddress: walletAddress, amount: amount, coinType: viewModel.selectedCoin.id)
                        }
                    }) {
                        Text("Transfer")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding([.leading, .trailing])
                    }
                    .disabled(walletAddress.isEmpty || amount.isEmpty || viewModel.selectedCoin == nil)
                }

                Button(action: {
                    viewModel.signOut()
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

                Spacer()
            }
            .background(Color.black.opacity(0.8))
            .overlay(
                transactionOverlay
            )
        }

    private var transactionOverlay: some View {
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
    }

    private func signBioWalletTxn(walletAddress: String, amount: String, coinType:String) async {
        do {
            isLoading = true
            defer { isLoading = false }

            guard !viewModel.bioWalletSigner.tag.isEmpty else {
                print("keyTag is empty")
                return
            }

            guard let sendingAmount = Double(amount) else {
                print("Error in amount", amount)
                return
            }
            
            guard let senderAddress = viewModel.usersWalletAddress, !senderAddress.isEmpty else {
                // Handle the error case when the sender address is not set
                print("Sender address is not set")
                return
            }

            let scaledAmount = sendingAmount * pow(10, viewModel.selectedCoin.decimal)
            let sendingAmountInMist = UInt64(scaledAmount)

            var txb = try TransactionBlock()
            var coin: TransactionArgument;
            if coinType == "0x2::sui::SUI" {
                coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(sendingAmountInMist))])
            }else{
                print("trying to transfer for coinType \(coinType)")
                let object = try await viewModel.suiProvider.getCoins(account: senderAddress, coinType: coinType)
                coin = try txb.splitCoin(coin: txb.object(id: object.data[0].coinObjectId).toTransactionArgument(), amounts: [try txb.pure(value: .number(sendingAmountInMist))])
            }
            
            try txb.transferObject(objects: [coin], address: walletAddress)
            try txb.setSenderIfNotSet(sender: senderAddress)

            let dryRunRes = try await viewModel.bioWalletSigner.dryRunTransactionBlock(&txb)

            if let error = dryRunRes.effects?.status.error {
                print("dryRunRes Error:", error)
                DispatchQueue.main.async {
                    self.transactionStatus = .failure
                    self.transactionResult = error // Directly using the error string
                    self.showAlert = true
                }
            } else {
                print("dryRunRes Success")
                let res = try await viewModel.bioWalletSigner.signAndExecuteTransactionBlock(&txb)
                print(res)
                DispatchQueue.main.async {
                    self.transactionStatus = .success
                    self.transactionResult = "https://suiscan.xyz/testnet/tx/\(res.digest)" // Set this to your actual transaction result link
                    self.showAlert = true
                }
            }
        } catch {
            print("Failed to sign data: \(error)")
            DispatchQueue.main.async {
                self.transactionStatus = .failure
                self.transactionResult = error.localizedDescription
                self.showAlert = true
            }
        }
    }

    enum TransactionStatus {
        case success
        case failure
    }
}

struct TransferView_Previews: PreviewProvider {
    static var previews: some View {
        TransferView()
            .environmentObject(BioWalletViewModel())
    }
}
