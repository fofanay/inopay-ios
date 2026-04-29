# InopaySDK (iOS / macOS)

Swift Package — client for the Inopay African capital markets infrastructure (BRVM, BVMAC, GSE) via the public sandbox.

## Status

`v0.1.0-alpha.1` — alpha public, wraps `https://api.getinopay.com/v1/sandbox/*`.

## Install

### Swift Package Manager (recommended)

In Xcode → File → Add Package Dependencies → enter the URL of the package archive:

```
https://getinopay.com/sdk/ios/inopay-ios-0.1.0-alpha.1.zip
```

Or in `Package.swift`:

```swift
.package(url: "https://getinopay.com/sdk/ios/inopay-ios-0.1.0-alpha.1.zip", from: "0.1.0")
```

### Manual

Download the zip from <https://getinopay.com/sdk/ios/> and drag `Sources/InopaySDK` into your Xcode project.

## Quick start

```swift
import InopaySDK

let inopay = InopayClient(apiKey: "sk_test_demo_inopay_2026") // public sandbox demo key

// List instruments
Task {
    do {
        let result = try await inopay.listInstruments()
        for instrument in result.instruments {
            print("\(instrument.symbol): \(instrument.last_price) \(instrument.currency.rawValue)")
        }
    } catch {
        print("Error: \(error)")
    }
}

// Place a simulated order
Task {
    let input = CreateOrderInput(symbol: "SNTS.BRVM", side: .buy, qty: 10)
    let response = try await inopay.createOrder(input)
    print("Order \(response.order.id) status: \(response.order.status.rawValue)")
}

// Fetch a mock KYC attestation
Task {
    let kyc = try await inopay.fetchKyc(userId: "usr_demo_42")
    print("Attestation issued at \(kyc.attestation.issued_at)")
}
```

## API surface

| Method | Description |
|---|---|
| `health()` | Sandbox status |
| `listInstruments()` | List BRVM / BVMAC / GSE instruments |
| `listSGIs()` | List partner SGIs in the sandbox |
| `createOrder(_:)` | Place a simulated order |
| `getOrder(id:)` | Read back an order |
| `fetchKyc(userId:)` | Mock Ed25519-signed KYC attestation |
| `resetSandbox()` | Reset the demo wallet |

## Rate limit

The public demo key `sk_test_demo_inopay_2026` is rate-limited to **60 requests per minute per IP**.
For private quotas request a sandbox key at <https://getinopay.com/fr/developers/sandbox>.

## Requirements

- iOS 15+ / macOS 12+
- Swift 5.9+

## License

MIT — © Inopay
