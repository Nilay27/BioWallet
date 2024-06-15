//
//  BridgeView.swift
//  BioWallet
//
//  Created by Kumar Nilay on 05/06/24.
//

import Foundation
import SwiftUI

struct Bridge: Identifiable {
    let id = UUID()
    let name: String
    let symbol: String
}

struct BridgeView: View {
    @State private var isDropdownOpen: Bool = false
    @State private var selectedBridge: Bridge? = nil // Change type to Bridge?
    @State private var walletAddress: String = ""
    @State private var amount: String = ""
    @State private var isLoading: Bool = false
    @EnvironmentObject var viewModel: BioWalletViewModel
    @State private var transactionStatus: TransactionStatus? = nil
    @State private var transactionResult: String = ""
    @State private var showAlert: Bool = false

    let bridges: [Bridge] = [
            Bridge(name: "Sui", symbol: "suiLogo"),
            Bridge(name: "Ethereum", symbol: "ethereumLogo"),
            Bridge(name: "Polygon", symbol: "polygonLogo"),
            Bridge(name: "Avalanche", symbol: "avalancheLogo")
        ]

    var body: some View {
           VStack {
               Spacer()
               DropdownMenu(isOpen: $isDropdownOpen, label: {
                   HStack {
                       if let selectedBridge = selectedBridge {
                           HStack {
                               Text(selectedBridge.name)
                                   .foregroundColor(.white)
                                   .background(Color.black)
                                   .font(.title3)
                                   .fontWeight(.bold)
                           }
                           .padding()
                           .background(Color.black.opacity(0.8))
                           .cornerRadius(10)
                           .padding(.horizontal, 20)
                       } else {
                           Text("Select Bridge")
                               .foregroundColor(.white)
                               .padding()
                               .background(Color.black)
                               .cornerRadius(10)
                               .padding(.horizontal, 20)
                       }
                   }
               }) {
                   VStack(spacing: 0) { // Ensure no spacing between items
                       ForEach(bridges) { bridge in
                           HStack {
                               Text(bridge.name)
                           }
                           .padding(.vertical, 10) // Consistent padding for all items
                           .background(Color.black)
                           .fontWeight(.bold)
                           .font(.title3)
                           .onTapGesture {
                               withAnimation {
                                   selectedBridge = bridge
                                   isDropdownOpen = false
                               }
                           }
                       }
                   }
               }
               .padding()

               TextField("Wallet Address", text: $walletAddress)
                   .padding()
                   .background(Color.black)
                   .foregroundColor(.white)
                   .cornerRadius(10)
                   .textFieldStyle(PlainTextFieldStyle())
                   .padding([.leading, .trailing])

               TextField("Amount", text: $amount)
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
                           isLoading = true
                           await performBridgeTransaction()
                           isLoading = false
                       }
                   }) {
                       Text("Bridge")
                           .padding()
                           .frame(maxWidth: .infinity)
                           .background(Color.red)
                           .foregroundColor(.white)
                           .cornerRadius(10)
                           .padding([.leading, .trailing])
                   }
                   .disabled(walletAddress.isEmpty || amount.isEmpty || selectedBridge == nil)
                   Spacer()
               }

               Spacer()
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
           .background(Color.black.opacity(0.8))
           .overlay(transactionOverlay)
           .edgesIgnoringSafeArea(.all)
       }

    func performBridgeTransaction() async {
        do {
            guard let recipientChain = selectedBridge?.name else {
                print("Bridge not selected")
                return
            }
            
            guard let myAddress = viewModel.usersWalletAddress else {
                print("My address not found")
                return
            }
            
            let res = try await viewModel.bioWalletSigner.signAndExecuteBridgeTransaction(recipientChain: recipientChain, senderAddress: myAddress, receiverAddress: walletAddress, amountToSend: amount)
            print("result of bridging", res)
            print("Transaction successful")
            DispatchQueue.main.async {
                self.transactionStatus = .success
                self.transactionResult = "https://suiscan.xyz/\(viewModel.selectedNetwork.rawValue.lowercased())/tx/\(res.digest)" 
                self.showAlert = true
            }
            await viewModel.fetchBalance(coinType: viewModel.selectedCoin.id)

        } catch {
            print("Failed to execute bridge transaction: \(error)")
            DispatchQueue.main.async {
                self.transactionStatus = .failure
                self.transactionResult = error.localizedDescription
                self.showAlert = true
            }
        }
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

    enum TransactionStatus {
        case success
        case failure
    }
}

struct BridgeView_Previews: PreviewProvider {
    static var previews: some View {
        BridgeView()
    }
}
