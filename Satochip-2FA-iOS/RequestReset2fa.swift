//
//  RequestReset2fa.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 24/04/2023.
//

import Foundation

public struct RequestReset2fa: RequestData {
    
    public let type = "RESET_2FA"
    public var challengeHex: String
    public var warningCode = WarningCode.Ok // code 0 = no issue
    //public var responseHex = String(repeating: "00", count: 20) // reject by default
        
    init(requestJson: [String:AnyHashable], id20Hex: String) throws {
        self.challengeHex =  id20Hex + String(repeating: "AA", count: 44)
    }
}
