//
//  RequestSignTxHash.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 11/05/2023.
//

import Foundation
import CryptoSwift
import SwiftCryptoTools
import BigInt

public enum TxType: Int {
    case legacy = 0
    case eip1559 = 2
}

public struct RequestSignTxHash: RequestData {
    
    public let type = "SIGN_TX_HASH"
    public var challengeHex: String
    public var warningCode = WarningCode.Ok // code 0 = no issue
    //public var responseHex = String(repeating: "00", count: 20) // reject by default
    
    public var id = UUID()
    public var requestJson: [String:AnyHashable]
    public var txParsed = ""
    //public var txType: String = ""
    //public var coinObject: Bitcoin
    
//    public var txHashHexProvided: String = ""
//    public var txHashHexComputed: String = ""
    
    // eth
    public var txType: TxType? = nil // version
    public var txFrom: String? = nil
    
    // legacy
    public var txNonce: Int? = nil
    public var txGasPrice: BigUInt? = nil
    public var txGasLimit: BigUInt? = nil
    public var txTo: String? = nil
    public var txValue: BigUInt? = nil
    public var txData: String? = nil
    public var txV: Int? = nil
    public var txR: Int? = nil
    public var txS: Int? = nil
    
    // eip1559
    public var txChainid: Int? = nil
    public var txPriorityFeePerGas: BigUInt? = nil
    public var txFeePerGas: BigUInt? = nil
    public var txAccessList: String? = nil // todo
    
    // blockchain info default values
    public var txChainName: String?
    public var txChainSymbol: String?
    public var txChainDecimals: Int?
    
    public func hash(into hasher: inout Hasher) {
        return hasher.combine(self.id.uuidString)
    }
    
    static public func ==(lhs: RequestSignTxHash, rhs: RequestSignTxHash) -> Bool {
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
        
        guard let txHex = requestJson["tx"] as? String else {
            throw RequestError.RequestWrongFormat(details: "missing txInput (tx) property")
        }
        guard let hashHex = requestJson["hash"] as? String else {
            throw RequestError.RequestWrongFormat(details: "missing txInput (tx) property")
        }
        self.txChainid = requestJson["chainId"] as? Int ?? nil
        self.txFrom = requestJson["from"] as? String ?? "(not provided)"
        
        let txBytes = txHex.hexToBytes
        
        // parse eth tx type
        let txFirstByte = txBytes[0]
        if txFirstByte <= 0xfe && txFirstByte >= 0xc0 {
            self.txType = TxType.legacy
            
            let txRlp = try RLP.decode(input: Data(txBytes))
            print("txRlp = \(txRlp)")
            let txRlpList = try txRlp.listValue()
            print("txRlp.listValue: \(txRlpList)")
            print("txRlp.listValue.count: \(txRlpList.count)")
            //count should be 9
            for (index, item) in txRlpList.enumerated(){
                print("index: \(index)")
                print("item(hex): \(item.dataValue.hexString)")
                do {
                    print("item(string): \(try item.stringValue())")
                } catch {
                    print(error)
                }
            }
//            https://github.com/ethereum/EIPs/blob/master/EIPS/eip-1559.md
//            signer_nonce: int = 0
//            gas_price: int = 0
//            gas_limit: int = 0
//            destination: int = 0
//            amount: int = 0
//            payload: bytes = bytes()
//            v: int = 0
//            r: int = 0
//            s: int = 0
            self.txNonce = try txRlpList[0].intValue()
            print("txNonce: \(txNonce)")
            self.txGasPrice = try txRlpList[1].bigIntValue()
            print("txGasPrice: \(txGasPrice)")
            self.txGasLimit = try txRlpList[2].bigIntValue()
            print("txGasLimit: \(txGasLimit)")
            self.txTo = txRlpList[3].dataValue.hexString
            print("txTo: \(txTo)")
            self.txValue = try txRlpList[4].bigIntValue()
            print("txValue: \(txValue)")
            self.txData = txRlpList[5].dataValue.hexString
            print("txData: \(txData)")
            self.txV = try txRlpList[6].intValue()
            print("txV: \(txV)")
            self.txR = try txRlpList[7].intValue()
            print("txR: \(txR)")
            self.txS = try txRlpList[8].intValue()
            print("txS: \(txS)")
            
            if self.txChainid == nil {
                self.txChainid = self.txV
            }
            
            // reencode with chainId (EIP155)
            // TODO?
//            let encoded = RLP.encode([
//                self.txNonce,
//                self.txGasPrice,
//                self.txGasLimit,
//                self.txTo?.hexToBytes,
//                self.txValue,
//                self.txData?.hexToBytes,
//                self.txV,
//                self.txR,
//                self.txS])
//            print("encoded: \(encoded.hexString)") // patch: wrong encoding!
        } else if txFirstByte == 0x2 {
            self.txType = TxType.eip1559
            
            let txBytesTrimmed = txBytes.dropFirst(1) //
            let txRlp = try RLP.decode(input: Data(txBytesTrimmed))
            print("txRlp = \(txRlp)")
            let txRlpList = try txRlp.listValue()
            print("txRlp.listValue: \(txRlpList)")
            print("txRlp.listValue.count: \(txRlpList.count)")
            // count should be 9??
            for (index, item) in txRlpList.enumerated(){
                print("index: \(index)")
                print("item(hex): \(item.dataValue.hexString)")
                do {
                    print("item(string): \(try item.stringValue())")
                } catch {
                    print(error)
                }
            }
            
//            chain_id: int = 0
//            signer_nonce: int = 0
//            max_priority_fee_per_gas: int = 0
//            max_fee_per_gas: int = 0
//            gas_limit: int = 0
//            destination: int = 0
//            amount: int = 0
//            payload: bytes = bytes()
//            access_list: List[Tuple[int, List[int]]] = field(default_factory=list)
//            signature_y_parity: bool = False
//            signature_r: int = 0
//            signature_s: int = 0
            self.txChainid = try txRlpList[0].intValue()
            print("txChainid: \(txChainid)")
            self.txNonce = try txRlpList[1].intValue()
            print("txNonce: \(txNonce)")
            self.txPriorityFeePerGas = try txRlpList[2].bigIntValue()
            print("txPriorityFeePerGas: \(txPriorityFeePerGas)")
            self.txFeePerGas = try txRlpList[3].bigIntValue()
            print("txFeePerGas: \(txFeePerGas)")
            //self.txGasPrice = try txRlpList[1].bigIntValue()
            //print("txGasPrice: \(txGasPrice)")
            self.txGasLimit = try txRlpList[4].bigIntValue()
            print("txGasLimit: \(txGasLimit)")
            self.txTo = txRlpList[5].dataValue.hexString
            print("txTo: \(txTo)")
            self.txValue = try txRlpList[6].bigIntValue()
            print("txValue: \(txValue)")
            self.txData = txRlpList[7].dataValue.hexString
            print("txData: \(txData)")
            
            self.txAccessList = txRlpList[8].dataValue.hexString
            print("txAccessList: \(txAccessList)")
            
        } else {
            throw RequestError.RequestWrongFormat(details: "Unsupported Ethereum transaction type: \(txFirstByte)")
        }
        
        let keccak = SHA3(variant: .keccak256)
        let txHashBytes = keccak.calculate(for: txBytes)
        let txHashHex = txHashBytes.bytesToHex
        
        if txHashHex != hashHex.uppercased() {
            self.warningCode = WarningCode.HashMismatch // todo (expected, computed)
        }
        self.challengeHex = hashHex + String(repeating: "CC", count: 32)
        
        // get blockchain from txChainId + name, symbol & decimals
        if let chainid = self.txChainid,
           //let fileURL = Bundle.main.url(forResource: "eip155-\(chainid)", withExtension: "json", subdirectory: "EIP155"){
           let fileURL = Bundle.main.url(forResource: "eip155-\(chainid)", withExtension: "json"){
            do {
                let data = try Data(contentsOf: fileURL)
                guard let chainDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String:Any] else {
                    print("chainDict is nil")
                    throw RequestError.JsonError
                }
                guard let nativeCurrencyDict = chainDict["nativeCurrency"] as? [String:Any] else {
                    print("nativeCurrencyDict is nil")
                    throw RequestError.JsonError
                }
                self.txChainName = nativeCurrencyDict["name"] as? String
                print("self.txChainName: \(self.txChainName)")
                self.txChainSymbol = nativeCurrencyDict["symbol"] as? String
                print("self.txChainSymbol: \(self.txChainSymbol)")
                self.txChainDecimals = nativeCurrencyDict["decimals"] as? Int
                print("self.txChainDecimals: \(self.txChainDecimals)")
            } catch {
                print("failed to get chain info for chain id: \(self.txChainid)")
            }
        } else {
            print("failed to get chain info for chain id \(self.txChainid) - folder issue?")
            //print("fileUrl: \(fileURL)")
        }
            
    }
}
