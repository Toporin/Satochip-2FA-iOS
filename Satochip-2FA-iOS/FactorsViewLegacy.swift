//
//  FactorsView.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 13/04/2023.
//

import SwiftUI
import CodeScanner

struct FactorsViewLegacy: View {
    
    @EnvironmentObject var dataStore: DataStore
    @State private var isPresentingScanner = false
    @State private var scannedCode: String?
    
    var body: some View {
        VStack(spacing: 10) {
            if let code = scannedCode {
                Text("Found qr code \(code)")
                NavigationLink("Next page", destination: AddFactorView(scannedCode: code), isActive: .constant(true)).hidden()
            }

            Button("Scan Code") {
                isPresentingScanner = true
            }

            Text("Scan a QR code to begin")
        }
        .sheet(isPresented: $isPresentingScanner) {
            CodeScannerView(codeTypes: [.qr]) { response in
                if case let .success(result) = response {
                    scannedCode = result.string
                    isPresentingScanner = false
                }
            }
        }
    }
}

struct FactorsView_Previews: PreviewProvider {
    static var previews: some View {
        FactorsView()
    }
}
