import SuiKit
import SwiftUI

struct SignInView: View {
    @EnvironmentObject var viewModel: BioWalletViewModel
    @State private var enteredUsername: String = ""
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        GeometryReader { geometry in
            VStack {
                LogoView()
                Spacer()
                TextField("Enter Username", text: $enteredUsername)
                    .padding()
                    .background(Color.black)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .textFieldStyle(PlainTextFieldStyle())
                    .padding([.leading, .trailing])

                if isLoading {
                    ZStack {
                        ProgressView()
                        Text("Creating Wallet...")
                            .foregroundColor(.white)
                    }
                    .padding()
                } else {
                    Button(action: signIn) {
                        Text("Sign In")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding([.leading, .trailing])
                    }
                    .disabled(enteredUsername.isEmpty)
                }
                Spacer()
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .background(Color.black.opacity(0.8))
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }

    private func signIn() {
        isLoading = true
        Task {
            do {
                if let userMap = UserDefaults.standard.dictionary(forKey: "userMap") as? [String: [String: String]], userMap[enteredUsername] != nil {
                    // User exists
                } else {
                    // Create a new wallet
                    let tagToPublicKeyMap = try await viewModel.bioWalletSigner.createWallet()
                    var newUserMap = UserDefaults.standard.dictionary(forKey: "userMap") as? [String: [String: String]] ?? [:]
                    newUserMap[enteredUsername] = ["tag": tagToPublicKeyMap.tag, "publicKey": tagToPublicKeyMap.publicKey.base64()]
                    UserDefaults.standard.set(newUserMap, forKey: "userMap")
                }
                viewModel.signIn(username: enteredUsername)
            } catch {
                alertMessage = "Failed to create wallet: \(error.localizedDescription)"
                showingAlert = true
            }
            isLoading = false
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BioWalletViewModel()
        SignInView()
            .environmentObject(viewModel)
    }
}
