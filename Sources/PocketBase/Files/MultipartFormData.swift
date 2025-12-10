//
//  MultipartFormData.swift
//  PocketBase
//
//  Created by Brianna Zamora on 12/4/24.
//

import Foundation

/// A utility for building multipart/form-data request bodies.
///
/// Used internally for file uploads to PocketBase.
struct MultipartFormData: Sendable {
    /// The boundary string used to separate parts in the multipart body.
    let boundary: String

    /// The accumulated data for the multipart body.
    private var data: Data

    /// Creates a new MultipartFormData builder with a unique boundary.
    init() {
        self.boundary = "PocketBase-\(UUID().uuidString)"
        self.data = Data()
    }

    /// Creates a new MultipartFormData builder with a specific boundary.
    /// - Parameter boundary: The boundary string to use.
    init(boundary: String) {
        self.boundary = boundary
        self.data = Data()
    }

    /// The Content-Type header value for this multipart form data.
    var contentType: String {
        "multipart/form-data; boundary=\(boundary)"
    }

    /// Appends a text field to the multipart body.
    /// - Parameters:
    ///   - name: The field name.
    ///   - value: The string value.
    mutating func append(name: String, value: String) {
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        data.append("\(value)\r\n".data(using: .utf8)!)
    }

    /// Appends a file to the multipart body.
    /// - Parameters:
    ///   - name: The field name.
    ///   - file: The file to upload.
    mutating func append(name: String, file: UploadFile) {
        // Escape quotes and backslashes in filename per RFC 2231
        let escapedFilename = file.filename
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        data.append("--\(boundary)\r\n".data(using: .utf8)!)
        data.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(escapedFilename)\"\r\n".data(using: .utf8)!)
        data.append("Content-Type: \(file.mimeType)\r\n\r\n".data(using: .utf8)!)
        data.append(file.data)
        data.append("\r\n".data(using: .utf8)!)
    }

    /// Appends multiple files to the multipart body with the same field name.
    /// - Parameters:
    ///   - name: The field name.
    ///   - files: The files to upload.
    mutating func append(name: String, files: [UploadFile]) {
        for file in files {
            append(name: name, file: file)
        }
    }

    /// Appends JSON-encoded data as form fields.
    /// - Parameters:
    ///   - data: The JSON data to append.
    mutating func appendJSON(_ jsonData: Data) throws {
        guard let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return
        }
        appendDictionary(json, prefix: "")
    }

    /// Recursively appends dictionary values as form fields.
    private mutating func appendDictionary(_ dict: [String: Any], prefix: String) {
        for (key, value) in dict {
            let fieldName = prefix.isEmpty ? key : "\(prefix)[\(key)]"
            appendValue(value, name: fieldName)
        }
    }

    /// Appends a value with proper type handling.
    private mutating func appendValue(_ value: Any, name: String) {
        switch value {
        case let string as String:
            append(name: name, value: string)
        // Bool must be checked before NSNumber because Swift's Bool bridges to NSNumber
        case let bool as Bool:
            append(name: name, value: bool ? "true" : "false")
        case let number as NSNumber:
            append(name: name, value: "\(number)")
        case let array as [Any]:
            for (index, item) in array.enumerated() {
                appendValue(item, name: "\(name)[\(index)]")
            }
        case let dict as [String: Any]:
            appendDictionary(dict, prefix: name)
        case is NSNull:
            // Skip null values
            break
        default:
            append(name: name, value: "\(value)")
        }
    }

    /// Finalizes the multipart body and returns the complete data.
    /// - Returns: The complete multipart/form-data body.
    mutating func finalize() -> Data {
        data.append("--\(boundary)--\r\n".data(using: .utf8)!)
        return data
    }
}
