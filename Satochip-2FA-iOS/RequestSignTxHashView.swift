//
//  RequestSignTxHashView.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 05/05/2023.
//

import SwiftUI
import SwiftCryptoTools
import BigInt

struct RequestSignTxHashView: View {
    
    public var requestSignTxHash: RequestSignTxHash
    
    var body: some View {
        VStack{
            Group {
                Text("Coin: \(requestSignTxHash.txChainName ?? "unknown")")
                
                if let txType = requestSignTxHash.txType {
                    switch(txType){
                    case TxType.legacy:
                        Text("Legacy transaction")
                    case TxType.eip1559:
                        Text("Eip1559 transaction")
                    }
                }
                if let txFrom = requestSignTxHash.txFrom {
                    Text("From: 0x\(txFrom)")
                } else {
                    Text("From: (not provided)")
                }
                if let txTo = requestSignTxHash.txTo {
                    Text("To: 0x\(txTo)")
                }
            }
            Group {
//                if let txValue = requestSignTxHash.txValue {
//                    Text("Value: \(String(txValue))")
//                }
                showTxValue()
                
                if let txNonce = requestSignTxHash.txNonce {
                    Text("Nonce: \(txNonce)")
                }
                // legacy
                if let txGasPrice = requestSignTxHash.txGasPrice,
                    let txGasLimit = requestSignTxHash.txGasLimit {
                    Text("GasPrice: \(String(txGasPrice))")
                    Text("GasLimit: \(String(txGasLimit))")
                    Text("Max fee: \(String(txGasPrice * txGasLimit))")
                }
//                if let txGasLimit = requestSignTxHash.txGasLimit {
//                    Text("GasLimit: \(String(txGasLimit))")
//                }
                // eip1559
                if let txFeePerGas = requestSignTxHash.txFeePerGas {
                    Text("FeePerGas: \(String(txFeePerGas))")
                }
                if let txPriorityFeePerGas = requestSignTxHash.txPriorityFeePerGas {
                    Text("PriorityFeePerGas: \(String(txPriorityFeePerGas))")
                }
                
                if let txData = requestSignTxHash.txData {
                    Text("Data: 0x\(txData)")
                }
                
                if requestSignTxHash.warningCode != WarningCode.Ok {
                    Text("WARNING: \(requestSignTxHash.warningCode.rawValue)")
                }
            }
        } // VStack
    } // View
    
    func showTxValue() -> Text {
        
        if let txValue = requestSignTxHash.txValue {
            
            let txDecimals = requestSignTxHash.txChainDecimals ?? 0
            let valueBig = Double(txValue)/pow(10, Double(txDecimals))
            let valueString = String(valueBig)
            
            let chainSymbol: String
            if requestSignTxHash.txChainid == nil {
                chainSymbol = "unknown chain id"
            } else {
                chainSymbol = requestSignTxHash.txChainSymbol ?? "Unsupported chain id: \(requestSignTxHash.txChainid)"
            }
            return Text("Value: \(valueString) \(chainSymbol)")
        } else{
            return Text("Value: unknown")
        }
    }
    
} // RequestSignTxHashView
    

struct RequestSignTxHashView_Previews: PreviewProvider {
    static var previews: some View {
        //RequestSignTxView()
        Text("preview")
    }
}

