import XCTest
@testable import L2RR2LCore

final class APIClientTests: XCTestCase {
    func testEndpointConstruction() {
        let endpoint = AuthEndpoints.login(email: "test@example.com", password: "password")

        XCTAssertEqual(endpoint.path, "auth/login")
        XCTAssertEqual(endpoint.method, .post)
        XCTAssertNotNil(endpoint.body)
    }

    func testChildrenEndpoints() {
        let listEndpoint = ChildrenEndpoints.list
        XCTAssertEqual(listEndpoint.path, "children")
        XCTAssertEqual(listEndpoint.method, .get)

        let getEndpoint = ChildrenEndpoints.get(id: "123")
        XCTAssertEqual(getEndpoint.path, "children/123")
    }

    func testLessonsEndpointsWithFilters() {
        let endpoint = LessonsEndpoints.list(
            subject: "reading",
            gradeLevel: "K",
            limit: 10,
            offset: 5
        )

        XCTAssertEqual(endpoint.path, "lessons")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertNotNil(endpoint.queryItems)
        XCTAssertTrue(endpoint.queryItems!.contains { $0.name == "subject" && $0.value == "reading" })
        XCTAssertTrue(endpoint.queryItems!.contains { $0.name == "limit" && $0.value == "10" })
    }

    func testProgressEndpointsPath() {
        let endpoint = ProgressEndpoints.forLesson(childId: "child1", lessonId: "lesson1")
        XCTAssertEqual(endpoint.path, "progress/child/child1/lesson/lesson1")

        let startEndpoint = ProgressEndpoints.startLesson(childId: "child1", lessonId: "lesson1")
        XCTAssertEqual(startEndpoint.path, "progress/child/child1/lesson/lesson1/start")
        XCTAssertEqual(startEndpoint.method, .post)
    }

    func testAPIErrorDescriptions() {
        let unauthorized = APIError.unauthorized
        XCTAssertNotNil(unauthorized.errorDescription)
        XCTAssertTrue(unauthorized.errorDescription!.contains("Unauthorized"))

        let networkError = APIError.networkError(URLError(.notConnectedToInternet))
        XCTAssertNotNil(networkError.errorDescription)
        XCTAssertTrue(networkError.errorDescription!.contains("Network error"))
    }
}
