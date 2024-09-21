//
//  RawrView.swift
//  PocketBaseDemo
//
//  Created by Brianna Zamora on 9/18/24.
//

import PocketBase
import SwiftUI
import os

struct RawrView: View {
    @Environment(\.pocketbase) private var pocketbase

    private let rawr: Rawr
    
    @State private var isPresentingEditAlert: Bool = false
    @State private var editText: String = ""

    static let logger = Logger(
        subsystem: "PocketBaseDemo",
        category: "RawrView"
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
