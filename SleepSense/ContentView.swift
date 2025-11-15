//
//  ContentView.swift
//  SleepSense
//
//  Created by Rushan Chanuka on 2025-11-15.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            DashboardView()
                .toolbar {
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
