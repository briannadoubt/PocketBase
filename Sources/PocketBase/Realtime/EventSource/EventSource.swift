//
//  EventSource.swift
//  PocketBase
//
//  Created by Brianna Zamora on 10/1/24.
//

import Foundation

actor EventSource: NSObject, HasLogger {
    let config: Config
    
    private(set) var readyState: ReadyState = .raw
    func set(readyState: ReadyState) {
        self.readyState = readyState
    }
    private var urlSession: URLSession?
    let utf8LineParser: UTF8LineParser = UTF8LineParser()
    let eventParser: EventParser
    let reconnectionTimer: ReconnectionTimer
    private var sessionTask: URLSessionDataTask?
    
    private var delegate: EventSourceDelegate?
    
    func createSession() -> URLSession {
        URLSession(
            configuration: config.urlSessionConfiguration,
            delegate: delegate,
            delegateQueue: nil
        )
    }

    public init(config: Config) {
        self.config = config
        self.eventParser = EventParser(
            handler: config.handler,
            initialEventId: config.lastEventId,
            initialRetry: config.reconnectTime
        )
        self.reconnectionTimer = ReconnectionTimer(
            maxDelay: config.maxReconnectTime,
            resetInterval: config.backoffResetThreshold
        )
        super.init()
        self.delegate = EventSourceDelegate(eventSource: self)
    }

    public func start() async {
        guard self.readyState == .raw else {
            Self.logger.info("start() called on already-started EventSource object. Returning")
            return
        }
        self.readyState = .connecting
        self.urlSession = self.createSession()
        await self.connect()
    }

    public func stop() async {
        let previousState = self.readyState
        self.readyState = .shutdown
        self.sessionTask?.cancel()
        if previousState == .open {
            await self.config.handler.onClosed()
        }
        self.urlSession?.invalidateAndCancel()
        self.urlSession = nil
    }
    
    func connect() async {
        Self.logger.info("Starting EventSource client")
        let request = await createRequest()
        let task = urlSession?.dataTask(with: request)
        task?.resume()
        sessionTask = task
    }

    public func getLastEventId() async -> String? {
        await eventParser.getLastEventId()
    }

    func createRequest() async -> URLRequest {
        var urlRequest = URLRequest(
            url: self.config.url,
            cachePolicy: URLRequest.CachePolicy.reloadIgnoringLocalAndRemoteCacheData,
            timeoutInterval: self.config.idleTimeout
        )
        urlRequest.httpMethod = self.config.method
        urlRequest.httpBody = self.config.body
        if let lastEventId = await self.getLastEventId(), !lastEventId.isEmpty {
            urlRequest.setValue(lastEventId, forHTTPHeaderField: "Last-Event-Id")
        }
        urlRequest.allHTTPHeaderFields = self.config.headerTransform(
            urlRequest.allHTTPHeaderFields?.merging(self.config.headers) { $1 } ?? self.config.headers
        )
        return urlRequest
    }
    
    func dispatchError(error: Error) async -> ConnectionErrorAction {
        let action: ConnectionErrorAction = config.connectionErrorHandler(error)
        if action != .shutdown {
            await config.handler.onError(error: error)
        }
        return action
    }
    
    /// Struct for configuring the EventSource.
    public struct Config: Sendable {
        /// The `EventHandler` called in response to activity on the stream.
        public let handler: EventHandler
        /// The `URL` of the request used when connecting to the EventSource API.
        public let url: URL

        /// The HTTP method to use for the API request.
        public var method: String = "GET"
        /// Optional HTTP body to be included in the API request.
        public var body: Data?
        /// Additional HTTP headers to be set on the request
        public var headers: [String: String] = [:]
        /// Transform function to allow dynamically configuring the headers on each API request.
        public var headerTransform: HeaderTransform = { $0 }
        /// An initial value for the last-event-id header to be sent on the initial request
        public var lastEventId: String = ""
        
        /// The minimum amount of time to wait before reconnecting after a failure
        public var reconnectTime: TimeInterval = 1.0
        /// The maximum amount of time to wait before reconnecting after a failure
        public var maxReconnectTime: TimeInterval = 30.0
        /// The minimum amount of time for an `EventSource` connection to remain open before allowing the connection
        /// backoff to reset.
        public var backoffResetThreshold: TimeInterval = 60.0
        /// The maximum amount of time between receiving any data before considering the connection to have timed out.
        public var idleTimeout: TimeInterval = 300.0

        private var _urlSessionConfiguration: URLSessionConfiguration = URLSessionConfiguration.default
        /**
         The `URLSessionConfiguration` used to create the `URLSession`.

         - Important:
            Note that this copies the given `URLSessionConfiguration` when set, and returns copies (updated with any
         overrides specified by other configuration options) when the value is retrieved. This prevents updating the
         `URLSessionConfiguration` after initializing `EventSource` with the `Config`, and prevents the `EventSource`
         from updating any properties of the given `URLSessionConfiguration`.

         - Since: 1.3.0
         */
        public var urlSessionConfiguration: URLSessionConfiguration {
            get {
                // swiftlint:disable:next force_cast
                let sessionConfig = _urlSessionConfiguration.copy() as! URLSessionConfiguration
                sessionConfig.httpAdditionalHeaders = ["Accept": "text/event-stream", "Cache-Control": "no-cache"]
                sessionConfig.timeoutIntervalForRequest = idleTimeout

                #if !os(Linux) && !os(Windows)
                if #available(iOS 13, macOS 10.15, tvOS 13, watchOS 6, *) {
                    sessionConfig.tlsMinimumSupportedProtocolVersion = .TLSv12
                } else {
                    sessionConfig.tlsMinimumSupportedProtocol = .tlsProtocol12
                }
                #endif
                return sessionConfig
            }
            set {
                // swiftlint:disable:next force_cast
                _urlSessionConfiguration = newValue.copy() as! URLSessionConfiguration
            }
        }

        /**
         An error handler that is called when an error occurs and can shut down the client in response.

         The default error handler will always attempt to reconnect on an
         error, unless `EventSource.stop()` is called or the error code is 204.
         */
        public var connectionErrorHandler: ConnectionErrorHandler = { error in
            guard let unsuccessfulResponseError = error as? UnsuccessfulResponseError
            else { return .proceed }

            let responseCode: Int = unsuccessfulResponseError.responseCode
            if 204 == responseCode {
                return .shutdown
            }
            return .proceed
        }

        /// Create a new configuration with an `EventHandler` and a `URL`
        public init(handler: EventHandler, url: URL, lastEventId: String?) {
            self.handler = handler
            self.url = url
            self.lastEventId = lastEventId ?? ""
        }
    }
}

actor ReconnectionTimer {
    private let maxDelay: TimeInterval
    private let resetInterval: TimeInterval

    var backoffCount: Int = 0
    var connectedTime: Date?
    func set(connectedTime: Date?) {
        self.connectedTime = connectedTime
    }

    init(maxDelay: TimeInterval, resetInterval: TimeInterval) {
        self.maxDelay = maxDelay
        self.resetInterval = resetInterval
    }

    func reconnectDelay(baseDelay: TimeInterval) -> TimeInterval {
        backoffCount += 1
        if let connectedTime = connectedTime, Date().timeIntervalSince(connectedTime) >= resetInterval {
            backoffCount = 0
        }
        self.connectedTime = nil
        let maxSleep = min(maxDelay, baseDelay * pow(2.0, Double(backoffCount)))
        return maxSleep / 2 + Double.random(in: 0...(maxSleep / 2))
    }
}

final class EventSourceDelegate: NSObject, URLSessionDataDelegate, HasLogger {
    let eventSource: EventSource
    
    init(eventSource: EventSource) {
        self.eventSource = eventSource
    }
    
    // MARK: URLSession Delegates

    // Tells the delegate that the task finished transferring data.
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        Task {
            await eventSource.utf8LineParser.closeAndReset()
            let currentRetry = await eventSource.eventParser.reset()
            
            guard await eventSource.readyState != .shutdown else { return }
            
            if let error = error {
                if (error as NSError).code != NSURLErrorCancelled {
                    Self.logger.info("Connection error: \(error)")
                    if await eventSource.dispatchError(error: error) == .shutdown {
                        Self.logger.info("Connection has been explicitly shut down by error handler")
                        if await eventSource.readyState == .open {
                            await eventSource.config.handler.onClosed()
                        }
                        await eventSource.set(readyState: .shutdown)
                        return
                    }
                }
            } else {
                Self.logger.info("Connection unexpectedly closed.")
            }
            
            if await eventSource.readyState == .open {
                await eventSource.config.handler.onClosed()
            }
            
            await eventSource.set(readyState: .closed)
            let sleep = await eventSource.reconnectionTimer.reconnectDelay(baseDelay: currentRetry)
            // this formatting shenanigans is to workaround String not implementing CVarArg on Swift<5.4 on Linux
            Self.logger.log("Waiting \(String(format: "%.3f", sleep)) seconds before reconnecting...")
            try? await Task.sleep(for: .seconds(sleep))
            await eventSource.connect()
        }
    }
    
    public func urlSession(
        _ session: URLSession,
        dataTask: URLSessionDataTask,
        didReceive response: URLResponse,
        completionHandler: @escaping @Sendable (URLSession.ResponseDisposition) -> Void
    ) {
        Self.logger.debug("Initial reply received")
        Task {
            // swiftlint:disable:next force_cast
            let httpResponse = response as! HTTPURLResponse
            let statusCode = httpResponse.statusCode
            if (200..<300).contains(statusCode) && statusCode != 204 {
                await eventSource.reconnectionTimer.set(connectedTime: Date())
                await eventSource.set(readyState: .open)
                await eventSource.config.handler.onOpened()
                completionHandler(.allow)
            } else {
                Self.logger.info("Unsuccessful response: \(String(format: "%d", statusCode))")
                let statusCode = statusCode
                let dispatchError = await eventSource.dispatchError(error: UnsuccessfulResponseError(responseCode: statusCode))
                if dispatchError == .shutdown {
                    Self.logger.info("Connection has been explicitly shut down by error handler")
                    await eventSource.set(readyState: .shutdown)
                }
                completionHandler(.cancel)
            }
        }
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        Task {
            for line in await eventSource.utf8LineParser.append(data) {
                await eventSource.eventParser.parse(line: line)
            }
        }
    }
}
