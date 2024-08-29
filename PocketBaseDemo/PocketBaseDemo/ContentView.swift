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
    
    @RealtimeQuery<Rawr>(
        sort: [.init(\.field)]
    ) private var rawrs
    
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
                Button("Logout", role: .destructive) {
                    pocketbase.collection(User.self).logout()
                }
                Button("New", systemImage: "plus") {
                    Task {
                        do {
                            try await pocketbase.collection(Rawr.self).create(Rawr(field: ""))
                        } catch {
                            Self.logger.error("Failed to create record with error \(error)")
                        }
                    }
                }
            }
        }
        .task {
            await $rawrs.start()
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

struct RawrView: View {
    @Environment(\.pocketbase) private var pocketbase

    private let rawr: Rawr
    
    @State private var isPresentingEditAlert: Bool = false
    @State private var editText: String = ""

    static let logger = Logger(
        subsystem: "PocketBaseDemo",
        category: "ContentView"
    )

    init(rawr: Rawr) {
        self.rawr = rawr
    }
    
    var body: some View {
        Button(rawr.field) {
            editText = rawr.field
            isPresentingEditAlert = true
        }
        .foregroundStyle(.primary)
        .alert("Update Rawr", isPresented: $isPresentingEditAlert) {
            TextField("Update Rawr", text: $editText)
                .onSubmit {
                    save()
                }
            Button("Cancel", role: .cancel) {
                isPresentingEditAlert = false
            }
            Button("Save") {
                save()
            }
        }
    }
    
    private func save() {
        var rawr = self.rawr
        rawr.field = editText
        Task {
            do {
                try await pocketbase.collection(Rawr.self).update(rawr)
                isPresentingEditAlert = false
            } catch {
                Self.logger.error("Failed to update rawr with error: \(error)")
            }
        }
    }
}

#Preview {
    ContentView()
        .pocketbase(.localhost)
}
