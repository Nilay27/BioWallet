import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: BioWalletViewModel
    @State private var selectedTab: Tab = .transfer

    var body: some View {
        VStack {
            
            if viewModel.isSignedIn {
                HeaderView()
                Spacer()
                switch selectedTab {
                case .transfer:
                    TransferView()
//                case .swap:
//                    SwapView()
                case .bridge:
                    BridgeView()
                case .network:
                    NetworkView()
                }
            FooterView(selectedTab: $selectedTab) // Provide binding here
            } else {
                SignInView()
            }
            
        }
        .background(Color.black.opacity(0.8))
        .edgesIgnoringSafeArea(.all)
    }
}

enum Tab {
    case transfer
//    case swap
    case bridge
    case network
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Initialize the view model with a username
       let viewModel = BioWalletViewModel()
       viewModel.signIn(username: "nilay")
        return ContentView()
            .environmentObject(BioWalletViewModel())
    }
}
