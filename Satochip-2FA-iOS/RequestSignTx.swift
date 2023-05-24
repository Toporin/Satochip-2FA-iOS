//
//  RequestSignTx.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 24/04/2023.
//

import Foundation
import CryptoSwift
import SwiftCryptoTools

public struct RequestSignTx: RequestData {
    
    public let type = "SIGN_TX"
    public var challengeHex: String
    public var warningCode = WarningCode.Ok // code 0 = no issue
    //public var responseHex = String(repeating: "00", count: 20) // reject by default
    
    public var id = UUID()
    public var requestJson: [String:AnyHashable]
    public var txParsed = ""
    public var txType: String = ""
    public var coinObject: Bitcoin
//    public var coinType: UInt = 0
//    public var coinName: String = ""
    public var inputs = [String]()
    public var outputs = [String]()
    public var inputAmounts = [Double?]()
    public var outputAmounts = [Double?]()
    public var fee : Double?
    
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.id.uuidString)
    }
    
    static public func ==(lhs: RequestSignTx, rhs: RequestSignTx) -> Bool {
        if lhs.requestJson == rhs.requestJson {
            return true
        } else {
            return false
        }
    }
    
    init(requestJson: [String:AnyHashable]) throws {
        self.requestJson = requestJson
        self.challengeHex = ""
        self.txParsed = ""
        
        guard let isSegwit = requestJson["sw"] as? Bool else {
            throw RequestError.RequestWrongFormat(details: "missing isSegwit (sw) property")
        }
        guard let coinType = requestJson["ct"] as? UInt32 else {
            throw RequestError.RequestWrongFormat(details: "missing coinType (ct) property")
        }
        
        guard let txHex = requestJson["tx"] as? String else {
            throw RequestError.RequestWrongFormat(details: "missing txInput (tx) property")
        }
        
//        guard let isTestnet = requestJson["tn"] as? Bool else {
//            throw RequestError.RequestWrongFormat(details: "missing isTestnet (tn) property")
//        }
//
        let isTestnet = requestJson["tn"] as? Bool ?? false
        
        
        //let self.coinObject: Bitcoin
        switch coinType {
        case 0:
            self.coinObject = Bitcoin(isTestnet: false, apiKeys: [String:String]())
        case 1:
            self.coinObject = Bitcoin(isTestnet: true, apiKeys: [String:String]())
        case 2:
            self.coinObject = Litecoin(isTestnet: isTestnet, apiKeys: [String:String]())
        case 145:
            self.coinObject = BitcoinCash(isTestnet: isTestnet, apiKeys: [String:String]())
        default:
            print("Satochip: Coin not (yet) supported: \(coinType)")
            self.coinObject = UnsupportedBitcoinFork(isTestnet: true, apiKeys: [String:String]())
        }
        txParsed = "Coin: "+self.coinObject.displayName+"\n"
        //coinName = self.coinObject.displayName
        
        let txBytes = txHex.hexToBytes
        let txHashBytes = Digest.sha256(Digest.sha256(txBytes))
        let txHashHex = txHashBytes.bytesToHex
        self.challengeHex = txHashHex + String(repeating: "00", count: 32)
        
        if isSegwit {
            
            // parse segwit tx
            guard let txinType = requestJson["ty"] as? String else {
                throw RequestError.RequestWrongFormat(details: "missing txinType (ty) property")
            }
            print("txinType: \(txinType)")
            var txparser = TxParser(txBytes: txBytes)
            txparser.parseSegwitTransaction()
            
            print("Satochip: hashPrevouts: \(txparser.hashPrevouts.bytesToHex)")
            print("Satochip: hashSequence: \(txparser.hashSequence.bytesToHex)")
            print("Satochip: txOutHash: \(txparser.txOutHash.bytesToHex)")
            print("Satochip: txOutIndex: \(txparser.txOutIndex)")
            print("Satochip: inputScript: \(txparser.inputScript.bytesToHex)")
            print("Satochip: inputAmount: \(txparser.inputAmount)")
            print("Satochip: nSequence: \(txparser.nSequence.bytesToHex)")
            print("Satochip: hashOutputs: \(txparser.hashOutputs.bytesToHex)")
            print("Satochip: nLocktime: \(txparser.nLocktime.bytesToHex)")
            print("Satochip: nHashType: \(txparser.nHashType.bytesToHex)")
            
            let scriptHex = txparser.inputScript.bytesToHex
            print("Satochip: inputScript: \(scriptHex)")
            
            let addr: String
            if txinType == "p2wpkh" {
                let hashHex = txparser.outputScriptToH160(scriptHex: scriptHex)
                let hashBytes = hashHex.hexToBytes
                addr = try self.coinObject.hashToSegwitAddr(hash: hashBytes)
                print("Satochip: p2wpkh address: \(addr)")
            } else if txinType == "p2wsh" { //multisig-segwit
                addr = try self.coinObject.scriptToP2wsh(script: scriptHex.hexToBytes)
                print("Satochip: p2wsh address: \(addr)")
            } else if txinType == "p2wsh-p2sh" {
                let hashHex = txparser.outputScriptToH160(scriptHex: scriptHex)
                let hashBytes = hashHex.hexToBytes
                let fullHashBytes = "0020".hexToBytes + hashBytes
                addr = self.coinObject.p2shScriptToAddr(script: fullHashBytes)
                print("Satochip: p2wsh-p2sh address: \(addr)")
//                h= transaction.output_script_to_h160(script)
//                addr= self.coinObject.p2sh_scriptaddr("0020"+h)
            } else if txinType == "p2wpkh-p2sh" {
                // for p2wpkh-p2sh addres is derived from script hash, see https://github.com/bitcoin/bips/blob/master/bip-0141.mediawiki#P2WPKH_nested_in_BIP16_P2SH
                let hashHex = txparser.outputScriptToH160(scriptHex: scriptHex)
                let hashBytes = hashHex.hexToBytes
                let fullHashBytes = "0014".hexToBytes + hashBytes
                addr = self.coinObject.p2shScriptToAddr(script: fullHashBytes)
                print("Satochip: p2wpkh-p2sh address: \(addr)")
                //h= transaction.output_script_to_h160(script)
                //addr= self.coinObject.p2sh_scriptaddr("0014"+h)
            } else if (coinType == 145) && (txinType == "p2pkh" || txinType == "p2sh"){
                // for bcash
                addr = self.coinObject.scriptToAddr(script: scriptHex.hexToBytes)
                // TODO: convert to cashaddr...
                //let cashAddress = CashAddrBech32.encode(Data([versionByte]) + Data(pubkeyHash), prefix: cashAddrPrefix)
                print("Satochip: txin type: \(txinType) address: \(addr)")
                
//                addr= coin.scripttoaddr(script)
//                addr= convert.to_cash_address(addr) #cashAddr conversion
//                addr= addr.split(":",1)[-1] #remove prefix
            } else{
                addr = "unsupported script: \(scriptHex) \n"
            }
            print("addr: \(addr)")
            inputs.append(addr)
            inputAmounts.append(Double(txparser.inputAmount))
            
            self.txParsed += "input:\n"
            self.txParsed += "\t address: \(addr) spent: \(Double(txparser.inputAmount)/100000) \n"  //satoshi to mBtc
            
            // parse outputs
            guard let txoHex = requestJson["txo"] as? String else {
                throw RequestError.RequestWrongFormat(details: "missing txOutputs (txo) property")
            }
            let txoBytes = txoHex.hexToBytes
            var txoParser = TxParser(txBytes: txoBytes)
            txoParser.parseOutputs()
            
            let hashOutputsBytes = Digest.sha256(Digest.sha256( Array(txoBytes.dropFirst(1)) ))
            //hashOutputs=sha256(sha256(outputs[1:]).digest()).hexdigest()
            
            let nbOuts = txoParser.outAmounts.count
            print("nbOuts= \(nbOuts)")
            
            txParsed += "outputs (\(nbOuts)):\n"
            var amountOut: UInt64 = 0
            for i in 0..<nbOuts {
                let amount = txoParser.outAmounts[i]
                amountOut += amount
                let scriptBytes = txoParser.outScripts[i]
                let scriptHex = scriptBytes.bytesToHex
                var isDataScript = false
                print("Satochip: outScripts: \(scriptBytes.bytesToHex)")
                print("Satochip: amount: \(amount)")
            
                var addrOut: String
                if scriptHex.hasPrefix("76A914") { //p2pkh
                    addrOut = self.coinObject.scriptToAddr(script: scriptBytes)
                } else if scriptHex.hasPrefix("A914"){ //p2sh
                    addrOut = self.coinObject.scriptToAddr(script: scriptBytes)
                } else if scriptHex.hasPrefix("0014"){ //p2wpkh
                    let hashBytes = Array(scriptBytes.dropFirst(2))
                    addrOut = try self.coinObject.hashToSegwitAddr(hash: hashBytes)
                    print("DEBUG p2wpkh: \(addrOut)")
                } else if scriptHex.hasPrefix("0020"){ //p2wsh
                    let hashBytes = Array(scriptBytes.dropFirst(2))
                    addrOut = try self.coinObject.hashToSegwitAddr(hash: hashBytes)
                } else if scriptHex.hasPrefix("6A"){ // op_return data script
                    if scriptHex.hasPrefix("6A04534C5000"){
                        //# SLP token
                        addrOut = "TODO: SLP parsing"
//                        try:
//                        addr= self.parse_slp_script(script)
//                        except Exception as ex:
//                        addr= 'Error during SLP script parsing! '
//                        Logger.warning("Error during SLP script parsing: "+str(ex))
                    } else{
                        let dataBytes = scriptBytes.dropFirst(3)
                        let dataStr = String(decoding: dataBytes, as: UTF8.self)
                        addrOut = "DATA: \(dataStr)"
                        // addr= "DATA: "+  bytes.fromhex(script[6:]).decode('utf-8', errors='backslashreplace') # errors='ignore', 'backslashreplace', 'replace'
                    }
                    isDataScript = true
                } else {
                    addrOut = "unsupported script: \(scriptHex) \n"
                }
                
                if (coinType==145) && !isDataScript {
                    addrOut = "TODO: convert addr \(addrOut) to cashaddress"
                    //addr= convert.to_cash_address(addr) #cashAddr conversion
                    //addr= addr.split(":",1)[-1] #remove prefix
                }
                print("Satochip: output address: \(addrOut)")
                txParsed += "\t address: \(addrOut) spent: \(Double(amountOut)/100000) \n" //satoshi to mBtc
                outputs.append(addrOut)
                outputAmounts.append(Double(amountOut))
                
            } // for nbOuts
            
            txParsed += "\t total: \(Double(amountOut)/100000) m\(self.coinObject.coinSymbol) \n"  //satoshi to mBtc

            if hashOutputsBytes != txparser.hashOutputs {
                txParsed += "Warning! inconsistent output hashes!\n"
                warningCode = WarningCode.HashMismatch
            }
            
            print("DEBUG: txParsed: \(txParsed)")
            
        } else { // legacy...
            
            var txparser = TxParser(txBytes: txBytes)
            txparser.parseTransaction()
            let txparsercopy = txparser
            
            //Task { // since some call are async
                // Inputs
                let nbIns = txparsercopy.inputScriptArray.count
                var amountTotalIn: Double = 0
                var txParsed = "inputs (\(nbIns)):\n"
                for (index, scriptBytes) in txparsercopy.inputScriptArray.enumerated() {
                    let scriptHex = scriptBytes.bytesToHex
                    print("Satochip: input script: \(scriptHex)")
                    
                    // debug
                    let txOutHash = txparsercopy.txOutHashArray[index]
                    let txOutIndex = txparsercopy.txOutIndexArray[index]
                    print("txhash: \(txOutHash.bytesToHex), txOutIndex: \(txOutIndex)")
                    
                    // recover script and corresponding addresse
                    let addrIn: String
                    if scriptHex == "" { // all input scripts are removed for signing except 1
                        let txOutHash = txparsercopy.txOutHashArray[index]
                        let txOutIndex = txparsercopy.txOutIndexArray[index]
                        print("txhash: \(txOutHash.bytesToHex), txOutIndex: \(txOutIndex)")
                        addrIn = "tx:\(txOutHash.bytesToHex):\(txOutIndex)"
                    } else if scriptHex.hasSuffix("AE") { // m-of-n pay-to-multisig
                        //m= int(script[0:2], 16)-80
                        //n= int(script[-4:-2], 16)-80
                        txParsed += "\t multisig m-of-n \n"
                        addrIn = self.coinObject.p2shScriptToAddr(script: scriptBytes)
                        print("Satochip: address multisig: \(addrIn)")
                    } else { //p2pkh, p2sh
                        addrIn = self.coinObject.scriptToAddr(script: scriptBytes)
                        print("Satochip: address: \(addrIn)")
//                        // DEBUG: get tx prevout
//                        let txOutHash = txparsercopy.txOutHashArray[index]
//                        let txOutIndex = txparsercopy.txOutIndexArray[index]
//                        print("txhash: \(txOutHash.bytesToHex), txOutIndex: \(txOutIndex)")
//                        addrIn = "tx:\(txOutHash.bytesToHex):\(txOutIndex)"
                    }
                    
                    // amount not available at this point
                    txParsed += "\t address: \(addrIn) balance: n/a \n"
                    
                    inputs.append(addrIn)
                    inputAmounts.append(nil)
                    
                }// for inputs
                txParsed += "\t total: \(amountTotalIn/100000) m\(self.coinObject.coinSymbol) \n" //satoshi to mBtc
                
            //} // task
            
            // outputs
            var amountTotalOut: Double = 0
            let nbOuts = txparser.outScripts.count
            txParsed += "outputs (\(nbOuts)): \n"
            for (index, scriptBytes) in txparser.outScripts.enumerated(){
                
                let amountUInt64 = txparser.outAmounts[index]
                let amountOut = Double(amountUInt64)
                amountTotalOut += amountOut
                let addrOut: String
                let scriptHex = scriptBytes.bytesToHex
                print("Satochip: output script: \(scriptHex)")
                if scriptHex.hasPrefix("76A914"){ // p2pkh
                    addrOut = self.coinObject.scriptToAddr(script: scriptBytes)
                } else if scriptHex.hasPrefix("A914"){ // p2sh
                    addrOut = self.coinObject.scriptToAddr(script: scriptBytes)
                } else if scriptHex.hasPrefix("0014"){ //p2wpkh
                    let hash = Array(scriptBytes.dropFirst(2))
                    do {
                        addrOut = try self.coinObject.hashToSegwitAddr(hash: hash)
                    } catch {
                        addrOut = "Failed to parse p2wpkh script \(scriptHex)"
                    }
                } else if scriptHex.hasPrefix("0020"){ // p2wsh
                    let hash = Array(scriptBytes.dropFirst(2))
                    do {
                        addrOut = try self.coinObject.hashToSegwitAddr(hash: hash)
                    } catch {
                        addrOut = "Failed to parse p2wsh script \(scriptHex)"
                    }
                } else{
                    addrOut = "Unsupported script: \(scriptHex) \n"
                }
                
                txParsed += "\t address: \(addrOut) spent: \(amountOut/100000) \n" //satoshi to mBtc
                
                outputs.append(addrOut)
                outputAmounts.append(Double(amountUInt64))
                
            } // for outputs
            txParsed += "\t total: \(amountTotalOut/100000) m\(self.coinObject.coinSymbol) \n"  //satoshi to mBtc
            
            let fees = 1 //amountTotalIn-amountTotalOut
            if fees >= 0 {
                txParsed += "\t  fees: \(fees/100000) m\(self.coinObject.coinSymbol) \n" // satoshi to mBtc
            }
            
        } // end legacy
        
        
    } // init
    
}
