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
        VStack {
            ZStack {
                HStack {
                    Image("BioWalletLogo")
                        .resizable()
                        .frame(width: 100, height: 100)
                    Spacer()
                }
                Text("BioWallet")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            .padding()
            .background(Color.black.opacity(0.8))
            
            if let username = username, let address = address, let balance = balance {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Username: \(username)")
                            .font(.largeTitle)
                        HStack {
                            if let url = URL(string: "https://suiscan.xyz/devnet/account/\(address)") {
                                Link("Address: \(address.prefix(6))...\(address.suffix(6))", destination: url)
                                    .font(/*@START_MENU_TOKEN@*/.title/*@END_MENU_TOKEN@*/)
                            }
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
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            }
                        }
                        Text("Balance: \(balance)")
                            .font(.title)
                    }
                    Spacer()
                    Button(action: {
                        onRefresh?()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                }
                .padding()
                .background(Color.black.opacity(0.8))
                .foregroundColor(.white)
            }
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView(username: "testuser", address: "0x1234567890abcdef", balance: "1 SUI", onRefresh: {})
    }
}
