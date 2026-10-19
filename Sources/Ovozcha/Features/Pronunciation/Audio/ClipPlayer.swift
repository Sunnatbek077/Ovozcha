import Foundation
import Observation

#if SKIP
import android.media.MediaPlayer
#else
import AVFoundation
#endif

/// Murabbiy ovozini chaladi: ilova ichidagi yozuvlarni (`Resources/Audio/*.m4a`) ketma-ket
/// va bolaning o'z yozuvini. IOS va Android (Skip) uchun umumiy.
///
/// Ketma-ketlik davomiylik bo'yicha boshqariladi (har bo'lak tugashini kutib, keyingisi):
/// ikkala platformada bir xil ishlaydi va delegat/listener kerak emas.
@MainActor
@Observable
final class ClipPlayer {

    private(set) var isPlaying = false

    /// Bo'laklar orasidagi pauza (soniya): gap tabiiy eshitilsin.
    private static let gap = 0.08
    private static let extensions = ["m4a", "mp3", "wav"]

    @ObservationIgnored private var work: Task<Void, Never>?
    @ObservationIgnored private var located: [String: URL] = [:]
    @ObservationIgnored private var missing: Set<String> = []

    #if SKIP
    @ObservationIgnored private var player: MediaPlayer?
    #else
    @ObservationIgnored private var player: AVAudioPlayer?
    #endif

    init() {
    }

    // MARK: So'rovlar

    func has(_ clip: String) -> Bool {
        return locate(clip) != nil
    }

    func hasAll(_ clips: [String]) -> Bool {
        for clip in clips {
            if locate(clip) == nil { return false }
        }
        return true
    }

    // MARK: Ijro

    /// Bo'laklarni ketma-ket chaladi, keyin (berilsa) `file` ni. Bo'laklardan biri yo'q bo'lsa,
    /// ular chalinmaydi (yarim gap chalkashtiradi), faqat `file`. Nimadir chalinsa `true`.
    @discardableResult
    func play(_ clips: [String], then file: URL? = nil) -> Bool {
        var urls: [URL] = []
        if !clips.isEmpty && hasAll(clips) {
            for clip in clips {
                if let url = locate(clip) {
                    urls.append(url)
                }
            }
        }
        if let file = file {
            urls.append(file)
        }
        if urls.isEmpty {
            return false
        }
        playSequence(urls)
        return true
    }

    func stop() {
        work?.cancel()
        work = nil
        releaseCurrent()
        isPlaying = false
    }

    // MARK: Ichki

    private func playSequence(_ urls: [URL]) {
        stop()
        isPlaying = true
        work = Task {
            for url in urls {
                if Task.isCancelled { return }
                let duration = start(url)
                if duration <= 0.0 { continue }
                try? await Task.sleep(nanoseconds: UInt64((duration + ClipPlayer.gap) * 1_000_000_000.0))
            }
            if Task.isCancelled { return }
            releaseCurrent()
            isPlaying = false
        }
    }

    /// Faylni chala boshlaydi va davomiyligini (soniya) qaytaradi. Xato bo'lsa 0.
    private func start(_ url: URL) -> Double {
        releaseCurrent()

        #if SKIP

        let newPlayer = MediaPlayer()
        do {
            let address = url.absoluteString
            if address.hasPrefix("asset:") {
                // Ilova ichidagi yozuv: `asset:/ovozcha/module/Resources/Audio/x.m4a`.
                // m4a Android'da siqilmay saqlanadi, shuning uchun `openFd` ishlaydi.
                var path = url.path
                while path.hasPrefix("/") {
                    path = String(path.dropFirst())
                }
                let descriptor = ProcessInfo.processInfo.androidContext.assets.openFd(path)
                newPlayer.setDataSource(descriptor.fileDescriptor, descriptor.startOffset, descriptor.length)
                descriptor.close()
            } else {
                newPlayer.setDataSource(url.path)
            }
            newPlayer.prepare()
            newPlayer.start()
        } catch {
            android.util.Log.w("Ovozcha", "ovoz chalinmadi: \(url): \(error)")
            newPlayer.release()
            return 0.0
        }
        player = newPlayer
        return Double(newPlayer.duration) / 1000.0

        #else

        do {
            let session = AVAudioSession.sharedInstance()
            // Ovoz asosiy funksiya: jim rejimda ham eshitilishi kerak.
            try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try? session.setActive(true)
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
            return newPlayer.duration
        } catch {
            return 0.0
        }

        #endif
    }

    private func releaseCurrent() {
        #if SKIP
        if let current = player {
            current.stop()
            current.release()
        }
        #else
        player?.stop()
        #endif
        player = nil
    }

    /// Yozuvni topadi. iOS'da `Resources` tekislanadi (ildizda), Android'da `Audio/` papkasi saqlanadi.
    private func locate(_ clip: String) -> URL? {
        if let url = located[clip] { return url }
        if missing.contains(clip) { return nil }
        let directories: [String?] = [nil, "Audio"]
        for ext in ClipPlayer.extensions {
            for directory in directories {
                if let url = Bundle.module.url(forResource: clip, withExtension: ext, subdirectory: directory) {
                    located[clip] = url
                    return url
                }
            }
        }
        missing.insert(clip)
        return nil
    }
}
