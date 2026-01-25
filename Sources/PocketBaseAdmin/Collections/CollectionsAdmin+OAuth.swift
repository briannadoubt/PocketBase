//
//  CollectionsAdmin+OAuth.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension CollectionsAdmin {
    /// Get OAuth2 configuration for a collection.
    ///
    /// - Parameter collectionId: The ID of the collection.
    /// - Returns: The OAuth2 configuration, if present.
    public func getOAuth2Config(collectionId: String) async throws -> OAuth2Config? {
        let collection = try await view(id: collectionId)
        return collection.oauth2
    }

    /// Update OAuth2 providers for a collection.
    ///
    /// - Parameters:
    ///   - collectionId: The ID of the collection.
    ///   - providers: The OAuth2 providers to set.
    /// - Returns: The updated collection.
    public func updateOAuth2Providers(
        collectionId: String,
        providers: [OAuth2ProviderConfig]
    ) async throws -> CollectionModel {
        let collection = try await view(id: collectionId)

        var oauth2 = collection.oauth2 ?? OAuth2Config()
        oauth2.providers = providers

        let updateRequest = CollectionUpdateRequest(oauth2: oauth2)
        return try await update(id: collectionId, updateRequest)
    }

    /// Enable or disable OAuth2 for a collection.
    ///
    /// - Parameters:
    ///   - collectionId: The ID of the collection.
    ///   - enabled: Whether OAuth2 should be enabled.
    /// - Returns: The updated collection.
    public func setOAuth2Enabled(
        collectionId: String,
        enabled: Bool
    ) async throws -> CollectionModel {
        let collection = try await view(id: collectionId)

        var oauth2 = collection.oauth2 ?? OAuth2Config()
        oauth2.enabled = enabled

        let updateRequest = CollectionUpdateRequest(oauth2: oauth2)
        return try await update(id: collectionId, updateRequest)
    }

    /// Add or update a single OAuth2 provider for a collection.
    ///
    /// - Parameters:
    ///   - collectionId: The ID of the collection.
    ///   - provider: The OAuth2 provider to add or update.
    /// - Returns: The updated collection.
    public func updateOAuth2Provider(
        collectionId: String,
        provider: OAuth2ProviderConfig
    ) async throws -> CollectionModel {
        let collection = try await view(id: collectionId)

        var oauth2 = collection.oauth2 ?? OAuth2Config()
        var providers = oauth2.providers ?? []

        // Remove existing provider with same name if present
        providers.removeAll { $0.name == provider.name }
        providers.append(provider)

        oauth2.providers = providers

        let updateRequest = CollectionUpdateRequest(oauth2: oauth2)
        return try await update(id: collectionId, updateRequest)
    }

    /// Remove an OAuth2 provider from a collection.
    ///
    /// - Parameters:
    ///   - collectionId: The ID of the collection.
    ///   - providerName: The name of the provider to remove.
    /// - Returns: The updated collection.
    public func removeOAuth2Provider(
        collectionId: String,
        providerName: String
    ) async throws -> CollectionModel {
        let collection = try await view(id: collectionId)

        var oauth2 = collection.oauth2 ?? OAuth2Config()
        var providers = oauth2.providers ?? []

        providers.removeAll { $0.name == providerName }
        oauth2.providers = providers

        let updateRequest = CollectionUpdateRequest(oauth2: oauth2)
        return try await update(id: collectionId, updateRequest)
    }
}
