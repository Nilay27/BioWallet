//
//  NetworkView.swift
//  BioWallet
//
//  Created by Kumar Nilay on 05/06/24.
//

import Foundation
import SwiftUI
import SuiKit

struct NetworkView: View {
    @EnvironmentObject var viewModel: BioWalletViewModel
    @State private var selectedNetwork: Network = .testnet
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    // Handle back action
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(.black)
                }
                Spacer()
                Text("Network")
                    .font(.largeTitle)
                    .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                    .foregroundColor(.white)
                    
                Spacer()
                // Placeholder for alignment
                Image(systemName: "arrow.left")
                    .opacity(0) // Make it invisible
            }
            .padding()
            
            List {
                ForEach(Network.allCases, id: \.self) { network in
                    HStack {
                        Text(network.rawValue)
                            .foregroundColor(.white)
                            .font(.title3)
                            .fontWeight(/*@START_MENU_TOKEN@*/.bold/*@END_MENU_TOKEN@*/)
                        Spacer()
                        if selectedNetwork == network {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Image(systemName: "circle")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedNetwork = network
                        viewModel.changeNetwork(to: network)
                    }
                }
            }
            .listStyle(PlainListStyle())
            .onAppear {
                selectedNetwork = viewModel.selectedNetwork
            }
            .background(Color.black)
            .opacity(0.8)
        }
        .background(Color.black)
        .opacity(0.8)
    }
}

enum Network: String, CaseIterable {
    case mainnet = "Mainnet"
    case devnet = "Devnet"
    case testnet = "Testnet"
    case local = "Local"

    var connection: ConnectionProtocol {
        switch self {
        case .mainnet:
            return MainnetConnection()
        case .devnet:
            return DevnetConnection()
        case .testnet:
            return TestnetConnection()
        case .local:
            return LocalnetConnection()
        }
    }
}

struct NetworkView_Previews: PreviewProvider {
    static var previews: some View {
        NetworkView()
            .environmentObject(BioWalletViewModel())
    }
}


