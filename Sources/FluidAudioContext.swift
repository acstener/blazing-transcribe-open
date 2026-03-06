import Foundation
import FluidAudio

/// FluidAudio-based ASR engine using NVIDIA Parakeet TDT models on Apple Neural Engine.
///
/// FluidAudio runs inference entirely on the ANE, keeping CPU and GPU free.
/// Parakeet TDT v3 achieves ~210x real-time on M4 Pro with 2.5% WER.
///
/// No network calls — all inference is on-device.
public final class FluidAudioContext {
    private let asrManager: AsrManager

    /// Create a FluidAudioContext by loading a Parakeet TDT model.
    public static func create(version: AsrModelVersion = .v3) async throws -> FluidAudioContext {
        let models = try await AsrModels.downloadAndLoad(version: version)
        let asrManager = AsrManager(config: .default)
        try await asrManager.initialize(models: models)
        return FluidAudioContext(asrManager: asrManager)
    }

    private init(asrManager: AsrManager) {
        self.asrManager = asrManager
    }

    /// Transcribe Float32 PCM audio (16kHz mono) to text.
    /// All inference runs on the Apple Neural Engine — no cloud API.
    public func transcribe(samples: [Float]) async throws -> String {
        let result = try await asrManager.transcribe(samples, source: .microphone)
        return result.text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
