//
//  FactorsView.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 13/04/2023.
//

import SwiftUI

struct FactorsView: View {
    
    @EnvironmentObject var dataStore: DataStore
    @State var addFactor = false
    @State var addFactorRequest = false
    @State var addFactorAction = ""
    
    var body: some View {
        NavigationView {
            VStack{
                Text("My Factors")
                
                Button(action: {
                    addFactor = true
                    print("Button Action for scanCode")}) {
                        Text("Scan QR Code!")
                    }
                    .buttonStyle(.borderless)
                
                // for each factor
                List {
                    //ForEach(dataStore.factorArray, id: \.self) { item in
                    ForEach(Array(dataStore.factorDict.keys), id: \.self) { idHex in
                        Text(dataStore.factorDict[idHex]?.label ?? "")
                        Text(idHex)
                        //Text(item.label)
                        //Text(item.idHex)
                    }
                }
                
            }
            .sheet(isPresented: $addFactor) {
                VStack{
                    Button(action: {
                        addFactor = false
                        addFactorAction = "ScanCode"
                        addFactorRequest = true
                        print("Button Action for scanCode")}) {
                            Text("Scan QR Code!")
                        }
                    Button(action: {
                        addFactor = false
                        addFactorAction = "EnterCode"
                        addFactorRequest = true
                        print("Button Action for manually enter code")}) {
                            Text("Enter secret manually!")
                        }
                }
            }// sheet
            .background(
                //NavigationLink(destination: ScanCode(), isActive: $addFactorRequest){EmptyView()}
                NavigationLink(destination: getDestination(operation: addFactorAction), isActive: $addFactorRequest){EmptyView()}
            )
        } // NavigationView
    }// body
    
    func getDestination(operation: String) -> AnyView {
        print("getDestination operation: \(operation)")
        if operation == "ScanCode"{
            return AnyView(ScanCode())
        } else{ // if operation == "EnterCode"
            return AnyView(AddFactorView(scannedCode: nil))
        }
    }
    
}

struct FactorsViewOld_Previews: PreviewProvider {
    static var previews: some View {
        FactorsView()
    }
}
