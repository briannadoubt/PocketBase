//
//  ContentView.swift
//  PocketBaseDemo
//
//  Created by Brianna Zamora on 8/7/24.
//

import PocketBaseUI
import SwiftUI
import os

struct ContentView: View {
    @Environment(\.pocketbase) private var pocketbase
    
    @RealtimeQuery<Rawr>(sort: [.init(\.field)]) private var rawrs
    
    static let logger = Logger(
        subsystem: "PocketBaseDemo",
        category: "ContentView"
    )
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(rawrs) { rawr in
                    RawrView(rawr: rawr)
                }
                .onDelete(perform: delete)
            }
            .refreshable {
                await $rawrs.start()
            }
            .navigationTitle("Rawrs")
            .toolbar {
                Button("Logout", role: .destructive, action: logout)
                Button("New", systemImage: "plus", action: new)
            }
        }
        .task {
            await $rawrs.start()
        }
    }
    
    func logout() {
        Task {
            await pocketbase.collection(User.self).logout()
        }
    }
    
    func new() {
        Task {
            do {
                try await pocketbase.collection(Rawr.self).create(Rawr(field: ""))
            } catch {
                Self.logger.error("Failed to create record with error \(error)")
            }
        }
    }
    
    func delete(_ index: IndexSet) {
        let rawrs = index.map { self.rawrs[$0] }
        Task {
            for rawr in rawrs {
                do {
                    try await pocketbase.collection(Rawr.self).delete(rawr)
                } catch {
                    Self.logger.error("Failed to deleted record with error \(error)")
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .pocketbase(.localhost)
}
