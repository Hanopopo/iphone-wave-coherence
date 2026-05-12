# Wave Coherence

> A multi-sensor "field engine" for iPhone. Uses every emitter and receiver iOS gives an app to detect, generate and phase-lock real, measurable waves around you — magnetic, acoustic, vibrational, optical and 2.4 GHz radio.

Built in SwiftUI with an Apple Liquid Glass design language. Compiles in GitHub Actions to a **fully unsigned IPA** that you can re-sign in 7-day mode with [Sideloadly](https://sideloadly.io) using a free Apple ID.

## Features

### Receivers (detect waves around you)
- **Magnetometer** — 3-axis Hall sensor, magnetic field magnitude in µT.
- **Microphone FFT** — real-time spectrum, peak detection, dominant frequency.
- **Camera PPG (HR + HRV)** — cover the rear camera with your fingertip; the flash illuminates capillaries and the app derives bpm, RMSSD and a heart-coherence score.
- **Accelerometer + Gyroscope** — orientation and vibration RMS.
- **Barometer** — pressure and relative altitude in real time.
- **Bluetooth LE scan** — every advertising device nearby, RSSI, and a derived "RF density" metric.

### Emitters (generate waves from your phone)
- **Audio tone** — pure sine / binaural beats / isochronic tones at any frequency.
- **Taptic Engine** — phase-locked mechanical vibration (transient pulses below 30 Hz, continuous above).
- **Screen flasher** — full-screen brightness modulation in phase with the master clock (SSVEP-style).
- **Flashlight LED** — pulsed up to ~12 Hz.
- **BLE intention beacon** — broadcasts a 2.4 GHz advertisement tagged with the chosen frequency so a second device can detect it.

### Coherence Engine
A 60 Hz master clock drives every emitter from the same phase. Every receiver is sampled, normalized, and combined into a coherence score visualized in real time on the Dashboard.

### Presets
Curated frequencies grouped by category — Schumann modes, brainwave bands, Solfeggio, resonant breathing — each documented with the peer-reviewed paper it is based on (see [RESEARCH.md](./RESEARCH.md)).

## Build (locally, on a Mac)

```bash
brew install xcodegen
xcodegen generate
open WaveCoherence.xcodeproj
```

## Build (in CI → unsigned IPA → Sideloadly)

Every push triggers `.github/workflows/build-ipa.yml`. Once green, open the workflow run on GitHub and download the `WaveCoherence-unsigned-ipa` artifact.

To install:

1. Plug your iPhone into a Mac or Windows machine.
2. Open Sideloadly.
3. Drag the `WaveCoherence-unsigned.ipa` into Sideloadly.
4. Sign in with your free Apple ID.
5. Sideloadly re-signs the IPA with a free 7-day certificate and installs it on the device.
6. On the iPhone, go to **Settings → General → VPN & Device Management** and trust the developer profile.

## Permissions

iOS will prompt for: Motion, Microphone, Camera, Bluetooth, Location (compass). All are required to access the corresponding receivers/emitters; the app does not transmit data off-device.

## Honest scope

Wave Coherence emits real, measurable signals only. Any effect on perception, mood, or physiology comes from those measurable stimuli — not from supernatural channels. Claims tied to specific frequencies (Solfeggio, "manifestation") are presented with citations in [RESEARCH.md](./RESEARCH.md) and clearly marked when the supporting evidence is weak.
