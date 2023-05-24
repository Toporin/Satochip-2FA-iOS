//
//  RequestItem.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 17/04/2023.
//

import Foundation

public enum WarningCode: Int {
    case Ok = 0
    case HashMismatch = 1
    case UnsupportedSignMsgHashRequest = 2
    case WrongMessageFormat = 3
    case EIP712Unsupported = 4
    case FailedToParseEIP712Msg = 5
}

// todo: add protocol for requestData?
public protocol RequestData: Hashable {
    var type: String { get }
    var challengeHex: String { get set }
    var warningCode: WarningCode {get set}
    //var responseHex: String {get set}
}

public struct RequestItem: Hashable {
    public static func == (lhs: RequestItem, rhs: RequestItem) -> Bool {
        if lhs.id == rhs.id {
            return true
        } else {
            return false
        }
    }
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.id)
    }
    
    public var id = UUID() // todo: idHex?
    public var idHex: String
    public var msgRaw: String
    public var label: String
    public var responseHex: String? = nil
    public var requestData: (any RequestData)? = nil //(any Hashable)? = nil // parsed request
    
    public init(id: String, label: String, msg: String){
        self.idHex = id
        self.label = label
        self.msgRaw = msg
    }
    
}
