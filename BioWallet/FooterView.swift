//
//  FooterView.swift
//  BioWallet
//
//  Created by Kumar Nilay on 05/06/24.
//

import Foundation

import SwiftUI

/**
 Image(systemName: "dollarsign.circle")
     .resizable()
     .frame(width: 30, height: 30)
 */
struct FooterView: View {
    var body: some View {
            HStack(spacing: 20) {
                Spacer()
                Button(action: {
                    // Action for Send
                }) {
                    VStack {
                        Image(systemName: "arrow.up.right")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                    }
                }
                Spacer()
                Button(action: {
                    // Action for Swap
                }) {
                    VStack {
                        Image(systemName: "arrow.right.arrow.left")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                    }
                }
                Spacer()
                Button(action: {
                    // Action for Bridge
                }) {
                    VStack {
                        Image(systemName: "arrow.triangle.swap")                             
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                    }
                }
                Spacer()
                Button(action: {
                    // Action for Portfolio
                }) {
                    VStack {
                        Image(systemName: "globe")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
                    }
                }
                Spacer()
            }
            .padding()
            .background(Color.black)
            .opacity(0.8)
        }
}

struct FooterView_Previews: PreviewProvider {
    static var previews: some View {
        FooterView()
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
