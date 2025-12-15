//
//  PortForwarder.swift
//  PocketBase
//
//  Created by Claude on 12/11/24.
//

#if os(macOS)

import Foundation
import Network

/// A simple TCP port forwarder that listens on a local address and forwards to a remote address
@available(macOS 26.0, *)
public actor PortForwarder {
    private let localHost: String
    private let localPort: UInt16
    private let remoteHost: String
    private let remotePort: UInt16
    private var listener: NWListener?
    private var connections: [NWConnection] = []
    private let verbose: Bool

    public init(localHost: String = "0.0.0.0", localPort: UInt16, remoteHost: String, remotePort: UInt16, verbose: Bool = false) {
        self.localHost = localHost
        self.localPort = localPort
        self.remoteHost = remoteHost
        self.remotePort = remotePort
        self.verbose = verbose
    }

    public func start() async throws {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        // Set the local endpoint to bind to specific interface and port
        let host: NWEndpoint.Host
        if localHost == "0.0.0.0" {
            // Bind to all interfaces
            host = .ipv4(.any)
        } else if localHost == "localhost" || localHost == "127.0.0.1" {
            host = .ipv4(.loopback)
        } else {
            host = NWEndpoint.Host(localHost)
        }

        parameters.requiredLocalEndpoint = NWEndpoint.hostPort(
            host: host,
            port: NWEndpoint.Port(rawValue: localPort)!
        )

        // Don't pass port here - it's already set in requiredLocalEndpoint
        let listener = try NWListener(using: parameters)
        self.listener = listener

        listener.stateUpdateHandler = { [verbose] state in
            if verbose {
                print("[PortForwarder] Listener state: \(state)")
            }
        }

        listener.newConnectionHandler = { [weak self] incomingConnection in
            guard let self = self else { return }
            Task {
                await self.handleConnection(incomingConnection)
            }
        }

        listener.start(queue: .global())

        if verbose {
            print("[PortForwarder] Forwarding \(localHost):\(localPort) -> \(remoteHost):\(remotePort)")
        }
    }

    public func stop() {
        listener?.cancel()
        listener = nil
        for connection in connections {
            connection.cancel()
        }
        connections.removeAll()
    }

    private func handleConnection(_ incoming: NWConnection) {
        connections.append(incoming)

        // Create outgoing connection to container
        let remoteEndpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(remoteHost),
            port: NWEndpoint.Port(rawValue: remotePort)!
        )
        let outgoing = NWConnection(to: remoteEndpoint, using: .tcp)
        connections.append(outgoing)

        incoming.stateUpdateHandler = { [verbose] state in
            if verbose {
                print("[PortForwarder] Incoming connection state: \(state)")
            }
            if case .failed = state {
                incoming.cancel()
                outgoing.cancel()
            }
        }

        outgoing.stateUpdateHandler = { [weak self, verbose] state in
            if verbose {
                print("[PortForwarder] Outgoing connection state: \(state)")
            }
            if case .ready = state {
                // Start forwarding in both directions
                self?.startForwarding(from: incoming, to: outgoing)
                self?.startForwarding(from: outgoing, to: incoming)
            } else if case .failed = state {
                incoming.cancel()
                outgoing.cancel()
            }
        }

        incoming.start(queue: .global())
        outgoing.start(queue: .global())
    }

    /// Non-isolated helper to start forwarding task
    private nonisolated func startForwarding(from source: NWConnection, to destination: NWConnection) {
        Task {
            await self.forward(from: source, to: destination)
        }
    }

    private func forward(from source: NWConnection, to destination: NWConnection) async {
        while true {
            do {
                let data = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
                    source.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else if isComplete && data == nil {
                            continuation.resume(returning: nil)
                        } else {
                            continuation.resume(returning: data)
                        }
                    }
                }

                guard let data = data, !data.isEmpty else {
                    // Connection closed
                    break
                }

                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                    destination.send(content: data, completion: .contentProcessed { error in
                        if let error = error {
                            continuation.resume(throwing: error)
                        } else {
                            continuation.resume()
                        }
                    })
                }
            } catch {
                break
            }
        }
    }
}

#endif
