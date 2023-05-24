//
//  RequestsView.swift
//  Satochip-2FA-iOS
//
//  Created by Satochip on 13/04/2023.
//

import SwiftUI

struct RequestsView: View {
    
    @EnvironmentObject var dataStore: DataStore
    @State var currentDate = Date.now
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationView {
            VStack{
                Text("My requests")
                
                Text("\(currentDate)")
                    .onReceive(timer) { input in
                        currentDate = input
                        if !dataStore.isRequestAvailable {
                            dataStore.pollServer()
//                            Task {
//                                dataStore.pollServer()
//                                await dataStore.executeQuery()
//                            }
                        }
                    }
                
                // for each factor
                List {
                    ForEach(dataStore.requestArray, id: \.id) { item in
                        VStack{
                            Text("id: \(item.id)") // debug
                            Text(item.idHex)
                            Text(item.label)
                            //Text(item.msgRaw)
                            // parsed data according to request type
                            RequestDataView(requestData: item.requestData)
                            
                            // buttons approve/reject
                            HStack {
                                Spacer()
                                Button(action: {
                                    
                                    let isSuccess = dataStore.performChallengeResponse(requestItem: item, isApproved: true)
                                    print("performChallengeResponse isSuccess: \(isSuccess)")
                                    
//                                    // compute challenge-response
//                                    guard let factorItem = dataStore.factorDict[item.id] else {
//                                        // TODO
//                                        print("Could not find any corresponding factor for \(item.id)")
//                                        return
//                                    }
//                                    guard let requestData = item.requestData else {
//                                        print("Could not find any request for \(item.id)")
//                                        return
//                                    }
//                                    let responseHex = factorItem.approveChallenge(challengeHex: requestData.challengeHex)
//                                    //item.responseHex = responseHex
//
//                                    // format & encrypt response
//                                    let replyTxt = requestData.challengeHex + ":" + responseHex
//                                    var replyEncrypted: String = ""
//                                    do {
//                                        replyEncrypted = try factorItem.encryptRequest(msgPlainTxt: replyTxt)
//                                    } catch {
//                                        // TODO
//                                        print("Failed to encrypt reply: \(error)")
//                                        return
//                                    }
//                                    // return response
//                                    dataStore.putServer(id: factorItem.idOtherHex, msg: replyEncrypted)
//
//                                    // logs operation
//
//                                    // remove request from server and from request array
//
                                    
                                    print("Button request approved!")})
                                {
                                    HStack{
                                        Image(systemName: "checkmark.seal")
                                            //.foregroundColor(Color("Color_foreground"))
                                        Text("Approve request")
                                    }
                                }
//                                    .padding()
//                                    .foregroundColor(Color("Color_foreground"))
//                                    .background(Color.gray)
//                                    .cornerRadius(.infinity)
                                .buttonStyle(.borderless)
                                
                                Spacer()
                                Button(action: {
                                    
                                    let isSuccess = dataStore.performChallengeResponse(requestItem: item, isApproved: false)
                                    
                                    print("Button request rejected!")})
                                {
                                    HStack{
                                        Image(systemName: "xmark.seal")
                                                //.foregroundColor(Color("Color_foreground"))
                                        Text("Reject request")
                                    }
                                }
//                                    .padding()
//                                    .foregroundColor(Color("Color_foreground"))
//                                    .background(Color.gray)
//                                    .cornerRadius(.infinity)
                                .buttonStyle(.borderless)
                                
                                Spacer()
                            } // Hstack
                            
                            
                        } // VStack
                    } // ForEach
                } // List
                
            }// VStack
            
        } // NavigationView
        
    } // View
    
}// struct

struct RequestsView_Previews: PreviewProvider {
    static var previews: some View {
        RequestsView()
    }
}
