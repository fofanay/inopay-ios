// InopaySDK — Swift client for Inopay's African capital markets infrastructure.
// Aligns with the public sandbox at https://api.getinopay.com/v1/sandbox

import Foundation

public enum Market: String, Codable, Sendable { case BRVM, BVMAC, GSE }
public enum Currency: String, Codable, Sendable { case XOF, XAF, GHS }
public enum OrderSide: String, Codable, Sendable { case buy, sell }
public enum OrderStatus: String, Codable, Sendable { case pending, filled, rejected, cancelled }
public enum KycLevel: String, Codable, Sendable { case KYC1, KYC2, KYC3 }

public struct Instrument: Codable, Sendable {
    public let symbol: String
    public let name: String
    public let market: Market
    public let currency: Currency
    public let last_price: Double
    public let change_pct: Double
}

public struct InstrumentList: Codable, Sendable {
    public let sandbox: Bool?
    public let as_of: String
    public let instruments: [Instrument]
}

public struct SGI: Codable, Sendable {
    public let id: String
    public let name: String
    public let market: Market
    public let fill_rate: Double
}

public struct SGIList: Codable, Sendable {
    public let sandbox: Bool
    public let sgis: [SGI]
}

public struct CreateOrderInput: Codable, Sendable {
    public let symbol: String
    public let side: OrderSide
    public let qty: Int
    public let sgi_id: String?

    public init(symbol: String, side: OrderSide, qty: Int, sgiId: String? = nil) {
        self.symbol = symbol
        self.side = side
        self.qty = qty
        self.sgi_id = sgiId
    }
}

public struct Order: Codable, Sendable {
    public let id: String
    public let symbol: String
    public let side: OrderSide
    public let qty: Int
    public let sgi_id: String
    public let status: OrderStatus
    public let avg_price: Double
    public let filled_qty: Int
    public let filled_at: String?
    public let settlement_date: String?
    public let settlement_currency: Currency?
}

public struct OrderResponse: Codable, Sendable {
    public let sandbox: Bool
    public let order: Order
    public let note: String?
}

public struct KycAttestation: Codable, Sendable {
    public let schema: String
    public let user_id: String
    public let issuer: String
    public let level: KycLevel
    public let issued_at: String
    public let expires_at: String
    public let key_id: String
    public let ed25519_signature: String
}

public struct KycResponse: Codable, Sendable {
    public let sandbox: Bool
    public let attestation: KycAttestation
    public let note: String?
}

public struct SandboxResetResult: Codable, Sendable {
    public let sandbox: Bool
    public let reset_at: String
    public let wallet_credit_cents: Int64
    public let message: String
}

public struct HealthResult: Codable, Sendable {
    public let sandbox: Bool
    public let status: String
    public let demo_key: String
    public let rate_limit: String
}

public struct InopayError: Error, Codable, Sendable, CustomStringConvertible {
    public let status: Int
    public let code: String
    public let detail: String?

    public var description: String {
        "InopayError(\(status) \(code): \(detail ?? ""))"
    }
}

public final class InopayClient: @unchecked Sendable {
    public let apiKey: String
    public let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    /// Initialize the client.
    /// - Parameters:
    ///   - apiKey: API key. Use `sk_test_demo_inopay_2026` for the public sandbox (60 req/min/IP).
    ///   - baseURL: defaults to the public sandbox.
    ///   - session: custom URLSession (useful for tests).
    public init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.getinopay.com/v1/sandbox")!,
        session: URLSession = .shared
    ) {
        precondition(!apiKey.isEmpty, "InopayClient: apiKey is required")
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.session = session
        self.decoder = JSONDecoder()
        self.encoder = JSONEncoder()
    }

    private func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: Data? = nil
    ) async throws -> T {
        var req = URLRequest(url: baseURL.appendingPathComponent(path))
        req.httpMethod = method
        req.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("application/json", forHTTPHeaderField: "Accept")
        req.httpBody = body

        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw InopayError(status: -1, code: "transport", detail: "non-HTTP response")
        }

        if (200..<300).contains(http.statusCode) {
            return try decoder.decode(T.self, from: data)
        }

        struct ErrPayload: Decodable { let error: String?; let detail: String? }
        let payload = try? decoder.decode(ErrPayload.self, from: data)
        throw InopayError(
            status: http.statusCode,
            code: payload?.error ?? "http_\(http.statusCode)",
            detail: payload?.detail
        )
    }

    // MARK: — Endpoints

    public func health() async throws -> HealthResult {
        try await request("health")
    }

    public func listInstruments() async throws -> InstrumentList {
        try await request("instruments")
    }

    public func listSGIs() async throws -> SGIList {
        try await request("sgis")
    }

    public func createOrder(_ input: CreateOrderInput) async throws -> OrderResponse {
        let body = try encoder.encode(input)
        return try await request("orders", method: "POST", body: body)
    }

    public func getOrder(id: String) async throws -> OrderResponse {
        try await request("orders/\(id)")
    }

    public func fetchKyc(userId: String) async throws -> KycResponse {
        try await request("kyc/\(userId)")
    }

    public func resetSandbox() async throws -> SandboxResetResult {
        try await request("sandbox/reset", method: "POST")
    }
}
