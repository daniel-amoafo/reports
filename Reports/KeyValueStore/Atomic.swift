import os

/**
 Mark a property as atomic

 Wrapped values will use an unfair_lock under the hood to ensure that access to
 the value is thread-safe.
 */
@propertyWrapper
public class Atomic<Value> {

    // MARK: - Private Properties

    /**
     To understand why it's important to manage our own `UnsafeMutablePointer` instead of using
     the `&` operator, see http://www.russbishop.net/the-law .
     */
    private var lockPointer: UnsafeMutablePointer<os_unfair_lock>
    private var unsafeValue: Value

    // MARK: - Public Properties

    public var projectedValue: Atomic<Value> {
        return self
    }

    /**
     Access the wrapped value safely

     Note that if you're performing a read/write operation, as opposed to a
     strict read _or_ write operation, you should instead use `.mutate` on the
     projected value. For example:

     ```swift
     // given:
     @Atomic var value: Int = 0

     // safe operations:
     value = 2
     print(value)

     // unsafe operation:
     value += 1

     // made safe again by using .mutate on the projected value:
     $value.mutate { $0 += 1 }
     ```
     */
    public var wrappedValue: Value {
        get {
            os_unfair_lock_lock(lockPointer)
            defer { os_unfair_lock_unlock(lockPointer) }
            return unsafeValue
        }
        set {
            os_unfair_lock_lock(lockPointer)
            defer { os_unfair_lock_unlock(lockPointer) }
            unsafeValue = newValue
        }
    }

    // MARK: - Life Cycle

    public init(wrappedValue: Value) {
        lockPointer = UnsafeMutablePointer<os_unfair_lock>.allocate(capacity: 1)
        lockPointer.initialize(to: os_unfair_lock())

        self.unsafeValue = wrappedValue
    }

    deinit {
        lockPointer.deallocate()
    }

    // MARK: - Public Methods

    /**
     Mutate the wrapped value safely

     This is only really necessary for read-write operations, since strict read
     or write operations are already thread safe. So for example:

     ```swift
     // given:
     @Atomic var value: Int = 0

     // safe operations:
     value = 2
     print(value)

     // unsafe operation:
     value += 1

     // made safe again by using .mutate on the projected value:
     $value.mutate { $0 += 1 }
     ```
     */
    public func mutate(_ mutation: (inout Value) -> Void) {
        os_unfair_lock_lock(lockPointer)
        defer { os_unfair_lock_unlock(lockPointer) }
        mutation(&unsafeValue)
    }

}
