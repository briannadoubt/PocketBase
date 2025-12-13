//
//  RawrView.swift
//  PocketBaseDemo
//
//  Created by Brianna Zamora on 9/18/24.
//

import PocketBase
import SwiftUI
import PhotosUI
import os

struct RawrView: View {
    @Environment(\.pocketbase) private var pocketbase

    private let rawr: Rawr

    @State private var isPresentingEditAlert: Bool = false
    @State private var editText: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var isUploadingImage: Bool = false

    static let logger = Logger(
        subsystem: "PocketBaseDemo",
        category: "RawrView"
    )

    init(rawr: Rawr) {
        self.rawr = rawr
        self.editText = rawr.field
    }

    var body: some View {
        HStack(spacing: 12) {
            // Image thumbnail or placeholder
            Group {
                if let imageURL = rawr.image?.url {
                    AsyncImage(url: imageURL) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        @unknown default:
                            Image(systemName: "photo")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "photo.badge.plus")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 50, height: 50)
            .background(Color.secondary.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay {
                if isUploadingImage {
                    ProgressView()
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Text field
            VStack(alignment: .leading, spacing: 4) {
                Text(rawr.field.isEmpty ? "Untitled" : rawr.field)
                    .foregroundStyle(rawr.field.isEmpty ? .secondary : .primary)

                Text(rawr.created, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Photo picker button
            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                Image(systemName: "camera")
                    .foregroundStyle(.blue)
            }
            .buttonStyle(.plain)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            editText = rawr.field
            isPresentingEditAlert = true
        }
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
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let item = newValue else { return }
            Task {
                await uploadImage(from: item)
                selectedPhotoItem = nil
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

    private func uploadImage(from item: PhotosPickerItem) async {
        isUploadingImage = true
        defer { isUploadingImage = false }

        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                Self.logger.error("Failed to load image data")
                return
            }

            // Create upload file
            let filename = "\(UUID().uuidString).jpg"
            let uploadFile = UploadFile(
                filename: filename,
                data: data,
                mimeType: "image/jpeg"
            )

            // Update rawr with new image
            var updatedRawr = rawr
            updatedRawr.image = .pending(uploadFile)

            try await pocketbase.collection(Rawr.self).update(updatedRawr)
            Self.logger.info("Successfully uploaded image for rawr: \(rawr.id)")
        } catch {
            Self.logger.error("Failed to upload image: \(error)")
        }
    }
}
