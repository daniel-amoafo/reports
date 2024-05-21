// Created by Daniel Amoafo on 17/5/2024.

import Combine
import Foundation

/// AsyncPublisher vends a .value property however does not reliably vend values
/// when used in a for await syntax. Using a `AsyncStream` reliably delivers values
extension Publisher where Failure == Never {

    public var stream: AsyncStream<Output> {
        AsyncStream { continuation in
            let cancellable = self.sink { _ in
                continuation.finish()
            } receiveValue: { value in
                 continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

}