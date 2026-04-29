import XCTest
@testable import InopaySDK

final class InopaySDKTests: XCTestCase {
    func testClientInitialization() {
        let client = InopayClient(apiKey: "sk_test_demo_inopay_2026")
        XCTAssertEqual(client.apiKey, "sk_test_demo_inopay_2026")
        XCTAssertEqual(client.baseURL.absoluteString, "https://api.getinopay.com/v1/sandbox")
    }

    func testHealthIntegration() async throws {
        let client = InopayClient(apiKey: "sk_test_demo_inopay_2026")
        let health = try await client.health()
        XCTAssertTrue(health.sandbox)
        XCTAssertEqual(health.status, "ok")
    }

    func testListInstrumentsIntegration() async throws {
        let client = InopayClient(apiKey: "sk_test_demo_inopay_2026")
        let result = try await client.listInstruments()
        XCTAssertGreaterThan(result.instruments.count, 0)
        XCTAssertEqual(result.instruments.first?.symbol, "SNTS.BRVM")
    }
}
