import Foundation
import AVFoundation
import CoreHaptics
import UIKit

/// Geiger-counter style feedback. The whole point is that you can hunt with the
/// phone at knee height and your eyes on the sand instead of on the screen:
/// clicks get faster and higher pitched as the signal comes up.
@MainActor
final class Feedback: ObservableObject {

    @Published var soundOn = false {
        didSet { soundOn ? tone.start() : tone.stop(); rescheduleTimer() }
    }
    @Published var hapticsOn = true {
        didSet { if hapticsOn { prepareHaptics() }; rescheduleTimer() }
    }

    private let tone = ToneGenerator()
    private var haptics: CHHapticEngine?
    private var clickTimer: Timer?
    private var clicksPerSecond: Double = 1

    init() { prepareHaptics() }

    /// Feed the smoothed RSSI in. -100 is nothing, -40 is standing on top of it.
    func update(rssi: Double) {
        let clamped = min(max(rssi, -100), -40)
        let t = (clamped + 100) / 60                     // 0...1
        clicksPerSecond = 0.7 + t * t * 13.0             // 0.7 Hz crawl to ~14 Hz
        tone.setFrequency(420 + t * 1100)
        rescheduleTimer()
    }

    private func rescheduleTimer() {
        guard soundOn || hapticsOn else {
            clickTimer?.invalidate()
            clickTimer = nil
            return
        }
        let interval = 1.0 / clicksPerSecond
        // Only rebuild the timer on a meaningful change, or it never gets to fire.
        if let clickTimer, abs(clickTimer.timeInterval - interval) < 0.05 { return }
        clickTimer?.invalidate()
        clickTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pulse() }
        }
    }

    private func pulse() {
        if soundOn { tone.click() }
        if hapticsOn { tap() }
    }

    // MARK: - Haptics

    private func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics, haptics == nil else { return }
        haptics = try? CHHapticEngine()
        haptics?.isAutoShutdownEnabled = true
        try? haptics?.start()
    }

    private func tap() {
        guard let haptics else {
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            return
        }
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9),
            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.7)
        ], relativeTime: 0)
        if let pattern = try? CHHapticPattern(events: [event], parameters: []),
           let player = try? haptics.makePlayer(with: pattern) {
            try? player.start(atTime: 0)
        }
    }
}

/// Owns the audio graph. Deliberately *not* main-actor isolated: the render block
/// runs on the real-time audio thread, so all of its state lives here behind a lock.
private final class ToneGenerator: @unchecked Sendable {

    private let engine = AVAudioEngine()
    private var source: AVAudioSourceNode?

    private let lock = NSLock()
    private var frequency: Double = 500
    private var envelopeSamples: Int = 0
    private var burstLength: Int = 1
    private var phase: Double = 0
    private var sampleRate: Double = 44_100

    func setFrequency(_ hz: Double) {
        lock.lock(); frequency = hz; lock.unlock()
    }

    /// Trigger one ~35 ms burst.
    func click() {
        lock.lock()
        burstLength = Int(sampleRate * 0.035)
        envelopeSamples = burstLength
        lock.unlock()
    }

    func start() {
        guard source == nil else { return }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }

        let format = engine.outputNode.inputFormat(forBus: 0)
        let rate = format.sampleRate > 0 ? format.sampleRate : 44_100
        lock.lock(); sampleRate = rate; lock.unlock()

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self else { return noErr }
            let buffers = UnsafeMutableAudioBufferListPointer(audioBufferList)

            self.lock.lock()
            let freq = self.frequency
            let rate = self.sampleRate
            let startRemaining = self.envelopeSamples
            var remaining = startRemaining
            let length = max(self.burstLength, 1)
            var localPhase = self.phase
            self.lock.unlock()

            let increment = 2 * Double.pi * freq / rate

            for frame in 0..<Int(frameCount) {
                var value: Float = 0
                if remaining > 0 {
                    // Linear decay — a hard gate would add a click to the click.
                    let decay = Double(remaining) / Double(length)
                    value = Float(sin(localPhase) * 0.35 * decay)
                    localPhase += increment
                    if localPhase > 2 * .pi { localPhase -= 2 * .pi }
                    remaining -= 1
                } else {
                    localPhase = 0
                }
                for buffer in buffers {
                    guard let ptr = buffer.mData?.assumingMemoryBound(to: Float.self) else { continue }
                    ptr[frame] = value
                }
            }

            self.lock.lock()
            self.phase = localPhase
            // If click() fired while we were rendering, leave its burst alone.
            if self.envelopeSamples == startRemaining { self.envelopeSamples = remaining }
            self.lock.unlock()

            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: nil)
        source = node

        do { try engine.start() } catch { engine.detach(node); source = nil }
    }

    func stop() {
        engine.stop()
        if let source { engine.detach(source) }
        source = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
    }
}
