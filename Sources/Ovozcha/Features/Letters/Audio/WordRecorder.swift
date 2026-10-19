import Foundation
import Observation
// `UIApplication` (ruxsat so'rash) SkipUI'da.
import SwiftUI

#if SKIP
import android.Manifest
import android.media.MediaRecorder
#else
import AVFoundation
#endif

/// So'z talaffuzini tekshirish uchun qisqa ovoz yozuvi. IOS va Android (Skip) uchun umumiy.
///
/// Faqat yozib oladi; eshittirish `ClipPlayer` da. Harflar va Talaffuz bo'limlari umumiy ishlatadi.
///
/// Format ikkala platformada bir xil: AAC/m4a, 16 kHz, mono — nutq tanish shuni kutadi.
@MainActor
@Observable
final class WordRecorder {

    enum StartResult: Equatable {
        case started
        case permissionDenied
        case failed
    }

    /// Bundan uzoq yozilmaydi (bola to'xtatishni unutsa).
    static let maxDuration: Double = 5.0
    /// Bundan qisqa yozuv hisobga olinmaydi (tasodifiy tegib ketish).
    static let minDuration: Double = 0.4
    /// Eng baland nuqta shundan past bo'lsa (0...1, ~ -30 dBFS), yozuv jim hisoblanadi va
    /// serverga yuborilmaydi. Sabab: Whisper jimlikdan so'z "o'ylab topadi" ("Thank you") —
    /// bola hech narsa demasa ham murabbiy "eshitdim" deb qolardi.
    static let silenceThreshold: Double = 0.03
    /// Balandlik qanchalik tez-tez o'lchanadi (soniya).
    private static let meterInterval: Double = 0.05

    private(set) var isRecording = false
    private(set) var lastRecordingURL: URL?

    @ObservationIgnored private var startedAt = Date()
    /// Yozuvdagi eng baland nuqta (0...1).
    @ObservationIgnored private var peakLevel: Double = 0.0
    @ObservationIgnored private var meterTask: Task<Void, Never>?
    /// `start()` ruxsatni kutayotganda `stop()`/`cancel()` chaqirilsa, shu raqam o'zgaradi va
    /// kechikib kelgan `start()` yozishni boshlamaydi. Aks holda bola ikki marta tez bossa,
    /// yozuv hech kim to'xtatmaydigan holda davom etardi (mikrofon yoniq qolardi).
    @ObservationIgnored private var generation = 0
    @ObservationIgnored private var isStarting = false

    #if SKIP
    @ObservationIgnored private var recorder: MediaRecorder?
    @ObservationIgnored private var outputPath: String?
    #else
    @ObservationIgnored private var recorder: AVAudioRecorder?
    #endif

    init() {
    }

    /// Yozuv qancha davom etganini soniyada qaytaradi.
    private var elapsed: Double {
        return Date().timeIntervalSince(startedAt)
    }

    func start() async -> StartResult {
        if isRecording {
            return .started
        }
        // Oldingi `start()` hali tugamagan: ikkinchi yozuvchi ochilmaydi.
        if isStarting {
            return .failed
        }
        lastRecordingURL = nil
        isStarting = true
        let ticket = generation

        #if SKIP

        let granted = await UIApplication.shared.requestPermission(Manifest.permission.RECORD_AUDIO)
        isStarting = false
        if !granted {
            return .permissionDenied
        }
        if ticket != generation {
            // Kutish paytida bekor qilindi.
            return .failed
        }

        let context = ProcessInfo.processInfo.androidContext
        let path = context.cacheDir.absolutePath + "/ovozcha-word.m4a"
        // minSdk = 31, shuning uchun kontekstli konstruktor har doim mavjud.
        let newRecorder = MediaRecorder(context)
        do {
            newRecorder.setAudioSource(MediaRecorder.AudioSource.MIC)
            newRecorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
            newRecorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
            newRecorder.setAudioSamplingRate(16000)
            newRecorder.setAudioChannels(1)
            newRecorder.setOutputFile(path)
            newRecorder.prepare()
            newRecorder.start()
        } catch {
            newRecorder.release()
            return .failed
        }
        recorder = newRecorder
        outputPath = path

        #else

        let granted = await Self.requestMicrophonePermission()
        isStarting = false
        guard granted else {
            return .permissionDenied
        }
        if ticket != generation {
            // Kutish paytida bekor qilindi.
            return .failed
        }
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)

            let url = FileManager.default.temporaryDirectory.appendingPathComponent("ovozcha-word.m4a")
            try? FileManager.default.removeItem(at: url)
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
            ]
            let newRecorder = try AVAudioRecorder(url: url, settings: settings)
            newRecorder.isMeteringEnabled = true
            guard newRecorder.record() else { return .failed }
            recorder = newRecorder
        } catch {
            return .failed
        }

        #endif

        startedAt = Date()
        peakLevel = 0.0
        isRecording = true
        startMetering()
        return .started
    }

    /// Yozishni to'xtatadi. Yozuv juda qisqa yoki jim bo'lsa `nil` qaytaradi.
    @discardableResult
    func stop() -> URL? {
        // Kutilayotgan `start()` ni bekor qiladi.
        generation += 1
        guard isRecording else { return lastRecordingURL }
        isRecording = false
        meterTask?.cancel()
        meterTask = nil
        sampleLevel()
        let duration = elapsed
        let heard = peakLevel >= WordRecorder.silenceThreshold
        // Chegarani haqiqiy qurilmada sozlash uchun.
        #if SKIP
        android.util.Log.d("Ovozcha", "yozuv balandligi \(peakLevel), davomiyligi \(duration)")
        #elseif DEBUG
        print("Ovozcha: yozuv balandligi \(peakLevel), davomiyligi \(duration)")
        #endif

        #if SKIP

        guard let current = recorder else { return nil }
        var saved: URL? = nil
        do {
            current.stop()
            if let path = outputPath, duration >= WordRecorder.minDuration && heard {
                saved = URL(fileURLWithPath: path)
            }
        } catch {
            // MediaRecorder juda qisqa yozuvda `stop()` da xato beradi — fayl yaroqsiz.
            saved = nil
        }
        current.release()
        recorder = nil

        #else

        guard let current = recorder else { return nil }
        let url = current.url
        current.stop()
        recorder = nil
        let saved: URL? = duration >= WordRecorder.minDuration && heard ? url : nil

        #endif

        lastRecordingURL = saved
        return saved
    }

    func cancel() {
        _ = stop()
        lastRecordingURL = nil
    }

    // MARK: Balandlik

    private func startMetering() {
        meterTask?.cancel()
        meterTask = Task {
            while !Task.isCancelled && isRecording {
                sampleLevel()
                try? await Task.sleep(nanoseconds: UInt64(WordRecorder.meterInterval * 1_000_000_000.0))
            }
        }
    }

    /// Joriy balandlikni o'lchab, eng baland nuqtani yangilaydi.
    private func sampleLevel() {
        guard let current = recorder else { return }
        var level = 0.0
        #if SKIP
        // Oxirgi so'rovdan beri eng katta amplituda (0...32767).
        level = Double(current.maxAmplitude) / 32767.0
        #else
        current.updateMeters()
        let decibels = Double(current.peakPower(forChannel: 0))
        level = pow(10.0, decibels / 20.0)
        #endif
        if level > peakLevel {
            peakLevel = level
        }
    }

    #if !SKIP
    private static func requestMicrophonePermission() async -> Bool {
        return await withCheckedContinuation { continuation in
            AVAudioApplication.requestRecordPermission { granted in
                continuation.resume(returning: granted)
            }
        }
    }
    #endif
}
