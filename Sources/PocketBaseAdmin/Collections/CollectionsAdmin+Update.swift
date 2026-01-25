//
//  CollectionsAdmin+Update.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension CollectionsAdmin {
    /// Updates an existing collection.
    ///
    /// - Parameters:
    ///   - id: The collection ID or name.
    ///   - collection: The updated collection schema.
    /// - Returns: The updated collection schema.
    @discardableResult
    public func update(id: String, _ collection: CollectionModel) async throws -> CollectionModel {
        let body = try encoder.encode(collection)
        return try await patch(path: "\(Self.basePath)/\(id)", body: body)
    }

    /// Updates an existing collection with partial data.
    ///
    /// - Parameters:
    ///   - id: The collection ID or name.
    ///   - request: The collection update request with fields to update.
    /// - Returns: The updated collection schema.
    @discardableResult
    public func update(id: String, _ request: CollectionUpdateRequest) async throws -> CollectionModel {
        let body = try encoder.encode(request)
        return try await patch(path: "\(Self.basePath)/\(id)", body: body)
    }
}

/// Request body for updating a collection.
public struct CollectionUpdateRequest: Codable, Sendable {
    public let name: String?
    /// The collection fields. Encoded as `fields` for PocketBase 0.23+.
    public let schema: [Field]?
    public let listRule: String?
    public let viewRule: String?
    public let createRule: String?
    public let updateRule: String?
    public let deleteRule: String?
    public let indexes: [String]?

    // View collection specific options
    /// The SQL query for view collections. Only applicable when type is .view.
    public let viewQuery: String?

    // Auth collection specific options
    public let verificationTemplate: EmailTemplate?
    public let resetPasswordTemplate: EmailTemplate?
    public let confirmEmailChangeTemplate: EmailTemplate?
    public let authAlert: AuthAlertConfig?

    // Auth-specific configuration
    public let oauth2: OAuth2Config?
    public let passwordAuth: PasswordAuthConfig?
    public let mfa: MFAConfig?
    public let otp: OTPConfig?

    // Auth rules
    public let manageRule: String?
    public let authRule: String?

    // Token configurations
    public let authToken: TokenConfig?
    public let passwordResetToken: TokenConfig?
    public let emailChangeToken: TokenConfig?
    public let verificationToken: TokenConfig?
    public let fileToken: TokenConfig?

    enum CodingKeys: String, CodingKey {
        case name
        case schema = "fields"  // PocketBase 0.23+ uses `fields`
        case listRule, viewRule, createRule, updateRule, deleteRule
        case indexes, viewQuery
        case verificationTemplate, resetPasswordTemplate, confirmEmailChangeTemplate, authAlert
        case oauth2, passwordAuth, mfa, otp
        case manageRule, authRule
        case authToken, passwordResetToken, emailChangeToken, verificationToken, fileToken
    }

    public init(
        name: String? = nil,
        schema: [Field]? = nil,
        listRule: String? = nil,
        viewRule: String? = nil,
        createRule: String? = nil,
        updateRule: String? = nil,
        deleteRule: String? = nil,
        indexes: [String]? = nil,
        viewQuery: String? = nil,
        verificationTemplate: EmailTemplate? = nil,
        resetPasswordTemplate: EmailTemplate? = nil,
        confirmEmailChangeTemplate: EmailTemplate? = nil,
        authAlert: AuthAlertConfig? = nil,
        oauth2: OAuth2Config? = nil,
        passwordAuth: PasswordAuthConfig? = nil,
        mfa: MFAConfig? = nil,
        otp: OTPConfig? = nil,
        manageRule: String? = nil,
        authRule: String? = nil,
        authToken: TokenConfig? = nil,
        passwordResetToken: TokenConfig? = nil,
        emailChangeToken: TokenConfig? = nil,
        verificationToken: TokenConfig? = nil,
        fileToken: TokenConfig? = nil
    ) {
        self.name = name
        self.schema = schema
        self.listRule = listRule
        self.viewRule = viewRule
        self.createRule = createRule
        self.updateRule = updateRule
        self.deleteRule = deleteRule
        self.indexes = indexes
        self.viewQuery = viewQuery
        self.verificationTemplate = verificationTemplate
        self.resetPasswordTemplate = resetPasswordTemplate
        self.confirmEmailChangeTemplate = confirmEmailChangeTemplate
        self.authAlert = authAlert
        self.oauth2 = oauth2
        self.passwordAuth = passwordAuth
        self.mfa = mfa
        self.otp = otp
        self.manageRule = manageRule
        self.authRule = authRule
        self.authToken = authToken
        self.passwordResetToken = passwordResetToken
        self.emailChangeToken = emailChangeToken
        self.verificationToken = verificationToken
        self.fileToken = fileToken
    }
}
