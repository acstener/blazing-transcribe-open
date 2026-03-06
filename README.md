# Blazing Transcribe — Open Audio Pipeline

**Your audio never leaves your Mac.** This document explains exactly how Blazing Transcribe handles your voice data so you can verify our privacy claims.

## The pipeline

Every step from microphone to typed text runs locally on your machine:

```
  Microphone
      │
      ▼
  Audio Capture ──── Converts to 16kHz mono
      │
      ▼
  Ring Buffer ────── Circular buffer in RAM (never written to disk)
      │
      ▼
  Silero VAD ─────── ML voice activity detection (runs on CPU, locally)
      │
      ▼
  Parakeet TDT ──── NVIDIA speech-to-text model (runs on Apple Neural Engine)
      │
      ▼
  Text Output ────── Typed into focused app via macOS CGEvent injection
```

No step in this pipeline makes a network call. Audio exists only in memory and is never saved to disk.

## Models

| Model | Purpose | Runs on |
|---|---|---|
| [NVIDIA Parakeet TDT 0.6B](https://huggingface.co/nvidia/parakeet-tdt-0.6b-v2) | Speech-to-text | Apple Neural Engine (via [FluidAudio](https://github.com/FluidInference/FluidAudio)) |
| [Silero VAD](https://github.com/snakers4/silero-vad) | Voice activity detection | CPU |

Both models run entirely on-device. No cloud inference, no API calls.

## What touches the network

Blazing Transcribe makes exactly **three types of network calls**. None of them involve your audio or transcription text:

| What | Why | What's sent | Audio/text sent? |
|---|---|---|---|
| **License check** | Verify subscription | License key only (via [Lemon Squeezy](https://lemonsqueezy.com)) | **Never** |
| **Analytics** | Aggregate usage stats | Event names only (see below) | **Never** |
| **Update check** | OTA updates via [Sparkle](https://sparkle-project.org) | App version only | **Never** |

### Analytics details

We use [TelemetryDeck](https://telemetrydeck.com), a privacy-first analytics provider based in the EU. Here's exactly what we send:

**Event names** — `appLaunched`, `transcriptionCompleted`, `recordingStarted`, `engineLoaded`, `recordingModeChanged`, `micToggleUsed`, `modeToggleUsed`, `licenseActivated`, `subscribeClicked`

**Basic parameters** — word count per transcription, which recording mode is active, error messages when something breaks

**What is never sent:** transcription text, audio data, microphone input, file contents, IP-based location, or anything personally identifiable. TelemetryDeck doesn't use cookies, doesn't track across apps, and doesn't sell data.

## Why we published this

Most transcription apps say "local processing" but give you no way to verify it. We're documenting our architecture publicly so you can confirm for yourself that:

1. Audio is captured into a ring buffer in memory — never written to disk, never sent anywhere
2. Transcription runs on Apple Neural Engine — fully on-device, no cloud API
3. Text is delivered via CGEvent keyboard injection — directly to the focused app
4. Analytics contain only event names and counters — no audio, text, or personal data

This also means there's no network latency in the transcription pipeline. Local processing isn't just more private — it's why Blazing Transcribe is fast.

## Links

- [Blazing Transcribe](https://blazingtranscribe.com) — the app
- [Privacy page](https://blazingtranscribe.com/privacy) — visual overview of our privacy model
