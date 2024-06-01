import SuiKit
import SwiftUI

struct SignInView: View {
    @Binding var isSignedIn: Bool
    @Binding var username: String
    @State private var enteredUsername: String = ""
    @State private var isLoading: Bool = false
    @State private var showingAlert: Bool = false
    @State private var alertMessage: String = ""
    @State private var userMap: [String: [String: String]] = [:]
    var bioWalletSigner: BioWalletSigner

    var body: some View {
        GeometryReader { geometry in
            VStack {
                HeaderView()
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
                    Button(action: {
                        isLoading = true
                        Task {
                            do {
                                if userMap[enteredUsername] == nil {
                                    let tagToPublicKeyMap = try await bioWalletSigner.createWallet()
                                    userMap[enteredUsername] = ["tag": tagToPublicKeyMap.tag, "publicKey": tagToPublicKeyMap.publicKey.base64()]
                                }
                                UserDefaults.standard.set(userMap, forKey: "userMap")
                                username = enteredUsername
                                isSignedIn = true
                            } catch {
                                // Handle error, such as user cancellation
                                print("Failed to create wallet: \(error.localizedDescription)")
                                alertMessage = error.localizedDescription
                                showingAlert = true
                            }
                            isLoading = false
                        }
                    }) {
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
            .onAppear {
                if let storedUserMap = UserDefaults.standard.dictionary(forKey: "userMap") as? [String: [String: String]] {
                    userMap = storedUserMap
                }
            }
            .alert("Error", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    @State static var isSignedIn = false
    @State static var username = ""
    static var previews: some View {
        let suiProvider = SuiProvider(connection: DevnetConnection())
        let bioWalletSigner = BioWalletSigner(provider: suiProvider)
        SignInView(isSignedIn: $isSignedIn, username: $username, bioWalletSigner: bioWalletSigner)
    }
}

