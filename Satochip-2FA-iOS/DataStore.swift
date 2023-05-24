//
//  DataStore.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 13/04/2023.
//

import Foundation
import XmlRpc
import CryptoSwift

//import HsExtensions

public enum RequestError: Error {
    case Base64DecodingError
    case Base64EncodingError
    case Utf8DecodingError
    case StringDecodingError
    case JsonError
    case EncryptionError
    case UnsupportedAction(action: String)
    case RequestWrongFormat(details: String)
    case EmptyRequest
}

public enum AppError: Error {
    case RandomGeneratorError
}


class DataStore: ObservableObject {
    
    //@Published var factorArray: [FactorItem] = [FactorItem]() //[]
    @Published var factorDict: [String:FactorItem] = [String:FactorItem]()
    @Published var requestArray: [RequestItem] = [RequestItem]()
    @Published var isRequestAvailable: Bool = false
    
    var client: XmlRpcClient
    
    // fetch web data only after xmlrpc server polling has finished...
    //let dispatchGroup = DispatchGroup()
    
    // settings
    let defaults = UserDefaults.standard
    var isAlreadyUsed = false
    
    init(){
        // xmlrpc connection
        self.client  = XmlRpc.createClient("https://cosigner.electrum.org")
        //self.client  = XmlRpc.createClient("https://cosigner.satochip.io")
        
        // settings
        isAlreadyUsed = defaults.bool(forKey: "isAlreadyUsed")
        if isAlreadyUsed {
            // load factors from user defaults
            //self.factorDict = defaults.object(forKey: "factorDict") as? [String:FactorItem] ?? [String:FactorItem]()
            if let factorsEncoded = defaults.object(forKey: "factorsEncoded") as? Data,
               let factorsDecoded = try? JSONDecoder().decode([String:FactorItem].self, from: factorsEncoded) {
                print("factorsDecoded: \(factorsDecoded)")
                self.factorDict = factorsDecoded
            }
            
        } else {
            // set factors default values
            defaults.set(true, forKey: "isAlreadyUsed")
            // create (empty) factors dict
            self.factorDict = [String:FactorItem]()
            
            // DEBUG add dummy request
            let secretHex = "7a1ead453ce43d309a4ad1416cb5013542b45208"
            let newFactor = self.addFactor(secretHex: secretHex, label: "test2FA")
            
            // save factors in default
            if let factorsEncoded = try? JSONEncoder().encode(self.factorDict) {
                defaults.set(factorsEncoded, forKey: "factorsEncoded")
            }
            //defaults.set(self.factorDict, forKey: "factorDict")
        }
        
//        let secretBytes = [UInt8](repeating: 0x00, count: 32)
//        let newFactor = self.addFactor(secretHex: secretBytes.bytesToHex, label: "test")
//        let newFactor = FactorItem(secretBytes: secretBytes, label: "test")
//        self.factorArray.append(newFactor)
        
        // todo: load factors from storage
        
        // add dummy request
//        let secretHex = "7a1ead453ce43d309a4ad1416cb5013542b45208"
//        let newFactor = self.addFactor(secretHex: secretHex, label: "test2FA")
//        if let newFactor = newFactor {
//            self.putServer(id: newFactor.idHex, msg: "TEST REQUEST")
//        }
    }
    
    func addFactor(secretHex: String, label: String) -> FactorItem?{
        // TODO: throw if malformed hex...
        do {
            let secretBytes = secretHex.hexToBytes
            let newFactor = FactorItem(secretBytes: secretBytes, label: label)
            //self.factorArray.append(newFactor)
            self.factorDict[newFactor.idHex] = newFactor
            
            // save factors in default
            //defaults.set(self.factorDict, forKey: "factorDict")
            if let factorsEncoded = try? JSONEncoder().encode(self.factorDict) {
                defaults.set(factorsEncoded, forKey: "factorsEncoded")
            }
            
            return newFactor
        }
        catch {
            //
            print("Failed to parse factor: \(secretHex)")
            return nil
        }
    }
    
    // remove factor
    // TODO!
    
    // poll server for requests
    @MainActor
    func pollServer() {
        print("Polling server START...")
        
        //for factor in factorArray {
        for (idHex, factor) in factorDict {
            
            //print("polling for factor: \(factor.idHex)")
            print("polling for factor: \(idHex)")
            
            do {
                
//                var methods = try client.get("get", factor.idHex)
//                print("Polling server get: result: \(methods)")
                
                self.client.call("get", factor.idHex) { error, value in
                    
                    if let error = error {
                        print("Call failed with error:", error)
                    }
                    else {
                        
                        print("Got request: ", value)
                        print("Got request strignValue: ", value.stringValue)
                        print("Got request description: ", value.description)
                        let msgRaw = value.stringValue
                        
                        if (msgRaw == "<null>"){
                            print("No response for this factor")
                        } else {
                            
                            var requestData: (any RequestData)? = nil //(any Hashable)? = nil
                            // TODO: parse!
                            do{
                                let requestJson = try factor.decryptRequest(msgRaw: msgRaw)
                                // get requested operation
//                                guard let action: String = (requestJson["action"] as? String? ?? "sign_tx") else {
//                                    throw RequestError.RequestWrongFormat(details: "missing action property")
//                                }
                                let action: String = ((requestJson["action"] as! String?) ?? "sign_tx")
                                // TODO: safe downcasting instead of forcing downcasting
                                print("action: \(action)")
                                
                                switch action {
                                    
                                case "reset_seed":
                                    requestData = try RequestResetSeed(requestJson: requestJson)
                                    
                                case "reset_2FA":
                                    requestData = try RequestReset2fa(requestJson: requestJson, id20Hex: factor.id20Hex)
                                
                                case "sign_msg":
                                    requestData = try RequestSignMsg(requestJson: requestJson)
                                    print("requestData requestData RequestSignMsg: \(requestData)")
                                    
                                case "sign_tx":
                                    //throw RequestError.UnsupportedAction(action: action)
                                    requestData = try RequestSignTx(requestJson: requestJson)
                                    print("requestData requestData RequestSignTx: \(requestData)")
                                    
                                case "sign_msg_hash":
                                    //throw RequestError.UnsupportedAction(action: action)
                                    requestData = try RequestSignMsgHash(requestJson: requestJson)
                                    print("requestData requestData RequestSignMsgHash: \(requestData)")
                                    
                                case "sign_tx_hash":
                                    //throw RequestError.UnsupportedAction(action: action)
                                    requestData = try RequestSignTxHash(requestJson: requestJson)
                                    print("requestData requestData RequestSignTxHash: \(requestData)")
                                    
                                default:
                                    throw RequestError.UnsupportedAction(action: action)
                                }
                                
                            } catch {
                                print("Error: \(error)")
                            }
                            
                            //
                            var newRequest = RequestItem(id: factor.idHex, label: factor.label, msg: msgRaw)
                            newRequest.requestData = requestData
                            print("Added to newRequest this requestData: \(requestData)")
                            
                            // update status
                            DispatchQueue.main.async {
                                self.requestArray.append(newRequest)
                                self.isRequestAvailable = true
                                print("Added new requestItem to request queue: \(newRequest)")
                            }
                        } // else not <null>
                    } // else not error
                    
                    // dispatchGroup is used to wait for pollServer() to finish before fetching web api
                    //self.dispatchGroup.leave()
                } // self.client.call
                
            } catch {
                print("Error: \(error)")
            }
        } // for factor
        
        print("Polling server END")
    }
    
    // put response to server
    func putServer(id: String, msg: String){
        print("Sending to server START...")
        
        do{
            print("Polling server client.put() to id: \(id)")
            let methods = try client.put(id, msg)
            print("Polling server methods: \(methods)")
            
//            print("Polling server client.call(put)")
//            self.client.call("put", id, msg) { error, value in
//                if let error = error {
//                    print("Put call failed with error:", error)
//                }
//                else {
//                    print("Put call success!")
//                }
//            }
        } catch {
            print("Error: \(error)")
        }
        print("Sending to server END...")
    }
    
    // delete entry in server
    func deleteServer(id: String){
        print("Deleting entry in server START...")
        do{
            print("Polling server client.delete()")
            let methods = try client.delete(id)
            print("Polling server methods: \(methods)")
        } catch {
            print("Error: \(error)")
        }
        print("Deleting entry in server END...")
    }
        
    func performChallengeResponse(requestItem: RequestItem, isApproved: Bool) -> Bool {
        
        guard let requestData = requestItem.requestData else {
            print("Could not find any request for \(requestItem.idHex)")
            print("requestItem: \(requestItem)")
            return false
        }
        guard let factorItem = self.factorDict[requestItem.idHex] else {
            // TODO
            print("Could not find any corresponding factor for \(requestItem.id)")
            return false
        }
        
        var responseHex : String = String(repeating: "00", count: 20) // default to rejected
        if isApproved {
            // compute challenge-response
            responseHex = factorItem.approveChallenge(challengeHex: requestData.challengeHex)
            //item.responseHex = responseHex
        }
        print("Challenge-response responseHex: \(responseHex)")
        
        // format & encrypt response
        let replyTxt = requestData.challengeHex + ":" + responseHex
        var replyEncrypted: String = ""
        do {
            replyEncrypted = try factorItem.encryptRequest(msgPlainTxt: replyTxt)
        } catch {
            // TODO
            print("Failed to encrypt reply: \(error)")
            return false
        }
        // return response
        self.putServer(id: factorItem.idOtherHex, msg: replyEncrypted)
        
        // logs operation
        
        // remove request from server and from request array
        self.deleteServer(id: factorItem.idHex)
        
        // remove from request array
        // update status
        DispatchQueue.main.async {
            if let index = self.requestArray.firstIndex(of: requestItem) {
                print("Size of requestArray before removal: \(self.requestArray.count)")
                self.requestArray.remove(at: index)
                print("Size of requestArray after removal: \(self.requestArray.count)")
            }
            if self.requestArray.count == 0 {
                self.isRequestAvailable = false
            }
        }
        
        print("Button request approved!")
        return true
    }
    
//    func fetchDataFromWeb() async {
//
//        for (index, item) in self.requestArray.enumerated() {
//
//            // for legacy btc transactions, input addresses and amounts must be fetched from explorer
//            if item.requestData?.type == "SIGN_TX" {
//
//                var requestDataTmp = item.requestData as! RequestSignTx
//                // inputs
//                for (inputIndex, input) in requestDataTmp.inputs.enumerated() {
//                    let addr: String
//                    if input.hasPrefix("tx:"){
//                        //TODO: get script from explorer, then compute address
//                        addr = "TODO: newAddress"
//                        requestDataTmp.inputs[inputIndex] = addr
//                    } else {
//                        addr = requestDataTmp.inputs[inputIndex]
//                    }
//                    // amounts
//                    if requestDataTmp.inputAmounts[inputIndex] == nil {
//                        let amount: Double = 0 // todo get from addr from explorer
//                        // update
//                        requestDataTmp.inputAmounts[inputIndex] = amount
//                    }
//                    // DEBUG update
//                    requestDataTmp.inputs[inputIndex] = "DEBUG-DEBUG"
//                    requestDataTmp.inputAmounts[inputIndex] = 666
//                    // ENDBUG
//                }
//                // update requestData
//                print("Start UPDATE DATA")
//                self.requestArray[index].requestData = requestDataTmp
//                print("End UPDATE DATA")
//
//            } // if requestSignTx
//
//        } // for requests
//    }
    
//    @MainActor
//    func executeQuery() async {
//    //func executeQuery() {
//        print("in executeQuery START")
//        self.dispatchGroup.enter()
//        dispatchGroup.notify(queue: DispatchQueue.global()){
//            Task {
//                //await self.fetchDataFromWeb()
//            }
//        }
//    }
    
//    // decrypt msg
//    func decryptRequest(msgRaw: String, key: [UInt8]) throws -> [String:String] {
//        
//        // base64 decode
//        //let msgEncrypted = String.fromBase64(msgRaw)
//        guard let msgDecoded = Data.fromBase64(msgRaw) else {
//            print("failed to decode base64 msg")
//            //todo: throw
//            //return ""
//            throw RequestError.Base64DecodingError
//        }
//        
//        // decrypt message & remove padding
//        let iv = Array(msgDecoded[0..<16])
//        let msgEncrypted = Array(msgDecoded[16...])
//        let msgDecrypted = try CryptoSwift.AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7).decrypt(msgEncrypted)
//        
//        // decode json
//        guard let msgJsonString = String(bytes: msgDecrypted, encoding: .utf8) else {
//            print("not a valid UTF-8 sequence")
//            // todo: throw
//            throw RequestError.Utf8DecodingError
//        }
//        print("request msgJsonString: \(msgJsonString)")
//        
//        let msgJson = try JSONSerialization.jsonObject(with: Data(msgDecrypted), options: [])
//        // todo: use custom structure?
//        
//        print("request type of msgJson: \(type(of: msgJson))")
//        print("request msgJson: \(msgJson)")
//        return msgJson as! [String:String]
//    }
    
//    // encrypt response
//    func encryptRequest(msgPlainTxt: String, key: [UInt8]) throws -> String {
//        let iv: [UInt8]
//        do {
//            iv = try generateRandomBytes(count: 16)
//        } catch {
//            iv = [UInt8]((0 ..< 16).map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
//        }
//        let msgPlainBytes = Array(msgPlainTxt.utf8)
//        var msgEncryptedBytes = try CryptoSwift.AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7).encrypt(msgPlainBytes)
//        msgEncryptedBytes = iv + msgEncryptedBytes
//        let msgEncryptedBase64 = msgEncryptedBytes.toBase64()
//        print("Satochip: msgEncryptedBase64: " + msgEncryptedBase64)
//        
//        return msgEncryptedBase64
//    }
    
    // parse request
    // bct, eth, bch, ltc, ...
//    func requestResetSeed(requestJson: [String:String]) throws -> RequestResetSeed {
//        guard let authentikeyx = requestJson["authentikeyx"] else {
//            throw RequestError.RequestWrongFormat(details: "missing authentikeyx in resetSeed")
//        }
//        
//        let challengeHex = authentikeyx + String(repeating: "FF", count: 32)
//        let request = RequestResetSeed(challengeHex: challengeHex, authentikeyx: authentikeyx)
//        
//        return request
//    }
    
//    func requestSignMsg(requestJson: [String:String]) throws -> RequestSignMsg {
//        guard let msg: String = requestJson["msg"] else {
//            throw RequestError.RequestWrongFormat(details: "missing msg in requestSignMsg")
//        }
//        let altcoin: String = requestJson["alt"] ?? "Bitcoin"
//        let headersize = [UInt8(altcoin.bytes.count + 17)]
//        let msgBytes = Array(msg.utf8)
//        var msgPaddedBytes : [UInt8] = headersize
//        msgPaddedBytes = msgPaddedBytes + Array(altcoin.utf8)
//        msgPaddedBytes = msgPaddedBytes + Array(" Signed Message:\n".utf8)
//        msgPaddedBytes = msgPaddedBytes + VarInt(msgBytes.count).data
//        msgPaddedBytes = msgPaddedBytes + msgBytes
//
//        let msgHashHex = Digest.sha256(msgPaddedBytes).bytesToHex
//        let challengeHex = msgHashHex + String(repeating: "BB", count: 32)
//
//        let request = RequestSignMsg(challengeHex: challengeHex, msg: msg, msgHashHex: msgHashHex)
//        return request
//    }
    
    
//    func generateRandomBytes(count: Int) throws -> [UInt8] {
//        var bytes = [UInt8](repeating: 0, count: count)
//        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
//
//        guard result == errSecSuccess else {
//            print("Problem generating random bytes")
//            throw AppError.RandomGeneratorError
//        }
//
//        return bytes //Data(bytes).base64EncodedString()
//    }
//    
    
}
