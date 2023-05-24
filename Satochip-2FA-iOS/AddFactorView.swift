//
//  AddFactorView.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 14/04/2023.
//

import SwiftUI

struct AddFactorView: View {
    
    public var scannedCode: String?
    @EnvironmentObject var dataStore: DataStore
    @State public var secretHex: String = ""
    @State public var label: String = ""
    
    
    var body: some View {
        Text("Scanned Code: \(scannedCode ?? "nil")")
        
        TextField("Enter secret label", text: $label)
        
        if scannedCode == nil {
            TextField("Enter secret hex", text: $secretHex)
        }
        
        Button(action: {
            
            var secret: String = ""
            if let scannedCode = scannedCode {
                secret = scannedCode
            } else {
                secret = secretHex
            }
            // todo: check secret
            
            dataStore.addFactor(secretHex: secret, label: label)
            print("Button add factor")}) {
                Text("Add factor!")
            }
        
    }
}

struct AddFactorView_Previews: PreviewProvider {
    static var previews: some View {
        AddFactorView(scannedCode: "debug")
        //Text("Debug")
    }
}
