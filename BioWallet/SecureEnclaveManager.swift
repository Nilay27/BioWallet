import Foundation
import Security
import LocalAuthentication
import BigInt

class SecureEnclaveManager {
    
    func generateKeyPair(tag: String, completion: @escaping (SecKey?, Data?, Data?, Error?) -> Void) {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate to generate key pair") { success, authenticationError in
            guard success else {
                completion(nil, nil, nil, authenticationError)
                return
            }
            
            let tagData = tag.data(using: .utf8)!
            
            let attributes: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits as String: 256,
                kSecPrivateKeyAttrs as String: [
                    kSecAttrIsPermanent as String: true,
                    kSecAttrApplicationTag as String: tagData
                ]
            ]
            
            var error: Unmanaged<CFError>?
            guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
                completion(nil, nil, nil, error?.takeRetainedValue())
                return
            }
            
            guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
                completion(nil, nil, nil, nil)
                return
            }
            
            guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
                completion(nil, nil, nil, error?.takeRetainedValue())
                return
            }
            
            let uncompressedPublicKey = publicKeyData as Data
            print("Uncompressed Public Key (with header): \(uncompressedPublicKey)")

            let uncompressedKey = uncompressedPublicKey.dropFirst()
            print("Uncompressed Public Key (64 bytes): \(uncompressedKey)")

            let compressedKey = self.compressPublicKey(uncompressedKey: uncompressedKey)
            print("Compressed Public Key (33 bytes): \(compressedKey)")
            
            completion(publicKey, uncompressedKey, compressedKey, nil)
        }
    }

    private func compressPublicKey(uncompressedKey: Data) -> Data {
        let x = uncompressedKey.prefix(32)
        let y = uncompressedKey.suffix(32)
        let yParity: UInt8 = y.last! % 2 == 0 ? 0x02 : 0x03
        var compressedKey = Data([yParity])
        compressedKey.append(x)
        return compressedKey
    }
    
    func signData(data: Data, tag: String, completion: @escaping (Data?, Error?) -> Void) {
        let context = LAContext()
        context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: "Authenticate to sign data") { success, authenticationError in
            guard success else {
                completion(nil, authenticationError)
                return
            }

            let tagData = tag.data(using: .utf8)!

            let query: [String: Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrApplicationTag as String: tagData,
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecReturnRef as String: true
            ]
            print("query", query)

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)
            print("status", status)

            guard status == errSecSuccess, let privateKey = item as! SecKey? else {
                completion(nil, NSError(domain: NSOSStatusErrorDomain, code: Int(status), userInfo: nil))
                return
            }
            print("status after privateKey", status)
            print("ref to privateKey accessed?", privateKey)

            var error: Unmanaged<CFError>?
            guard let derSignature = SecKeyCreateSignature(privateKey, .ecdsaSignatureMessageX962SHA256, data as CFData, &error) else {
                completion(nil, error?.takeRetainedValue())
                return
            }

            if let rawSignature = self.decodeECDSASignature(derSignature as Data) {
                let normalizedSignature = self.normalizeSignature(rawSignature)
                completion(normalizedSignature, nil)
            } else {
                completion(nil, NSError(domain: "SecureEnclaveManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to decode ECDSA signature"]))
            }
        }
    }

    private func decodeECDSASignature(_ derSignature: Data) -> Data? {
        var asn1Decoder = ASN1Decoder(data: derSignature)
        guard let _ = asn1Decoder.readSequence() else { return nil }
        guard let r =  asn1Decoder.readInteger(), let s =  asn1Decoder.readInteger() else { return nil }
        
        let rData = r.leftPadding(toLength: 32, withPad: 0x00)
        let sData = s.leftPadding(toLength: 32, withPad: 0x00)
        
        return rData + sData
    }
    
    private func normalizeSignature(_ signature: Data) -> Data {
        let curveOrder = BigInt("FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551", radix: 16)!
        let halfCurveOrder = curveOrder / 2

        // Assuming the signature is evenly split between r and s
        let r = BigInt(signature.prefix(32))
        var s = BigInt(signature.suffix(32))

        // Normalize s if necessary
        if s > halfCurveOrder {
            s = curveOrder - s
        }

        // Convert back to Data, ensuring it's zero-padded to the correct length
        let rData = r.serialize().leftPadding(toLength: 32, withPad: 0x00)
        let sData = s.serialize().leftPadding(toLength: 32, withPad: 0x00)
        return rData + sData
    }

}

struct ASN1Decoder {
    var data: Data
    var offset: Int = 0
    
    mutating func readByte() -> UInt8? {
        guard offset < data.count else { return nil }
        let byte = data[offset]
        offset += 1
        return byte
    }
    
    mutating func readLength() -> Int? {
        guard let firstByte = readByte() else { return nil }
        if firstByte & 0x80 == 0 {
            return Int(firstByte)
        } else {
            let lengthOfLength = Int(firstByte & 0x7F)
            var length = 0
            for _ in 0..<lengthOfLength {
                guard let byte = readByte() else { return nil }
                length = (length << 8) | Int(byte)
            }
            return length
        }
    }
    
    mutating func readInteger() -> Data? {
        guard let firstByte = readByte() else { return nil }
        guard firstByte == 0x02 else { return nil }
        guard let length = readLength() else { return nil }
        guard offset + length <= data.count else { return nil }
        let integerData = data.subdata(in: offset..<offset + length)
        offset += length
        return integerData
    }
    
    mutating func readSequence() -> Int? {
        guard let firstByte = readByte() else { return nil }
        guard firstByte == 0x30 else { return nil }
        return readLength()
    }
}

extension Data {
    var bytes: [UInt8] {
        return [UInt8](self)
    }
}

extension Data {
    var hexEncodedString: String {
        return map { String(format: "%02x", $0) }.joined()
    }
}

// Extension to pad data with a specific byte
extension Data {
    func leftPadding(toLength: Int, withPad character: UInt8) -> Data {
        if self.count < toLength {
            let padding = Data(repeating: character, count: toLength - self.count)
            return padding + self
        } else if self.count > toLength {
            return self.suffix(toLength)
        } else {
            return self
        }
    }
}

extension BigInt {
    init(_ data: Data) {
        self.init(sign: .plus, magnitude: BigUInt(data))
    }
    
    func serialize() -> Data {
        return self.magnitude.serialize()
    }
}

extension String {
    func leftPad(toLength: Int, withPad: String = "0") -> String {
        let padding = String(repeating: withPad, count: toLength - self.count)
        return padding + self
    }
}
