import XCTest
@testable import L2RR2L

/// Tests for JSON model decoding
/// These tests verify the JSON decoding logic for API response models.
final class ModelDecodingTests: XCTestCase {
    let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return decoder
    }()

    // MARK: - JSON Decoding Tests

    func testDecoderConfiguration() {
        XCTAssertNotNil(decoder)
    }

    func testSnakeCaseToCamelCase() {
        struct TestModel: Decodable {
            let firstName: String
            let lastName: String
        }

        let json = """
        {
            "first_name": "John",
            "last_name": "Doe"
        }
        """.data(using: .utf8)!

        let model = try? decoder.decode(TestModel.self, from: json)

        XCTAssertNotNil(model)
        XCTAssertEqual(model?.firstName, "John")
        XCTAssertEqual(model?.lastName, "Doe")
    }

    func testOptionalFieldsDecoding() {
        struct TestModel: Decodable {
            let requiredField: String
            let optionalField: String?
        }

        let json = """
        {
            "required_field": "value"
        }
        """.data(using: .utf8)!

        let model = try? decoder.decode(TestModel.self, from: json)

        XCTAssertNotNil(model)
        XCTAssertEqual(model?.requiredField, "value")
        XCTAssertNil(model?.optionalField)
    }

    func testArrayDecoding() {
        struct TestModel: Decodable {
            let items: [String]
        }

        let json = """
        {
            "items": ["a", "b", "c"]
        }
        """.data(using: .utf8)!

        let model = try? decoder.decode(TestModel.self, from: json)

        XCTAssertNotNil(model)
        XCTAssertEqual(model?.items.count, 3)
    }

    func testNestedObjectDecoding() {
        struct Inner: Decodable {
            let value: Int
        }
        struct Outer: Decodable {
            let inner: Inner
        }

        let json = """
        {
            "inner": {
                "value": 42
            }
        }
        """.data(using: .utf8)!

        let model = try? decoder.decode(Outer.self, from: json)

        XCTAssertNotNil(model)
        XCTAssertEqual(model?.inner.value, 42)
    }

    func testInvalidJSONThrowsError() {
        struct TestModel: Decodable {
            let field: String
        }

        let invalidJson = "{ invalid }".data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(TestModel.self, from: invalidJson))
    }

    func testMissingRequiredFieldThrowsError() {
        struct TestModel: Decodable {
            let requiredField: String
        }

        let json = "{}".data(using: .utf8)!

        XCTAssertThrowsError(try decoder.decode(TestModel.self, from: json))
    }
}
