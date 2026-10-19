#if SKIP
import Foundation
import Observation

/// Harf va son tovushini ijro etadi (Android).
///
/// Yozuvlar Talaffuz murabbiyi bilan bir xil joyda: `Resources/Audio/letter_a.m4a`,
/// `number_5.m4a` ... Ijro `ClipPlayer` orqali (Android `MediaPlayer`, ilova ichidagi asset).
/// Fayl yo'q bo'lsa `play` `false` qaytaradi va ekran "ovozi hali qo'shilmagan" deydi.
@MainActor
@Observable
final class LetterAudioPlayer {

    private(set) var lastMissingFileName: String?

    @ObservationIgnored private let player = ClipPlayer()

    init() {
    }

    func hasRecording(for letter: UzbekLetter) -> Bool {
        return player.has(letter.audioFileName)
    }

    @discardableResult
    func play(_ letter: UzbekLetter) -> Bool {
        return play(fileName: letter.audioFileName)
    }

    @discardableResult
    func play(fileName: String) -> Bool {
        if player.play([fileName]) {
            lastMissingFileName = nil
            return true
        }
        lastMissingFileName = fileName
        return false
    }

    func stop() {
        player.stop()
    }
}

#else
import Foundation
import AVFoundation
import Observation

/// Harf tovushini ijro etadi.
///
/// Ovoz fayllari ilova bilan birga keladi: `Resources/Audio/letter_a.m4a`, `letter_b.m4a`,
/// `letter_o_apos.m4a` ... (`UzbekLetter.audioFileName`). Fayl yo'q bo'lsa hech narsa ijro
/// etilmaydi va UI buni bolaga aytadi.
///
/// Ataylab TTS (sintez qilingan ovoz) ishlatilmaydi: iOS'da o'zbek tili ovozi kafolatlanmagan, boshqa
/// til ovozi esa `q`, `x`, `gʻ`, `oʻ`, `ng` kabi tovushlarni noto'g'ri o'rgatardi.
@MainActor
@Observable
final class LetterAudioPlayer {

    /// Oxirgi marta ijro etib bo'lmagan fayl nomi (UI xabar ko'rsatishi uchun).
    private(set) var lastMissingFileName: String?

    @ObservationIgnored private var player: AVAudioPlayer?
    private static let extensions = ["m4a", "mp3", "wav", "caf"]
    private static let subdirectories: [String?] = [nil, "Audio", "Resources/Audio"]

    init() {
    }

    /// Bu harf uchun yozuv bormi.
    func hasRecording(for letter: UzbekLetter) -> Bool {
        locate(fileName: letter.audioFileName) != nil
    }

    /// Harf tovushini ijro etadi. Yozuv topilmasa `false` qaytaradi.
    @discardableResult
    func play(_ letter: UzbekLetter) -> Bool {
        play(fileName: letter.audioFileName)
    }

    /// Fayl nomi bo'yicha ijro etadi (`letter_a`, `number_5`). Yozuv topilmasa `false` qaytaradi.
    @discardableResult
    func play(fileName: String) -> Bool {
        guard let url = locate(fileName: fileName) else {
            lastMissingFileName = fileName
            #if DEBUG
            print("Ovoz topilmadi: \(fileName).m4a (Resources/Audio/ ichiga qo'shing)")
            #endif
            return false
        }
        lastMissingFileName = nil
        configureSession()
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.prepareToPlay()
            newPlayer.play()
            player = newPlayer
            return true
        } catch {
            lastMissingFileName = fileName
            return false
        }
    }

    func stop() {
        player?.stop()
        player = nil
    }

    // MARK: Ichki

    private func locate(fileName: String) -> URL? {
        let bundle = Bundle.module
        for ext in LetterAudioPlayer.extensions {
            for directory in LetterAudioPlayer.subdirectories {
                if let url = bundle.url(forResource: fileName, withExtension: ext, subdirectory: directory) {
                    return url
                }
            }
        }
        return nil
    }

    private func configureSession() {
        #if os(iOS)
        // Ovoz asosiy funksiya: jim rejimda ham eshitilishi kerak.
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
        #endif
    }
}
#endif
