//
//  Navigation.swift
//  Bio-Wallet
//
//  Created by Kumar Nilay on 30/05/24.
//

import Foundation
import SwiftUI

struct NavigationLazyView<Content: View>: View {
    let build: () -> Content
    var body: some View {
        build()
    }
}

extension View {
    func navigate<Content: View>(to destination: Content, when binding: Binding<Bool>) -> some View {
        NavigationView {
            ZStack {
                self
                NavigationLink(destination: NavigationLazyView { destination }, isActive: binding) {
                    EmptyView()
                }
            }
        }
    }
}
