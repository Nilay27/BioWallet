//
//  BioWalletApp.swift
<<<<<<< HEAD
//  BioWallet
//
//  Created by Kumar Nilay on 01/06/24.
=======
//  Bio-Wallet
//
//  Created by Kumar Nilay on 29/05/24.
>>>>>>> old-history
//

import SwiftUI

@main
struct BioWalletApp: App {
<<<<<<< HEAD
=======
    @AppStorage("isSignedIn") private var isSignedIn: Bool = false
    @Environment(\.scenePhase) private var scenePhase

>>>>>>> old-history
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
<<<<<<< HEAD
    }
}
=======
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background || newPhase == .inactive {
                isSignedIn = false
            }
        }
    }
}


>>>>>>> old-history
