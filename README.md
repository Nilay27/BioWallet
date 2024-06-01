

---

# BioWallet

<img src="./BioWallet/Assets.xcassets/BioWalletLogo.imageset/Bio_Wallet%201.png" alt="BioWallet Logo" width="200" height="200">


#### **Your device is your hardware wallet, simple, secure and streamlined!**
## Demo Link

[Watch the Demo](https://youtu.be/Ihawy_Cb5iI?si=dbHM6l5ECHXhdC5U)

## Features
- **Hardware Wallet Transformation**: BioWallet securely stores your private key in the Secure Enclave of your device, transforming it into a hardware wallet. 
  - This eliminates the hassle of managing seed phrases and significantly reduces the risk of compromising your private key.
- **SUI Network Integration**: Built on the SUI network, leveraging its robust signature flexibility and support for Secp256R1 signature curve.
- **Secure Transactions**: Sign and perform transactions securely with biometric authentication using secure enclave.
- **Enhanced Security**: No more seed phrases; private keys never leave the device, ensuring top-notch security.
- **Passkey Backup**: Seamlessly interact with the wallet across your devices utilizing passkeys.
- **User-Friendly Interface**: Intuitive and easy-to-use interface with essential features.
- **Upcoming WebAuthn based SDK**: 


### Upcoming Features

#### WebAuthn SDK
- **Streamlined Onboarding**: An upcoming WebAuthn SDK will make onboarding extremely streamlined. Users won't even need to install the app and can interact with webApps that integrate with our SDK directly.
    - **SUI SIP Support**: This feature will leverage the upcoming SIP ([SIP-9](https://github.com/sui-foundation/sips/pull/9/)) which will enable WebAuthn support.

#### MultiSig Wallet
- **MultiSig Support**: BioWallet will soon support MultiSig wallets, allowing for enhanced security and flexibility.
    - **Multiple Key Schemes**: The MultiSig wallet will utilize keys across different schemes including secp256r1, secp256k1, and Ed25519.

#### Recovery Methods
  - **MPC Based Recovery**: In case the device does not support passkeys/ the passkeys were deleted.
    - Multi-Party Computation (MPC) based recovery ensures you can regain access to your wallet even if you lose your device (upcoming feature).

Feel free to copy this markdown into your README file.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Sample Methods](#sample-methods)

## Installation

### Prerequisites

- Xcode (latest version)
- Swift 5.0+
- iOS 14.0+

### Steps

1. **Clone the Repository**

    ```bash
    git clone https://github.com/yourusername/biowallet.git
    cd biowallet
    ```

2. **Open in Xcode**

    Open the project in Xcode by double-clicking on `BioWallet.xcodeproj`.

3. **Set Up Your Environment**

    - Connect your iOS device (iPad or iPhone).
    - Ensure your device is trusted and paired with your Mac.
  
4. **Setup env variable**
   - Provide the environment variable of pvt key for prefunding. 

5. **Build and Run**

    Select your connected device from the device list in Xcode and click the Run button.


## Sample Methods
### 1. Initialize the BioWalletSigner
```swift
let suiProvider = SuiProvider(connection: DevnetConnection())
let bioWalletSigner = BioWalletSigner(provider: suiProvider)
```
### 1. Sign a Message

```swift
let dataToSign = "Hello, Secure Enclave!".data(using: .utf8)!
let signature = try await biowalletSigner.signMessage(dataToSign)
```

### 2. Sign and execute a Transaction

```swift
// build a transaction:
var txb = try TransactionBlock()
try txb.setSenderIfNotSet(sender: usersWalletAddress)
let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(amount))])
try txb.transferObject(objects: [coin], address: account.address())
let res = try await bioWalletSigner.signAndExecuteTransactionBlock(&txb)
print("result", res)
```

### 3. Sign a Transaction

```swift
// build a transaction:
var txb = try TransactionBlock()
try txb.setSenderIfNotSet(sender: usersWalletAddress)
let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(amount))])
try txb.transferObject(objects: [coin], address: account.address())
// gives the serialized blockBytes and the serialized signature
// serialized signature contains flag || signature || publicKey 
// total 1 + 64 + 33 = 98 bytes worth of base64 encoded signature
let (serializedBlock, serializedSignature) = try await biowalletSigner.signAndExecuteTransactionBlock(&txb)
```

### 4. Perform a dry run to check txn validation
```swift
// build a transaction:
var txb = try TransactionBlock()
try txb.setSenderIfNotSet(sender: usersWalletAddress)
let coin = try txb.splitCoin(coin: txb.gas, amounts: [try txb.pure(value: .number(amount))])
try txb.transferObject(objects: [coin], address: account.address())
let dryRunRes = try await bioWalletSigner.dryRunTransactionBlock(&txb)
print("Dry run result", dryRunRes)
//  check for error by utilizing:  dryRunRes.effects?.status.error, if empty, dry run was succesful
```


---


