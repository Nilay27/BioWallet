//
//  BioWalletApp.swift
//  BioWallet
//
//  Created by Kumar Nilay on 01/06/24.
//

import SwiftUI

@main
struct BioWalletApp: App {
    @StateObject private var viewModel = BioWalletViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(viewModel)
        }
    }
}


