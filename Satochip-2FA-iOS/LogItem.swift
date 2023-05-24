//
//  LogItem.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 18/04/2023.
//

import Foundation

public struct LogItem: Hashable {
    
    public var id = UUID()
    
    public var date = Date.now
    public var label: String
    public var idfactor: String
    public var status: String
    public var description: String

//    public init(id: String, label: String, msg: String){
//        self.id = id
//        self.label = label
//        self.msgRaw = msg
//    }
    
}

