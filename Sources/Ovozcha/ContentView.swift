//
//  ContentView.swift
//  Ovozcha
//
//  Created by Sunnatbek on 20/09/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                #if !SKIP
                .imageScale(.large)
                #endif
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
