//
//  BioWalletApp.swift
//  BioWallet
//
//  Created by Kumar Nilay on 01/06/24.
//

import SwiftUI

@main
struct BioWalletApp: App {
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                isSignedIn = false
            }
        }
    }
}


