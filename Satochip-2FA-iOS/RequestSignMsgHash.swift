//
//  RequestSignMsgHash.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 20/04/2023.
//

import Foundation
import CryptoSwift
//import HsExtensions

public struct RequestSignMsgHash: RequestData {
    
    public let type = "SIGN_MSG_HASH"
    public var challengeHex: String
    public var responseHex = String(repeating: "00", count: 20) // reject by default
    public var warningCode: WarningCode = WarningCode.Ok // code 0 = no issue
    
    public var msg: String
    public var msgHashHex: String
    public var msgType: String
    
    /// <#Description#>
    /// - Parameter requestJson: <#requestJson description#>
    init(requestJson: [String:AnyHashable]) throws {
        
        let altcoin = "Ethereum"
        guard let hash = requestJson["hash"] as? String else {
            throw RequestError.RequestWrongFormat(details: "missing hash in requestSignMsg")
        }
        guard let msg: String = requestJson["msg"] as? String else {
            throw RequestError.RequestWrongFormat(details: "missing msg in requestSignMsg")
        }
        self.msgType = requestJson["msg_type"] as? String ?? "PERSONAL_MESSAGE"
        self.msg = msg
        self.msgHashHex = hash
        
        if self.msgType == "PERSONAL_MESSAGE" || msgType == "MESSAGE" {
            // TODO: if message is in hex-format, convert it to utf8 string
            var msgTxt = self.msg
            if (msgTxt.hasPrefix("0x")){
                msgTxt = String(msgTxt.dropFirst(2))
                if let tmp = String(bytes: msgTxt.hexToBytes, encoding: .utf8) {
                    msgTxt = tmp
                    self.msg = msgTxt
                } else {
                    //throw RequestError.RequestWrongFormat(details: "wrong msg format to sign in requestSignMsg")
                    msgTxt = self.msg
                    self.warningCode = WarningCode.WrongMessageFormat
                }
                
            }
            var msgBytes = Array(msgTxt.utf8)
            var prefixBytes = Array("\u{19}Ethereum Signed Message:\n".utf8)
            prefixBytes += Array(String(msgBytes.count).utf8)
            let msgEncodedBytes = prefixBytes + msgBytes
            
            let keccak = SHA3(variant: .keccak256)
            let msgEncodedHashBytes = keccak.calculate(for: msgEncodedBytes)
            let msgEncodedHashHex = msgEncodedHashBytes.bytesToHex
            
            if msgEncodedHashHex != self.msgHashHex.uppercased() {
                self.warningCode = WarningCode.HashMismatch
            }
            self.challengeHex = self.msgHashHex + String(repeating: "CC", count: 32)
            
        } else if self.msgType == "TYPED_MESSAGE" {
            do {
                print("typedMsg: \(msg)")
                if let fullJson = try JSONSerialization.jsonObject(with: Data(msg.utf8), options: []) as? [String: Any]{
                    print("fullJson: \(fullJson)")
                    let typedJson = fullJson["typedData"] as? [String: Any] ?? fullJson
                    print("typedJson: \(typedJson)")
                    let rawData = try JSONSerialization.data(withJSONObject: typedJson)
                    let decoder = JSONDecoder()
                    let typedData = try decoder.decode(EIP712TypedData.self, from: rawData)
                    let hashedMessage = try typedData.signHash()
                    let hashedMessageHex = [UInt8](hashedMessage).bytesToHex
                    print("hashedMessage: \(hashedMessageHex)")
                    print("self.msgHashHex: \(self.msgHashHex)")
                    
                    if hashedMessageHex != self.msgHashHex.uppercased() {
                        self.warningCode = WarningCode.HashMismatch // todo: expected, computed
                    }
                    self.challengeHex = self.msgHashHex + String(repeating: "CC", count: 32)
                    
                } else {
                    throw RequestError.JsonError
                }
            } catch let error as NSError {
                print("Failed to parse EIP712 msg: \(error) ")
                self.warningCode = WarningCode.FailedToParseEIP712Msg
                self.challengeHex = self.msgHashHex + String(repeating: "CC", count: 32)
            }
            
        } else {
            // User should be extra cautious and reject by default
            self.warningCode = WarningCode.UnsupportedSignMsgHashRequest
            self.challengeHex = self.msgHashHex + String(repeating: "CC", count: 32)
        }
    }
    
    
}

