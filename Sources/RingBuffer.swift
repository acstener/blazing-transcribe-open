import Foundation

/// Thread-safe circular buffer for Float audio samples.
/// Single producer (audio tap) / single consumer (transcription reader).
///
/// Audio samples live only in this buffer in RAM.
/// Nothing is written to disk. Nothing is sent over the network.
public final class RingBuffer {
    private var buffer: [Float]
    private var writeIndex: Int = 0
    private var totalWritten: Int = 0
    private let capacity: Int
    private let lock = NSLock()

    /// Create a ring buffer with the given capacity in samples.
    /// For 30s at 16kHz: capacity = 480_000 (1.83 MB)
    public init(capacity: Int) {
        self.capacity = capacity
        self.buffer = [Float](repeating: 0, count: capacity)
    }

    /// Write samples into the buffer, overwriting oldest data if full.
    public func write(_ samples: [Float]) {
        lock.lock()
        defer { lock.unlock() }

        for sample in samples {
            buffer[writeIndex] = sample
            writeIndex = (writeIndex + 1) % capacity
        }
        totalWritten += samples.count
    }

    /// Read the most recent `count` samples from the buffer.
    public func readLast(_ count: Int) -> [Float] {
        lock.lock()
        defer { lock.unlock() }

        let available = min(count, min(totalWritten, capacity))
        guard available > 0 else { return [] }

        var result = [Float](repeating: 0, count: available)
        var readPos = (writeIndex - available + capacity) % capacity

        for i in 0..<available {
            result[i] = buffer[readPos]
            readPos = (readPos + 1) % capacity
        }
        return result
    }
}
