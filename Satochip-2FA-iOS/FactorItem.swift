//
//  FactorItem.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 13/04/2023.
//

import Foundation
import CryptoSwift

public struct FactorItem: Hashable, Codable {
    
    public var id = UUID()
    public var secretBytes: [UInt8]
    public var label: String = ""
    public var id20Bytes: [UInt8]
    public var id20Hex: String = ""
    public var idBytes: [UInt8]
    public var idHex: String = ""
    public var idOtherBytes: [UInt8]
    public var idOtherHex: String = ""
    public var keyBytes: [UInt8]
    
    public init(secretBytes: [UInt8], label: String){
        self.label = label
        self.secretBytes = secretBytes
        //self.idBytes = secretBytes
        //self.idHex = idBytes.bytesToHex
        self.id20Bytes = try! HMAC(key: secretBytes, variant: .sha1).authenticate(Array("id_2FA".utf8))
        self.id20Hex = id20Bytes.bytesToHex
        print("id20Hex: \(id20Hex)")
        self.idBytes = Digest.sha256(id20Bytes)
        self.idHex = idBytes.bytesToHex
        print("idHex: \(idHex)")
        self.idOtherBytes = Digest.sha256(Array(self.idHex.utf8))
        self.idOtherHex = self.idOtherBytes.bytesToHex
        print("idOtherHex: \(idOtherHex)")
        var keyBytes32 = try! HMAC(key: secretBytes, variant: .sha1).authenticate(Array("key_2FA".utf8))
        self.keyBytes = Array(keyBytes32[0..<16]) // keep first 16 bytes out of 20
    }
    
    func approveChallenge(challengeHex: String) -> String {
        let challengeBytes = challengeHex.hexToBytes
        let responseBytes = try! HMAC(key: self.secretBytes, variant: .sha1).authenticate(challengeBytes)
        let responseHex = responseBytes.bytesToHex
        return responseHex
    }
    
    func rejectChallenge(challengeHex: String) -> String {
        return String(repeating: "00", count: 20)
    }
    
    // decrypt incoming request msg
    // decrypt msg
    func decryptRequest(msgRaw: String) throws -> [String:AnyHashable] {
        
        // base64 decode
        //let msgEncrypted = String.fromBase64(msgRaw)
        guard let msgDecoded = Data.fromBase64(msgRaw) else {
            print("failed to decode base64 msg")
            //todo: throw
            //return ""
            throw RequestError.Base64DecodingError
        }
        
        // decrypt message & remove padding
        let iv = Array(msgDecoded[0..<16])
        let msgEncrypted = Array(msgDecoded[16...])
        let msgDecrypted = try CryptoSwift.AES(key: self.keyBytes, blockMode: CBC(iv: iv), padding: .pkcs7).decrypt(msgEncrypted)
        
        // decode json
        guard let msgJsonString = String(bytes: msgDecrypted, encoding: .utf8) else {
            print("not a valid UTF-8 sequence")
            // todo: throw
            throw RequestError.Utf8DecodingError
        }
        print("request msgJsonString: \(msgJsonString)")
        
        let msgJson = try JSONSerialization.jsonObject(with: Data(msgDecrypted), options: [])
        // todo: use custom structure?
        
        print("request type of msgJson: \(type(of: msgJson))")
        print("request msgJson: \(msgJson)")
        //return msgJson as! [String:String]
        return msgJson as! [String:AnyHashable]
    }
    
    // encrypt response
    func encryptRequest(msgPlainTxt: String) throws -> String {
        let iv: [UInt8]
        do {
            iv = try generateRandomBytes(count: 16)
        } catch {
            iv = [UInt8]((0 ..< 16).map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
        }
        let msgPlainBytes = Array(msgPlainTxt.utf8)
        var msgEncryptedBytes = try CryptoSwift.AES(key: self.keyBytes, blockMode: CBC(iv: iv), padding: .pkcs7).encrypt(msgPlainBytes)
        msgEncryptedBytes = iv + msgEncryptedBytes
        let msgEncryptedBase64 = msgEncryptedBytes.toBase64()
        print("Satochip: msgEncryptedBase64: " + msgEncryptedBase64)
        
        return msgEncryptedBase64
    }
    
    
    func generateRandomBytes(count: Int) throws -> [UInt8] {
        var bytes = [UInt8](repeating: 0, count: count)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

        guard result == errSecSuccess else {
            print("Problem generating random bytes")
            throw AppError.RandomGeneratorError
        }

        return bytes //Data(bytes).base64EncodedString()
    }
}
