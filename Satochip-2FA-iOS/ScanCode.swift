//
//  ScanCode.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 13/04/2023.
//

import SwiftUI
import CodeScanner

struct ScanCode: View {
    
    @EnvironmentObject var dataStore: DataStore
    @State private var isShowingScanner = true
    @State private var scannedCode: String?
    @State private var isScannedCode = false
    
    func handleScan(result: Result<ScanResult, ScanError>) {
        isShowingScanner = false
       
        switch result {
        case .success(let result):
            //let details = result.string
            scannedCode = result.string
            print("Scanning successful: \(scannedCode)")
            //dataStore.addFactor(secretHex: details)
            isScannedCode = true
            
        case .failure(let error):
            print("Scanning failed: \(error.localizedDescription)")
            scannedCode = "error"
            isScannedCode = true
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Hello, Scan \(scannedCode ?? "nil")!")
                
                if let code = scannedCode {
                    Text("Found qr code \(code)")
                    //NavigationLink("Next page", destination: AddFactorView(scannedCode: code), isActive: .constant(true)).hidden()
                }
                
                CodeScannerView(codeTypes: [.qr], simulatedData: "", completion: handleScan)
            }
            .background(
                NavigationLink(destination: AddFactorView(scannedCode: scannedCode ?? ""), isActive: $isScannedCode){EmptyView()}
            )
        } // NavigationView
    }
}

struct ScanCode_Previews: PreviewProvider {
    static var previews: some View {
        ScanCode()
    }
}
