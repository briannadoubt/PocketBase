//
//  Users.swift
//  PocketBase
//
//  Created by Bri on 9/16/22.
//

import Foundation
import Alamofire

/// An object used to interact with the PocketBase **Users API**.
public actor Users {
    
    /// Used to make HTTP requests.
    private let http = HTTP()
    
    /// Used for retry policies and authorization headers.
    private var interceptor: Interceptor
    
    /// An object used to interact with the PocketBase **Users API**.
    /// - Parameter interceptor: The request's optional interceptor, defaults to nil. Use the interceptor to apply retry policies or attach headers as necessary.
    init(interceptor: Interceptor) {
        self.interceptor = interceptor
    }
    
    /// Returns a public list with the allowed user authentication methods.
    /// - Returns: A public list of allowed user authentication methods, represented with an `AuthMethods` object.
    public func authMethods() async throws -> AuthMethods {
        try await http.request(Request.authMethods)
    }
    
    /// Authenticate a user via its email and password.
    /// - Parameters:
    ///   - email: The potential user's email.
    ///   - password: The potential user's password.
    /// - Returns: A valid `LoginResponse` containing the token and the current user.
    public func auth<UserProfile: Model>(email: String, password: String) async throws -> LoginResponse<UserProfile> {
        try await http.request(Request.auth(email: email, password: password))
    }
    
    /// Authenticate via OAuth2 client provider.
    /// - Parameters:
    ///   - provider: The third-party authentication service designation.
    ///   - code: The oauth code retrieved from the specified provider.
    ///   - codeVerifier: The code verifier value used during the oauth flow.
    ///   - redirectUrl: The redirect URL used by the third-party to verify a valid connection to PocketBase.
    /// - Returns: A valid `LoginResponse` containing the token and the current user.
    public func oauth<UserProfile: Model>(provider: OAuthProvider, code: String, codeVerifier: String, redirectUrl: URL) async throws -> LoginResponse<UserProfile> {
        try await http.request(Request.oauth(provider: provider, code: code, codeVerifier: codeVerifier, redirectUrl: redirectUrl))
    }
    
    /// Returns a new auth response (token and user data) for already authenticated user. Requires `Authorization: User/Admin TOKEN` header value.
    /// - Returns: A valid `LoginResponse` containing the token and the current user.
    public func refresh<UserProfile: Model>() async throws -> LoginResponse<UserProfile> {
        try await http.request(Request.refresh, interceptor: interceptor)
    }
    
    /// Sends a password reset email to a user.
    /// - Parameter email: The potential user's email.
    public func requestPasswordReset(email: String) async throws {
        try await http.request(Request.requestPasswordReset(email: email))
    }
    
    /// Confirms a password reset request and sets a new user password.
    /// - Parameters:
    ///   - token: The current authentication session's Authentication Bearer token.
    ///   - password: A new password.
    ///   - passwordConfirm: A new password, verified.
    /// - Returns: A valid `LoginResponse` containing the token and the current user.
    public func confirmPasswordReset<UserProfile: Model>(token: String, password: String, passwordConfirm: String) async throws -> LoginResponse<UserProfile> {
        try await http.request(Request.confirmPasswordReset(token: token, password: password, passwordConfirm: passwordConfirm))
    }
    
    /// Sends user verification email request.
    /// - Parameter email: The email to verify.
    public func requestVerification(email: String) async throws {
        try await http.request(Request.requestVerification(email: email))
    }
    
    /// Confirms a user email address verification request.
    /// - Parameter token: The current authentication session's Authentication Bearer token.
    /// - Returns: A valid `LoginResponse` containing the token and the current user.
    public func confirmVerification<UserProfile: Model>(token: String) async throws -> LoginResponse<UserProfile> {
        try await http.request(Request.confirmVerification(token: token))
    }
    
    /// Sends user email change request.
    ///
    /// Requires `Authorization: User TOKEN` header value
    /// - Parameter newEmail: The potentially new email.
    public func requestEmailChange(newEmail: String) async throws {
        try await http.request(Request.requestEmailChange(newEmail: newEmail), interceptor: interceptor)
    }
    
    /// Confirms the new user email address change.
    /// - Parameters:
    ///   - token: The current authentication session's Authentication Bearer token.
    ///   - password: The current user's valid password.
    /// - Returns: A valid `LoginResponse` containing the token and the current user.
    public func confirmEmailChange<UserProfile: Model>(token: String, password: String) async throws -> LoginResponse<UserProfile> {
        try await http.request(Request.confirmEmailChange(token: token, password: password))
    }
    
    /// Returns a paginated users list.
    ///
    /// Only admins can access this action. Requires `Authorization: Admin/User TOKEN` header value.
    /// - Parameters:
    ///   - page: The current query's page number.
    ///   - perPage: The number of records per page.
    ///   - sort: The sort desctriptor.
    ///   - filter: The filter description.
    /// - Returns: A list result object containing an array of `User` records.
    public func list<UserProfile: Model>(page: Int = 1, perPage: Int = 30, sort: String, filter: String) async throws -> ListResult<User<UserProfile>> {
        try await http.request(Request.list(page: page, perPage: perPage, sort: sort, filter: filter), interceptor: interceptor)
    }
    
    /// Returns a paginated users list.
    ///
    /// Only admins can access this action. Requires `Authorization: Admin/User TOKEN` header value.
    /// - Parameters:
    ///   - page: The current query's page number.
    ///   - perPage: The number of records per page.
    ///   - sort: The sort desctriptor.
    ///   - filter: The filter description.
    /// - Returns: A list result object containing an array of `User` records.
    public func list<UserProfile: Model>(page: Int = 1, perPage: Int = 30, @SortQuery sort: () -> [Sort], filter: String) async throws -> ListResult<User<UserProfile>> {
        try await http.request(Request.list(page: page, perPage: perPage, sort: sort().query, filter: filter), interceptor: interceptor)
    }
    
    /// Return a single user by its ID.
    ///
    /// Only admins and the user owner can access this action. Requires `Authorization: Admin/User TOKEN` header value.
    /// - Parameter id: The `id` of the user that is to be shown.
    /// - Returns: The user record to be displayed.
    public func view<UserProfile: Model>(id: UUID) async throws -> User<UserProfile> {
        try await http.request(Request.view(id: id), interceptor: interceptor)
    }
    
    /// Creates a new user (aka. register).
    ///
    /// This action requires email/password authentication settings to be enabled!
    /// - Parameters:
    ///   - id: The `id` of the user that is to be created. If `nil` then a UUID will be generated on PocketBase.
    ///   - email: The potential user's email.
    ///   - password: The potential user's password.
    ///   - passwordConfirm: The potential user's password, confirmed.
    /// - Returns: A new user instance, if successful.
    public func create<UserProfile: Model>(id: UUID?, email: String, password: String, passwordConfirm: String) async throws -> User<UserProfile> {
        try await http.request(Request.create(id: id, email: email, password: password, passwordConfirm: passwordConfirm))
    }
    
    /// Update a single user model's email by its ID.
    ///
    /// Only admins can access this action. Requires `Authorization: Admin TOKEN` header value.
    /// - Parameters:
    ///   - id: The `id` of the user to be updated.
    ///   - email: The updated email. Changing the email address will reset the user's verified field (aka. will be set to false).
    /// - Returns: The updated user instance, if successful.
    public func updateEmail<UserProfile: Model>(id: UUID, email: String) async throws -> User<UserProfile> {
        try await http.request(Request.updateEmail(id: id, email: email), interceptor: interceptor)
    }
    
    /// Update a single user model's password by its ID.
    ///
    /// Only admins can access this action. Requires `Authorization: Admin TOKEN` header value.
    ///
    /// Changing the email address will reset the user's verified field (aka. will be set to false).
    /// - Parameters:
    ///   - id: The `id` of the user to be updated.
    ///   - email: The updated email. Changing the email address will reset the user's verified field (aka. will be set to false).
    /// - Returns: The updated user instance, if successful.
    public func updatePassword<UserProfile: Model>(id: UUID, password: String, passwordConfirm: String) async throws -> User<UserProfile> {
        try await http.request(Request.updatePassword(id: id, password: password, passwordConfirm: passwordConfirm), interceptor: interceptor)
    }
    
    /// Deletes a single user by its id.
    ///
    /// Only admins and the user owner can access this action.
    /// - Parameter id: The `id` of the user to be deleted.
    public func delete(id: UUID) async throws {
        try await http.request(Request.delete(id: id), interceptor: interceptor)
    }
    
    /// Return a list with all external auth providers linked to a single user.
    ///
    /// Only admins and the user owner can access this action.
    /// - Parameter id: The `id` of the user in question.
    /// - Returns: An array of `AuthMethod` objects describing the linked authentication methods for the current user.
    public func existingAuthMethods(id: UUID) async throws -> [AuthMethod] {
        try await http.request(Request.existingAuthMethods(id: id), interceptor: interceptor)
    }
    
    /// Unlink a single user external auth provider.
    ///
    /// Only admins and the user owner can access this action.
    /// - Parameters:
    ///   - id: The `id` of the user in question.
    ///   - provider: The third-party authentication service designation.
    public func unlinkProvider(id: UUID, provider: OAuthProvider) async throws {
        try await http.request(Request.unlinkProvider(id: id, provider: provider), interceptor: interceptor)
    }
    
    private enum Request: URLRequestConvertible {
        ///Request a public list with the allowed user authentication methods.
        case authMethods
        
        /// Authenticate a user via its email and password.
        /// - Parameters:
        ///   - email: The potential user's email.
        ///   - password: The potential user's password.
        case auth(email: String, password: String)
        
        /// Authenticate via OAuth2 client provider.
        /// - Parameters:
        ///   - provider: The third-party authentication service designation.
        ///   - code: The oauth code retrieved from the specified provider.
        ///   - codeVerifier: The code verifier value used during the oauth flow.
        ///   - redirectUrl: The redirect URL used by the third-party to verify a valid connection to PocketBase.
        case oauth(provider: OAuthProvider, code: String, codeVerifier: String, redirectUrl: URL)
        
        /// Returns a new auth response (token and user data) for already authenticated user.
        ///
        /// Requires `Authorization: User/Admin TOKEN` header value.
        case refresh
        
        /// Sends a password reset email to a user.
        /// - Parameter email: The potential user's email.
        case requestPasswordReset(email: String)
        
        /// Confirms a password reset request and sets a new user password.
        /// - Parameters:
        ///   - token: The current authentication session's Authentication Bearer token.
        ///   - password: A new password.
        ///   - passwordConfirm: A new password, verified.
        case confirmPasswordReset(token: String, password: String, passwordConfirm: String)
        
        /// Sends user verification email request.
        /// - Parameter email: The email to verify.
        case requestVerification(email: String)
        
        /// Confirms a user email address verification request.
        /// - Parameter token: The current authentication session's Authentication Bearer token.
        case confirmVerification(token: String)
        
        /// Sends user email change request.
        ///
        /// Requires `Authorization: User/Admin TOKEN` header value
        /// - Parameter newEmail: The potentially new email.
        case requestEmailChange(newEmail: String)
        
        /// Confirms the new user email address change.
        /// - Parameters:
        ///   - token: The current authentication session's Authentication Bearer token.
        ///   - password: The current user's valid password.
        case confirmEmailChange(token: String, password: String)
        
        /// Returns a paginated users list.
        ///
        /// Only admins can access this action. Requires `Authorization: Admin TOKEN` header value.
        case list(page: Int, perPage: Int, sort: String, filter: String)
        
        /// Return a single user by its ID.
        ///
        /// Only admins and the user owner can access this action. Requires `Authorization: Admin/User TOKEN` header value.
        /// - Parameter id: The `id` of the user that is to be shown.
        case view(id: UUID)
        
        /// Creates a new user (aka. register).
        ///
        /// This action requires email/password authentication settings to be enabled!
        /// - Parameters:
        ///   - id: The `id` of the user that is to be created. If `nil` then a UUID will be generated on PocketBase.
        ///   - email: The potential user's email.
        ///   - password: The potential user's password.
        ///   - passwordConfirm: The potential user's password, confirmed.
        case create(id: UUID?, email: String, password: String, passwordConfirm: String)
        
        /// Update a single user model's email by its ID.
        ///
        /// Only admins can access this action. Requires `Authorization: Admin TOKEN` header value.
        /// - Parameters:
        ///   - id: The `id` of the user to be updated.
        ///   - email: The updated email. Changing the email address will reset the user's verified field (aka. will be set to false).
        case updateEmail(id: UUID, email: String)
        
        /// Update a single user model's password by its ID.
        ///
        /// Only admins can access this action. Requires `Authorization: Admin TOKEN` header value.
        ///
        /// Changing the email address will reset the user's verified field (aka. will be set to false).
        /// - Parameters:
        ///   - id: The `id` of the user to be updated.
        ///   - email: The updated email. Changing the email address will reset the user's verified field (aka. will be set to false).
        case updatePassword(id: UUID, password: String, passwordConfirm: String)
        
        /// Deletes a single user by its id.
        ///
        /// Only admins and the user owner can access this action.
        /// - Parameter id: The `id` of the user to be deleted.
        case delete(id: UUID)
        
        /// Return a list with all external auth providers linked to a single user.
        ///
        /// Only admins and the user owner can access this action.
        ///
        /// - Parameter id: The `id` of the user in question.
        case existingAuthMethods(id: UUID)
        
        /// Unlink a single user external auth provider.
        ///
        /// Only admins and the user owner can access this action.
        /// - Parameters:
        ///   - id: The `id` of the user in question.
        ///   - provider: The third-party authentication service designation.
        case unlinkProvider(id: UUID, provider: OAuthProvider)
        
        /// The base URL for the Users API
        var base: URL {
            URL(string: "https://127.0.0.1:8090")!
                .appendingPathComponent("api")
                .appendingPathComponent("users")
        }
        
        /// The generated URL for a given request.
        var url: URL {
            switch self {
            case .authMethods:
                return base.appendingPathComponent("auth-methods")
            case .auth:
                return base.appendingPathComponent("auth-via-email")
            case .oauth:
                return base.appendingPathComponent("auth-via-oauth2")
            case .refresh:
                return base.appendingPathComponent("refresh")
            case .requestPasswordReset:
                return base.appendingPathComponent("request-password-reset")
            case .confirmPasswordReset:
                return base.appendingPathComponent("confirm-password-reset")
            case .requestVerification:
                return base.appendingPathComponent("request-verification")
            case .confirmVerification:
                return base.appendingPathComponent("confirm-verification")
            case .requestEmailChange:
                return base.appendingPathComponent("request-email-change")
            case .confirmEmailChange:
                return base.appendingPathComponent("confirm-email-change")
            case .list(let page, let perPage, let sort, let filter):
                var components = URLComponents()
                components.queryItems = [
                    URLQueryItem(name: "page", value: "\(page)"),
                    URLQueryItem(name: "perPage", value: "\(perPage)"),
                    URLQueryItem(name: "sort", value: sort),
                    URLQueryItem(name: "filter", value: filter)
                ]
                return components.url(relativeTo: base)!
            case .view(let id), .updateEmail(let id, _), .updatePassword(let id, _, _), .delete(let id):
                return base.appendingPathComponent(id.uuidString)
            case .create:
                return base
            case .existingAuthMethods(let id):
                return base
                    .appendingPathComponent(id.uuidString)
                    .appendingPathComponent("external-auths")
            case .unlinkProvider(let id, let provider):
                return base
                    .appendingPathComponent(id.uuidString)
                    .appendingPathComponent("external-auths")
                    .appendingPathComponent(provider.rawValue)
            }
        }
        
        /// The HTTP Method used for a given request.
        var method: HTTPMethod {
            switch self {
            case .authMethods:
                return .get
            case .auth, .oauth, .refresh, .requestPasswordReset, .confirmPasswordReset, .requestVerification, .confirmVerification, .requestEmailChange, .confirmEmailChange, .create, .existingAuthMethods:
                return .post
            case .list, .view:
                return .get
            case .updateEmail, .updatePassword:
                return .patch
            case .delete, .unlinkProvider:
                return .delete
            }
        }
        
        /// The HTTP Headers used for a given request.
        var headers: HTTPHeaders {
            var headers = HTTPHeaders()
            headers.add(.defaultAcceptEncoding)
            headers.add(.defaultUserAgent)
            headers.add(.defaultAcceptLanguage)
            return headers
        }
        
        // MARK: - `URLRequestConvertible` Conformance
        
        /// Convert the current case to a `URLRequest`.
        func asURLRequest() throws -> URLRequest {
            var request = try URLRequest(url: url, method: method, headers: headers)
            var body: [String: Encodable]?
            switch self {
            case .authMethods:
                break
            case .auth(let email, let password):
                body = [
                    "email": email,
                    "password": password
                ]
            case .oauth(let provider, let code, let codeVerifier, let redirectUrl):
                body = [
                    "provider": provider.rawValue,
                    "code": code,
                    "codeVerifier": codeVerifier,
                    "redirectUrl": redirectUrl.absoluteString
                ]
            case .refresh:
                break
            case .requestPasswordReset(let email):
                body = ["email": email]
            case .confirmPasswordReset(let token, let password, let passwordConfirm):
                body = [
                    "token": token,
                    "password": password,
                    "passwordConfirm": passwordConfirm
                ]
            case .requestVerification(let email):
                body = ["email": email]
            case .confirmVerification(let token):
                body = ["token": token]
            case .requestEmailChange(let newEmail):
                body = ["newEmail": newEmail]
            case .confirmEmailChange(let token, let password):
                body = [
                    "token": token,
                    "password": password
                ]
            case .create(let id, let email, let password, let passwordConfirm):
                body = [
                    "email": email,
                    "password": password,
                    "passwordConfirm": passwordConfirm
                ]
                if let id = id {
                    body?["id"] = id
                }
            case .updateEmail(let id, let email):
                body = [
                    "id": id,
                    "email": email
                ]
            case .updatePassword(let id, let password, let passwordConfirm):
                body = [
                    "id": id,
                    "password": password,
                    "passwordConfirm": passwordConfirm
                ]
            case .list, .view, .existingAuthMethods, .delete, .unlinkProvider:
                break
            }
            if let body = body as? Encodable {
                request.httpBody = try JSONEncoder().encode(body)
            }
            return request
        }
    }
}

/// The third-party authentication service designation.
public enum OAuthProvider: String, Encodable {
    case google
    case facebook
    case github
    case gitlab
}

/// The response of a successful login request.
public struct LoginResponse<UserProfile: Model>: Decodable {
    /// The current session's token.
    var token: String
    /// The currently logged in `User`.
    var user: User<UserProfile>
    /// Metadata accompanying the login response. Used with third-party OAuth providers.
    var meta: Metadata?
    
    /// Metadata accompanying the login response.
    struct Metadata: Decodable {
        /// The `id` of the auth
        var id: UUID
        /// The name of the oauth provider.
        var name: String
        /// The email of the logged in user.
        var email: String
        /// The photo URL for the current user.
        var avatarUrl: URL
        
        /// The `LoginResponse.Metadata`'s `CodingKeys` conformance
        enum CodingKeys: String, CodingKey {
            case id
            case name
            case email
            case avatarUrl = "avatarurl"
        }
    }
}

/// The currently available PocketBase authentication methods.
public struct AuthMethods: Decodable {
    /// Wether or not a user can login with their email and a password.
    var emailPassword: Bool
    /// A list of available third-party OAuth providers.
    var authProviders: [AuthProvider]
}

/// A third-party OAuth provider.
struct AuthProvider: Decodable {
    /// The name of the provider.
    var name: String
    /// The state of the provider.
    var state: String
    /// The hash used for verification.
    var codeVerifier: String
    /// The challenge that proves this is a real provider.
    var codeChallenge: String
    /// How to use the `codeChallenge` variable.
    var codeChallengeMethod: String
    /// The URL to hit to initiate the OAuth flow.
    var authUrl: URL
}

/// A currenly implemented authentication method saved to a User's account
public struct AuthMethod: Decodable {
    var id: UUID
    var created: Date
    var updated: Date
    var userId: UUID
    var provider: String
    var providerId: String
}
