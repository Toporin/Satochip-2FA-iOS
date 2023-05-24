//
//  RequestSignTxView.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 05/05/2023.
//

import SwiftUI
import SwiftCryptoTools

struct RequestSignTxView: View {
    
    @State public var requestSignTx: RequestSignTx
    
    var body: some View {
        //Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
        VStack{
            Text("Coin: \(requestSignTx.coinObject.displayName)")
            Text("Inputs: ")
            ForEach(Array(requestSignTx.inputs.enumerated()), id: \.element) { index, element in
                Text("\t \(requestSignTx.inputs[index])")
                //Text("\t \(requestSignTx.inputAmounts[index] ?? getBalance(addr: requestSignTx.inputs[index]))")
                Text("\t \(requestSignTx.inputAmounts[index] ?? 0)")
            }
            Text("Outputs: ")
            ForEach(Array(requestSignTx.outputs.enumerated()), id: \.element) { index, element in
                Text("\t \(requestSignTx.outputs[index])")
                Text("\t \(requestSignTx.outputAmounts[index] ?? 0)")
            }
            Text("Fees: \(requestSignTx.fee ?? -1)")
        }
        .task {
            self.requestSignTx = await fetchMissingDataFromWeb(request: requestSignTx)
        }
    }
    
    func getBalance(addr: String) async -> UInt64 {
        
        //let coin = Bitcoin(isTestnet: false, apiKeys: [String:String]()) // todo
        let balance: Double
        do{
            balance = try await requestSignTx.coinObject.getBalance(addr: addr)
        } catch {
            balance = 0
        }
        return UInt64(balance)
    }
    
    func fetchMissingDataFromWeb(request: RequestSignTx) async -> RequestSignTx {
        
        var requestCopy = request
        // for every input
        for (index, input) in requestCopy.inputs.enumerated() {
            if input.hasPrefix("tx:"){
                // get script from explorer(txHash, index), then compute address
                do {
                    let components = input.components(separatedBy: [":"])
                    let txHash = components[1]
                    guard let id = Int(components[2]) else { throw RequestError.StringDecodingError}
                    guard let result = try await requestCopy.coinObject.blockExplorer?.getTxInfo(txHash: txHash, index: id) else {
                        throw RequestError.StringDecodingError
                    }
                    let addr = requestCopy.coinObject.scriptToAddr(script: result.script.hexToBytes)
                    requestCopy.inputs[index] = addr
                    requestCopy.inputAmounts[index] = Double(result.value)
                    
                } catch {
                    requestCopy.inputs[index] = input
                    requestCopy.inputAmounts[index] = nil
                }
            } else {
                let addr = requestCopy.inputs[index]
                if requestCopy.inputAmounts[index] == nil {
                    let amount: Double?
                    do {
                        amount =  100_000_000 * (try await requestCopy.coinObject.getBalance(addr: addr)) // value from blockchain is in BTC, convert to sats
                    } catch {
                        amount = nil
                    }
                    // update
                    requestCopy.inputAmounts[index] = amount
                }
            } // else
        } // for inputs
        return requestCopy
    }
    
}

struct RequestSignTxView_Previews: PreviewProvider {
    static var previews: some View {
        //RequestSignTxView()
        Text("preview")
    }
}
