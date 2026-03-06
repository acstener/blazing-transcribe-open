# Blazing Transcribe — Open Audio Pipeline

**Your audio never leaves your Mac.** This document explains exactly how Blazing Transcribe handles your voice data so you can verify our privacy claims.

## The pipeline

Every step from microphone to typed text runs locally on your machine:

```
  Microphone
      │
      ▼
  Audio Capture ──── Converts to 16kHz mono via AVAudioEngine
      │
      ▼
  Ring Buffer ────── Circular buffer in RAM (never written to disk)
      │
      ▼
  Silero VAD ─────── ML voice activity detection (runs on CPU, locally)
      │
      ▼
  Parakeet TDT ──── Speech-to-text on Apple Neural Engine
      │
      ▼
  Text Output ────── Typed into focused app via macOS CGEvent injection
```

No step in this pipeline makes a network call. Audio exists only in memory and is never saved to disk.

## Code excerpts

### Audio stays in memory

Audio from the microphone is written to a ring buffer — a fixed-size array in RAM that overwrites old data as new data comes in. No disk writes, no network calls:

```swift
/// Thread-safe circular buffer for Float audio samples.
public final class RingBuffer {
    private var buffer: [Float]
    private var writeIndex: Int = 0
    private let capacity: Int

    /// For 30s at 16kHz: capacity = 480_000 (1.83 MB)
    public init(capacity: Int) {
        self.capacity = capacity
        self.buffer = [Float](repeating: 0, count: capacity)
    }

    /// Write samples into the buffer, overwriting oldest data if full.
    public func write(_ samples: [Float]) {
        for sample in samples {
            buffer[writeIndex] = sample
            writeIndex = (writeIndex + 1) % capacity
        }
        totalWritten += samples.count
    }
}
```

### Transcription runs on-device

Speech-to-text uses NVIDIA Parakeet TDT via [FluidAudio](https://github.com/FluidInference/FluidAudio), which runs entirely on the Apple Neural Engine:

```swift
/// FluidAudio-based ASR using NVIDIA Parakeet TDT on Apple Neural Engine.
/// Runs inference entirely on the ANE, keeping CPU and GPU free.
public final class FluidAudioContext: ASRContext {
    private let asrManager: AsrManager

    public func transcribe(samples: [Float], context: String?) -> TranscriptionResult {
        // All inference happens on-device via the Neural Engine.
        // No network call here — just local model inference.
        let result = asrManager.transcribe(samples, source: .microphone)
        return TranscriptionResult(text: result.text, ...)
    }
}
```

### Text is typed locally

Transcribed text is injected into the focused app via macOS CGEvent keyboard events — a local system API, no server involved:

```swift
/// Injects text into the focused application via CGEvent keyboard events.
func typeText(_ text: String) {
    let utf16 = Array(text.utf16)
    let source = CGEventSource(stateID: .hidSystemState)

    // CGEvent posts keyboard events directly to the focused app.
    // This is the same mechanism macOS uses for physical keyboard input.
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: true)
    keyDown.keyboardSetUnicodeString(...)
    keyDown.post(tap: .cghidEventTap)
}
```

## Models

| Model | Purpose | Runs on |
|---|---|---|
| [NVIDIA Parakeet TDT 0.6B](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2) | Speech-to-text | Apple Neural Engine (via [FluidAudio](https://github.com/FluidInference/FluidAudio)) |
| [Silero VAD](https://github.com/snakers4/silero-vad) | Voice activity detection | CPU |

Both models run entirely on-device. No cloud inference, no API calls.

## What touches the network

Blazing Transcribe makes exactly **three types of network calls**. None involve your audio or transcription text:

| What | Why | What's sent | Audio/text sent? |
|---|---|---|---|
| **License check** | Verify subscription | License key only (via [Lemon Squeezy](https://lemonsqueezy.com)) | **Never** |
| **Analytics** | Aggregate usage stats | Event names only (see below) | **Never** |
| **Update check** | OTA updates via [Sparkle](https://sparkle-project.org) | App version only | **Never** |

### Analytics details

We use [TelemetryDeck](https://telemetrydeck.com), a privacy-first analytics provider based in the EU.

**Event names we send:** `appLaunched`, `transcriptionCompleted`, `recordingStarted`, `engineLoaded`, `recordingModeChanged`, `micToggleUsed`, `modeToggleUsed`, `licenseActivated`, `subscribeClicked`

**Basic parameters:** word count per transcription, which recording mode is active, error messages when something breaks.

**Never sent:** transcription text, audio data, microphone input, file contents, or anything personally identifiable. TelemetryDeck doesn't use cookies, doesn't track across apps, and doesn't sell data.

## Why we published this

Most transcription apps say "local processing" but give you no way to verify it. We're publishing our architecture and key code excerpts so you can confirm:

1. Audio goes into an in-memory ring buffer — never written to disk, never sent anywhere
2. Transcription runs on Apple Neural Engine — fully on-device, no cloud API
3. Text is delivered via CGEvent keyboard injection — directly to the focused app
4. Analytics contain only event names and counters — no audio, text, or personal data

Local processing isn't just more private — it's why Blazing Transcribe is fast.

## Links

- [Blazing Transcribe](https://blazingtranscribe.com) — the app
- [Privacy](https://blazingtranscribe.com/privacy) — visual overview of our privacy model
