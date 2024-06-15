//
//  FooterView.swift
//  BioWallet
//
//  Created by Kumar Nilay on 05/06/24.
//

import Foundation

import SwiftUI

struct FooterView: View {
    @Binding var selectedTab: Tab

    var body: some View {
        HStack {
            Button(action: {
                selectedTab = .transfer
            }) {
                VStack {
                    Image(systemName: "dollarsign.circle")
                        .font(.largeTitle)
                    Text("Transfer")
                        .font(.caption)
                }
            }
            Spacer()
//            Button(action: {
//                selectedTab = .swap
//            }) {
//                VStack {
//                    Image(systemName: "arrow.right.arrow.left.circle")
//                        .font(.largeTitle)
//                    Text("Swap")
//                        .font(.caption)
//                }
//            }
//            Spacer()
            Button(action: {
                selectedTab = .bridge
            }) {
                VStack {
                    Image(systemName: "bolt.horizontal.circle")
                        .font(.largeTitle)
                    Text("Bridge")
                        .font(.caption)
                }
            }
            Spacer()
            Button(action: {
                selectedTab = .network
            }) {
                VStack {
                    Image(systemName: "globe")
                        .font(.largeTitle)
                    Text("Network")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
    }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView(selectedTab: .constant(.transfer))
    }
}
/**
 var body: some View {
     HStack {
         Spacer()
         Button(action: {
             // Action for dollar button
         }) {
             Image(systemName: "dollarsign.circle")
                 .resizable()
                 .frame(width: 30, height: 30)
         }
         Spacer()
         Button(action: {
             // Action for grid button
         }) {
             Image(systemName: "square.grid.2x2")
                 .resizable()
                 .frame(width: 30, height: 30)
         }
         Spacer()
         Button(action: {
             // Action for arrows button
         }) {
             Image(systemName: "arrow.up.right")
                 .resizable()
                 .frame(width: 30, height: 30)
         }
         Spacer()
         Button(action: {
             // Action for lightning bolt button
         }) {
             Image(systemName: "bolt")
                 .resizable()
                 .frame(width: 30, height: 30)
         }
         Spacer()
         Button(action: {
             // Action for globe button
         }) {
             Image(systemName: "globe")
                 .resizable()
                 .frame(width: 30, height: 30)
         }
         Spacer()
     }
     .padding()
     .background(Color.black.opacity(0.8))
     .foregroundColor(.white)
 }
 */
