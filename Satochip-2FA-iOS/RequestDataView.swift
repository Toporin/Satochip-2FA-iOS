//
//  RequestDataView.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 23/04/2023.
//

import SwiftUI

struct RequestDataView: View {
    
    public var requestData: (any RequestData)?
    
    var body: some View {
        VStack{
            
            if let requestData {
                Text("Request type: \(requestData.type)")
                
                if requestData.type == "SIGN_MSG" {
                    Text((requestData as! RequestSignMsg).msg)
                } else if requestData.type == "SIGN_TX" {
                    //Text((requestData as! RequestSignTx).txParsed)
                    RequestSignTxView(requestSignTx: requestData as! RequestSignTx)
                } else if requestData.type == "SIGN_TX_HASH" {
                    //Text((requestData as! RequestSignTx).txParsed)
                    RequestSignTxHashView(requestSignTxHash: requestData as! RequestSignTxHash)
                } else if requestData.type == "SIGN_MSG_HASH"{
                    Text((requestData as! RequestSignMsgHash).msg)
                } else {
                    Text("Unsupported requestData")
                }
                
                if (requestData.warningCode.rawValue != 0){
                    switch (requestData.warningCode){
                    default:
                        Text("Warning code: \(requestData.warningCode.rawValue)")
                    }
                }
                
            } else {
                Text("This request is null (should not happen!)")
            }
            
            
        }// VStack
        
    }
}

struct RequestDataView_Previews: PreviewProvider {
    static var previews: some View {
        RequestDataView()
    }
}
