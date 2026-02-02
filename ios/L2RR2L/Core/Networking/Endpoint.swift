import Foundation

/// Defines an API endpoint
public struct Endpoint {
    public let path: String
    public let method: HTTPMethod
    public let body: Encodable?
    public let queryItems: [URLQueryItem]?
    public let contentType: ContentType

    public enum ContentType {
        case json
        case formData
    }

    public init(
        path: String,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        queryItems: [URLQueryItem]? = nil,
        contentType: ContentType = .json
    ) {
        self.path = path
        self.method = method
        self.body = body
        self.queryItems = queryItems
        self.contentType = contentType
    }
}
