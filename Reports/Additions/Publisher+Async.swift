// Created by Daniel Amoafo on 17/5/2024.

import Combine
import Foundation

// AsyncPublisher vends a .value property however not reliable
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
