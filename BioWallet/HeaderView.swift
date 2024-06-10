import SwiftUI

struct HeaderView: View {
    @EnvironmentObject var viewModel: BioWalletViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LogoView()
            if !viewModel.username.isEmpty,
               let address = viewModel.usersWalletAddress {
                AccountInfoView(username: viewModel.username, address: address, balance: viewModel.selectedCoin.balance, onRefresh: {
                    Task {
                        await viewModel.fetchBalance(coinType: viewModel.selectedCoin.id)
                    }
                })
                .padding([.leading, .trailing], 10)
                .shadow(color: .blue, radius: 10)
            } else {
                // Debug information
                Text("Debug Info")
                Text("Username: \(viewModel.username)")
                if let address = viewModel.usersWalletAddress {
                    Text("Address: \(address)")
                } else {
                    Text("Address: nil")
                }
                Text("Selected Coin: \(viewModel.selectedCoin.name)")
                Text("Balance: \(viewModel.selectedCoin.balance)")
            }
        }
        .padding(.bottom)
        .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(12)
        .onAppear {
            if viewModel.isSignedIn {
                Task {
                    await viewModel.fetchBalance(coinType: viewModel.selectedCoin.id)
                }
            }
        }
    }
}

struct LogoView: View {
    var body: some View {
        ZStack {
            HStack {
                Image("BioWalletLogo")
                    .resizable()
                    .frame(width: 50, height: 50)
                Spacer()
            }
            Text("BioWallet")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

struct AccountInfoView: View {
    var username: String
    var address: String
    var balance: String
    var onRefresh: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            AccountsHeaderView(username: username)
            AccountDetailsView(address: address, onRefresh: onRefresh)
            BalanceView(balance: balance)
        }
        .padding(.horizontal)
        .padding(.bottom)
        .background(LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.white.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(12)
    }
}

struct AccountsHeaderView: View {
    var username: String
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("\(username)")
                .font(.title2)
                .padding(.top)
                .foregroundColor(.black)
                .fontWeight(.bold)
            Text("CURRENT")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct AccountDetailsView: View {
    var address: String
    var onRefresh: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(address.prefix(6) + "..." + address.suffix(6))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
            }
            Spacer()
            Button(action: {
                #if os(macOS)
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(address, forType: .string)
                #else
                UIPasteboard.general.string = address
                #endif
            }) {
                Image(systemName: "doc.on.doc")
                    .foregroundColor(.gray)
            }
            Button(action: {
                onRefresh?()
            }) {
                Image(systemName: "arrow.clockwise")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(8)
    }
}

struct BalanceView: View {
    var balance: String

    var body: some View {
        if balance == "0 SUI"{
            
        }else{
        Text("Balance: \(balance)")
            .font(.title3)
            .padding(.leading)
            .foregroundColor(.black)
            .fontWeight(.bold)
            .opacity(0.5)
        }
        
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BioWalletViewModel()
        HeaderView().environmentObject(viewModel)
    }
}
