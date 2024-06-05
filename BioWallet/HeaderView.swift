import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

struct HeaderView: View {
    var username: String?
    var address: String?
    var balance: String?
    var onRefresh: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            LogoView()
            if let username = username, let address = address, let balance = balance {
                AccountInfoView(username: username, address: address, balance: balance, onRefresh: onRefresh)
                    .padding([.leading, .trailing], 10)
                    .shadow(color: .blue, radius: 10)
            }
            Spacer()
        }
        .background(LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0.3), Color.blue.opacity(0.3)]), startPoint: .top, endPoint: .bottom))
        .cornerRadius(12)
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
        Text("Balance: \(balance)")
            .font(.title3)
            .padding(.leading)
            .foregroundColor(.black)
            .fontWeight(.bold)
            .opacity(0.5)
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(username: "testuser", address: "0x1234567890abcdef", balance: "1 SUI", onRefresh: {})
    }
}
