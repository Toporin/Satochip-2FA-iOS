//
//  ContentView.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 13/04/2023.
//

import SwiftUI

struct ContentView: View {
    
    @StateObject var dataStore = DataStore()
//    @State var currentDate = Date.now
//    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        
        ZStack{
            
//            Text("\(currentDate)")
//                .onReceive(timer) { input in
//                    currentDate = input
//                    dataStore.pollServer()
//                }
            
            TabView {
                RequestsView()
                    .tabItem {
                        Label("Requests", systemImage: "list.dash")
                    }
                
                LogsView()
                    .tabItem {
                        Label("Logs", systemImage: "square.and.pencil")
                    }
                
                FactorsView()
                    .tabItem {
                        Label("Factors", systemImage: "square.and.pencil")
                    }
            } // TabView
            .environmentObject(dataStore)
            
        }// ZStack
        //.environmentObject(dataStore)
    }// body
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
