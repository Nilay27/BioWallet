//
//  CoinPickerItem.swift
//  BioWallet
//
//  Created by Kumar Nilay on 09/06/24.
//

import Foundation
import SwiftUI

struct CoinPickerItem: View {
    @EnvironmentObject var viewModel: BioWalletViewModel
    let coin: Coin

    var body: some View {
        HStack(spacing: 5) {
            Image(coin.logo)
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .clipped()
            Text("\(coin.name) (\(coin.balance))")
                .font(.title3)
                .foregroundColor(.white)
                .opacity(/*@START_MENU_TOKEN@*/0.8/*@END_MENU_TOKEN@*/)
        }
        .padding(.horizontal, 5)
        .onAppear {
            Task {
                await viewModel.fetchBalance(coinType: coin.id)
            }
        }
    }
}

struct DropdownMenu<Label: View, Content: View>: View {
    @Binding var isOpen: Bool
    @ViewBuilder var label: Label
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                label 
                Spacer()
                Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                    .foregroundColor(.white)
            }
            .onTapGesture {
                withAnimation {
                    isOpen.toggle()
                }
            }

            if isOpen {
                VStack(spacing: 0) { // Ensure no spacing between items
                    content
                        .background(Color.black)
                        .opacity(0.8)
                        .cornerRadius(8)
                        .shadow(radius: 4)
                        .padding(.top, 5)
                }
                .transition(.move(edge: .top))
            }
        }
    }
}

struct CoinPickerItem_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BioWalletViewModel()
        CoinPickerItem(coin: viewModel.coins.first!)
            .environmentObject(viewModel)
    }
}
