import Foundation

/// Protocol for voice activity detection.
/// Implementations run locally — no network calls.
public protocol SpeechDetector {
    /// Detect speech in audio samples. Returns probability 0.0–1.0.
    func detectSpeech(samples: [Float]) -> Float
}
