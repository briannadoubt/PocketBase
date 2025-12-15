//
//  SettingsAdmin+Test.swift
//  PocketBase
//
//  Created by Claude Code on behalf of Brianna Zamora
//

import Foundation

extension SettingsAdmin {
    /// Tests the current email/SMTP configuration by sending a test email.
    ///
    /// - Parameters:
    ///   - email: The email address to send the test email to.
    ///   - template: The template to use (e.g., "verification", "password-reset").
    /// - Throws: An error if the test fails or the configuration is invalid.
    public func testEmail(to email: String, template: String = "verification") async throws {
        struct TestEmailRequest: Encodable {
            let email: String
            let template: String
        }

        let body = TestEmailRequest(email: email, template: template)
        let data = try JSONEncoder().encode(body)

        _ = try await execute(method: "POST", path: "\(Self.basePath)/test/email", body: data)
    }

    /// Tests the current S3 storage configuration.
    ///
    /// - Parameter filesystem: The filesystem to test (default: "storage").
    /// - Throws: An error if the test fails or the configuration is invalid.
    public func testS3(filesystem: String = "storage") async throws {
        struct TestS3Request: Encodable {
            let filesystem: String
        }

        let body = TestS3Request(filesystem: filesystem)
        let data = try JSONEncoder().encode(body)

        _ = try await execute(method: "POST", path: "\(Self.basePath)/test/s3", body: data)
    }
}
