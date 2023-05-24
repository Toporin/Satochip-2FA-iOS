//
//  TxParser.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 24/04/2023.
//

import Foundation
import  CryptoSwift

public enum TxState {
    case TX_START
    case TX_PARSE_INPUT
    case TX_PARSE_INPUT_SCRIPT
    case TX_PARSE_OUTPUT
    case TX_PARSE_OUTPUT_SCRIPT
    case TX_PARSE_FINALIZE
    case TX_END
}

public struct TxParser {
    
    var txBytes: [UInt8]
    var txOffset = 0
    var txRemaining:Int
    var isParsed = false
    
    // shared
    var txVersion = [UInt8]()
    var outScripts = [[UInt8]]()
    var outAmounts = [UInt64]()
    var singleHash = [UInt8]()
    var doubleHash =  [UInt8]()
    
    // legacy tx
    var txOutHashArray = [[UInt8]]()
    var txOutIndexArray = [UInt32]()
    var inputScriptArray = [[UInt8]]()
    
    // segwit tx
    var hashPrevouts = [UInt8]()
    var hashSequence = [UInt8]()
    var txOutHash = [UInt8]()
    var txOutIndex: UInt32 = 0
    var inputAmount: UInt64 = 0
    var inputScript = [UInt8]()
    var nSequence = [UInt8]()
    var hashOutputs = [UInt8]()
    var nLocktime = [UInt8]()
    var nHashType = [UInt8]()
    
    init(txBytes: [UInt8]){
        self.txBytes = txBytes
        self.txRemaining = txBytes.count
    }
    
    mutating func parseTransaction(){
        
        //TxState.TX_START {
        // max 4+9 bytes accumulated
        self.txVersion = self.parseBytes(length: 4) // version
        var txRemainingInputs = Int(self.parseVarInt())
        
        //TxState.TX_PARSE_INPUT
        while(txRemainingInputs > 0) {
            var txOutHash = self.parseBytes(length: 32) // txOutHash
            txOutHash = reverseBytes(inBytes: txOutHash)
            self.txOutHashArray.append(txOutHash)
            let txOutIndexBytes = self.parseBytes(length: 4) // txOutIndex
            let txOutIndex = self.readUInt32(bytes: txOutIndexBytes, offset: 0)
            self.txOutIndexArray.append(txOutIndex)
            
            //self.txState = TxState.TX_PARSE_INPUT_SCRIPT
            let txRemainingScripts = Int(self.parseVarInt());
            let inputScriptBytes = self.parseBytes(length: txRemainingScripts)
            self.inputScriptArray.append(inputScriptBytes)
            self.parseBytes(length: 4) // sequence
            
            txRemainingInputs-=1
        }
        
        //TxState.TX_PARSE_OUTPUT
        var txRemainingOutputs = Int(self.parseVarInt())
        while (txRemainingOutputs > 0){
            let amountBytes = self.parseBytes(length: 8) // amount
            self.outAmounts.append(self.readUInt64(bytes: amountBytes, offset: 0))
            
            // TxState.TX_PARSE_OUTPUT_SCRIPT
            let txRemainingScripts = Int(self.parseVarInt())
            let scripts = self.parseBytes(length: txRemainingScripts)
            self.outScripts.append(scripts)
            
            txRemainingOutputs -= 1
        }
        
        // TxState.TX_END:
        
        // update hash
        self.singleHash = Digest.sha256(self.txBytes)
        self.doubleHash = Digest.sha256(self.singleHash)
        self.isParsed = true
    }
    
    mutating func parseOutputs(){
        
        // TxState.TX_START)
        var txRemainingOutputs = Int(self.parseVarInt())
        
        // TxState.TX_PARSE_OUTPUT)
        while (txRemainingOutputs > 0){
            let amountBytes = self.parseBytes(length: 8) // amount
            self.outAmounts.append(self.readUInt64(bytes: amountBytes, offset: 0))
            
            // TxState.TX_PARSE_OUTPUT_SCRIPT
            let txRemainingScripts = Int(self.parseVarInt())
            let scripts = self.parseBytes(length: txRemainingScripts)
            self.outScripts.append(scripts)
            txRemainingOutputs-=1
        }
        
        // update hash
        self.singleHash = Digest.sha256(self.txBytes)
        self.doubleHash = Digest.sha256(self.singleHash)
        self.isParsed = true
    }
    
    mutating func parseSegwitTransaction() {
        
        // TxState.TX_START
        self.txVersion = self.parseBytes(length: 4)
        self.hashPrevouts = self.parseBytes(length: 32)
        self.hashSequence = self.parseBytes(length: 32)
        // parse outpoint
        self.txOutHash = parseBytes(length: 32)
        self.txOutHash = reverseBytes(inBytes: self.txOutHash)
        let txOutIndexBytes = parseBytes(length: 4)
        self.txOutIndex = readUInt32(bytes: txOutIndexBytes, offset: 0)
        // scriptcode= varint+script
        let txRemainingScripts = Int(self.parseVarInt())
        print("Debug txRemainingScripts: \(txRemainingScripts)")
        // TxState.TX_PARSE_INPUT_SCRIPT
        self.inputScript = self.parseBytes(length: txRemainingScripts)
        
        // TxState.TX_PARSE_FINALIZE:
        let inputAmountBytes = self.parseBytes(length: 8)
        print("inputAmountBytes: \(inputAmountBytes.bytesToHex)")
        self.inputAmount = self.readUInt64(bytes: inputAmountBytes, offset: 0)
        self.nSequence = parseBytes(length: 4)
        self.hashOutputs = self.parseBytes(length: 32)
        self.nLocktime = self.parseBytes(length: 4)
        self.nHashType = self.parseBytes(length: 4)
        
        //TxState.TX_END
        // update hash
        self.singleHash = Digest.sha256(self.txBytes)
        self.doubleHash = Digest.sha256(self.singleHash)
        self.isParsed = true
    }
    
    mutating func parseBytes(length: Int) -> [UInt8]{
        // todo: check length >0
        // todo check bounds
        let chunk = Array(self.txBytes[self.txOffset..<(self.txOffset+length)])
        self.txOffset += length
        self.txRemaining -= length
        return chunk
    }
    
    //mutating func parseVarInt() -> (UInt64, [UInt8]) {
    mutating func parseVarInt() -> UInt64 {
        let first = 0xFF & self.txBytes[self.txOffset]
        let val: UInt64
        let le: Int
        if first < 253 {
            // 8 bits
            val = UInt64(first)
            le = 1
        } else if first == 253 {
            // 16 bits
            val = UInt64(0xFF & self.txBytes[self.txOffset+1]) + UInt64((0xFF & self.txBytes[self.txOffset+2]) << 8)
            le=3
        } else if first == 254 {
            // 32 bits
            val = UInt64(self.readUInt32(bytes: self.txBytes, offset: self.txOffset + 1))
            le=5
        } else {
            // 64 bits
            val = self.readUInt64(bytes: self.txBytes, offset: self.txOffset + 1)
            le=9
        }
        //let txChunk = Array(self.txBytes[self.txOffset..<(self.txOffset+le)])
        self.txOffset+=le
        self.txRemaining-=le
        return val
    }
                
    func readUInt32(bytes: [UInt8], offset: Int) -> UInt32 {
        let out: UInt32
        out = UInt32(0xFF & bytes[offset]) +
                (UInt32(0xFF & bytes[offset+1]) << 8) +
                (UInt32(0xFF & bytes[offset+2]) << 16) +
                (UInt32(0xFF & bytes[offset+3]) << 24)
        return out
    }
  
//    // DEBUG!
//    func readUInt32(bytes: [UInt8], offset: Int) -> UInt32 {
//        let out: UInt32 = 0
//        return out
//    }
//    // DEBUG!!
//    func readUInt64(bytes: [UInt8], offset: Int) -> UInt64 {
//        let out: UInt64 = 0
//        return out
//    }
    
    func readUInt64(bytes: [UInt8], offset: Int) -> UInt64 {
        let out: UInt64
        print("Bytes: \(bytes.bytesToHex)")
        print("UInt0: \(UInt64(0xFF & bytes[offset]))")
        print("UInt1: \(UInt64((0xFF & bytes[offset+1]) << 8))")
        print("UInt2: \(UInt64((0xFF & bytes[offset+2]) << 16))")
        print("UInt3: \(UInt64((0xFF & bytes[offset+3]) << 24))")
        print("Alternative")
        print("UInt0: \(UInt64(0xFF & bytes[offset]))")
        print("UInt1: \(UInt64((0xFF & bytes[offset+1])) << 8)")
        print("UInt2: \(UInt64((0xFF & bytes[offset+2])) << 16)")
        print("UInt3: \(UInt64((0xFF & bytes[offset+3])) << 24)")

        out =   UInt64(0xFF & bytes[offset]) +
                (UInt64(0xFF & bytes[offset+1]) << 8) +
                (UInt64(0xFF & bytes[offset+2]) << 16) +
                (UInt64(0xFF & bytes[offset+3]) << 24) +
                (UInt64(0xFF & bytes[offset+4]) << 32) +
                (UInt64(0xFF & bytes[offset+5]) << 40) +
                (UInt64(0xFF & bytes[offset+6]) << 48) +
                (UInt64(0xFF & bytes[offset+7]) << 56)
        return out
    }
    
    func outputScriptToH160(scriptHex: String) -> String {
        var scriptHexOut = scriptHex
        if scriptHex.hasPrefix("76"){
            scriptHexOut = String(scriptHexOut.dropFirst(6))
        }
        else {
            scriptHexOut = String(scriptHexOut.dropFirst(4))
        }
        
        if scriptHex.hasSuffix("88AC"){
            scriptHexOut = String(scriptHexOut.dropLast(4))
        }
        else {
            scriptHexOut = String(scriptHexOut.dropLast(2))
        }
        print("scriptHex:    \(scriptHex)")
        print("scriptHexOut: \(scriptHexOut)")
        return scriptHexOut
    }
    
    func reverseBytes(inBytes: [UInt8]) -> [UInt8] {
        let size = inBytes.count
        var outBytes = [UInt8](repeating: 0, count: size)
        for (index, item) in inBytes.enumerated(){
            outBytes[size-1-index] = inBytes[index]
        }
        return outBytes
    }
}





