//
//  RecordCollection+Upload.swift
//  PocketBase
//
//  Created by Brianna Zamora on 3/22/25.
//

import Foundation

public struct FileDTO: Encodable, Sendable {
    public var fileName: String
    public var data: Data
    public init(fileName: String, data: Data) {
        self.fileName = fileName
        self.data = data
    }
}

extension RecordCollection {
    /// Upload a single file to a record field
    /// - Parameters:
    ///   - data: The data to upload
    ///   - recordId: The id of the record to update
    ///   - field: The field that the file resides in the record
    ///   - fileName: The name of the uploaded file
    /// - Returns: The updated record
    @Sendable
    @discardableResult
    public func upload(
        _ data: Data,
        for recordId: String,
        field: String,
        fileName: String
    ) async throws -> T {
        try await client.patch(
            path: PocketBase.recordPath(collection, recordId, trailingSlash: true),
            headers: client.multipartHeaders,
            body: PocketBase.formEncoder.encode(
                [
                    field: FileDTO(
                        fileName: fileName,
                        data: data
                    )
                ],
                boundary: PocketBase.multipartEncodingBoundary
            )
        )
    }
    
    /// Upload a batch of files to a record field
    /// - Parameters:
    ///   - data: The data objects to upload
    ///   - recordId: The id of the record to update
    ///   - field: The field that the file resides in the record
    ///   - fileName: The name of the uploaded file
    /// - Returns: The updated record
    @Sendable
    @discardableResult
    public func upload(
        _ data: [Data],
        for recordId: String,
        field: String,
        fileName: String
    ) async throws -> Data {
        try await client.patch(
            path: PocketBase.recordPath(
                collection,
                recordId,
                trailingSlash: true
            ) + fileName,
            headers: client.multipartHeaders,
            body: PocketBase.formEncoder.encode(
                [field: data],
                boundary: PocketBase.multipartEncodingBoundary
            )
        )
    }
}
