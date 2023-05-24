//
//  RequestResetSeed.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 19/04/2023.
//

import Foundation

public struct RequestResetSeed: RequestData {
    
    public let type = "RESET_SEED"
    public var challengeHex: String
    public var responseHex = String(repeating: "00", count: 20) // reject by default
    public var warningCode: WarningCode = WarningCode.Ok // code 0 = no issue
    
    public var authentikeyx: String
    
    init(requestJson: [String:AnyHashable]) throws {
        guard let authentikeyx = requestJson["authentikeyx"] as? String else {
            throw RequestError.RequestWrongFormat(details: "missing authentikeyx in resetSeed")
        }
        self.authentikeyx = authentikeyx
        self.challengeHex = self.authentikeyx + String(repeating: "FF", count: 32)
        //let request = RequestResetSeed(challengeHex: challengeHex, authentikeyx: authentikeyx)
        //return request
    }
}
