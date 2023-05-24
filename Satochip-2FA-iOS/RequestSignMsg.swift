//
//  RequestSignMsg.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 20/04/2023.
//

import Foundation
import CryptoSwift
import HsExtensions

public struct RequestSignMsg: RequestData {
    
    public let type = "SIGN_MSG"
    public var challengeHex: String
    public var responseHex = String(repeating: "00", count: 20) // reject by default
    public var warningCode: WarningCode = WarningCode.Ok // code 0 = no issue
    
    public var msg: String
    public var msgHashHex: String
    
    init(requestJson: [String:AnyHashable]) throws {
        guard let msg: String = requestJson["msg"] as? String else {
            throw RequestError.RequestWrongFormat(details: "missing msg in requestSignMsg")
        }
        self.msg = msg
        let altcoin: String = requestJson["alt"] as? String ?? "Bitcoin"
        let headersize = [UInt8(altcoin.bytes.count + 17)]
        let msgBytes = Array(msg.utf8)
        var msgPaddedBytes : [UInt8] = headersize
        msgPaddedBytes = msgPaddedBytes + Array(altcoin.utf8)
        msgPaddedBytes = msgPaddedBytes + Array(" Signed Message:\n".utf8)
        msgPaddedBytes = msgPaddedBytes + VarInt(msgBytes.count).data
        msgPaddedBytes = msgPaddedBytes + msgBytes
        
        self.msgHashHex = Digest.sha256(msgPaddedBytes).bytesToHex
        self.challengeHex = msgHashHex + String(repeating: "BB", count: 32)
        
        //let request = RequestSignMsg(challengeHex: challengeHex, msg: msg, msgHashHex: msgHashHex)
        //return request
    }
    
    
}
