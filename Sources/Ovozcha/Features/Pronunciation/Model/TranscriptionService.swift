import Foundation

enum TranscriptionError: Error, Equatable, Sendable {
    /// Internet yo'q yoki vaqt tugadi.
    case offline
    /// Server xato qaytardi yoki javob tushunarsiz.
    case server
}

/// Yozilgan ovozni matnga aylantiruvchi xizmat (nutq tanish).
///
/// Ilova o'zi ovozni tahlil qilmaydi: server matnni qaytaradi, baholash esa `PronunciationScoring`
/// da ilovaning o'zida bajariladi. Shu sababli serverga ixtiyoriy nutq tanish xizmati
/// (Whisper, Azure, Google va boshqalar) ulanadi, ilova o'zgarmaydi.
protocol TranscriptionService: Sendable {
    func transcribe(fileURL: URL) async throws -> String
}

/// Oddiy HTTP shartnoma:
///
///     POST <endpoint>
///     Content-Type: audio/mp4        (AAC/m4a, 16 kHz, mono)
///     Accept-Language: uz
///     tana: audio baytlari
///
///     200 OK  {"transcript": "olma"}
///
/// API kalitlari ilova ichida SAQLANMAYDI: endpoint o'zingizning serveringiz bo'lishi kerak
/// (u kalit bilan tashqi xizmatga murojaat qiladi va bola ovozini saqlamaydi).
struct HTTPTranscriptionService: TranscriptionService {
    let endpoint: URL

    private struct Reply: Decodable {
        let transcript: String
    }

    func transcribe(fileURL: URL) async throws -> String {
        let audio: Data
        do {
            audio = try Data(contentsOf: fileURL)
        } catch {
            throw TranscriptionError.server
        }

        var request = URLRequest(url: endpoint, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue("audio/mp4", forHTTPHeaderField: "Content-Type")
        request.setValue("uz", forHTTPHeaderField: "Accept-Language")
        // Skip'da `upload(for:from:)` tanani biriktirmaydi (yuqoridagi izohga qarang).
        request.httpBody = audio

        do {
            let (body, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
                throw TranscriptionError.server
            }
            return try JSONDecoder().decode(Reply.self, from: body).transcript
        } catch let error as TranscriptionError {
            throw error
        } catch {
            // Android'da tarmoq xatosi `URLError` emas (`NetworkErrors` ga qarang).
            throw NetworkErrors.isOffline(error) ? TranscriptionError.offline : TranscriptionError.server
        }
    }
}

/// Groq (Whisper) ga TO'G'RIDAN-TO'G'RI murojaat — FAQAT ISHLAB CHIQISH uchun.
///
/// Ogohlantirish: kalit ilovada bo'lsa, uni APK/IPA dan chiqarib olish mumkin va
/// begona odam sizning hisobingizdan foydalanadi. Do'konga chiqarishdan oldin
/// `HTTPTranscriptionService` (o'z serveringiz) ga o'ting.
struct GroqTranscriptionService: TranscriptionService {
    let apiKey: String

    /// Groq'ning OpenAI-mos endpointi.
    private var endpoint: URL {
        return URL(string: "https://api.groq.com/openai/v1/audio/transcriptions")!
    }

    private struct Reply: Decodable {
        let text: String
    }

    func transcribe(fileURL: URL) async throws -> String {
        let audio: Data
        do {
            audio = try Data(contentsOf: fileURL)
        } catch {
            throw TranscriptionError.server
        }

        let boundary = "ovozcha-" + UUID().uuidString
        var body = Data()
        body.append(Self.part(boundary: boundary, name: "model", value: "whisper-large-v3"))
        // O'zbek tili: usiz Whisper tilni o'zi topadi va ko'pincha rus/turk deb xato qiladi.
        body.append(Self.part(boundary: boundary, name: "language", value: "uz"))
        body.append(Self.part(boundary: boundary, name: "response_format", value: "json"))
        body.append(Self.filePart(boundary: boundary, name: "file", fileName: "audio.m4a",
                                  contentType: "audio/mp4", data: audio))
        body.append(Self.utf8("--" + boundary + "--\r\n"))

        var request = URLRequest(url: endpoint, timeoutInterval: 20)
        request.httpMethod = "POST"
        request.setValue("Bearer " + apiKey, forHTTPHeaderField: "Authorization")
        request.setValue("multipart/form-data; boundary=" + boundary, forHTTPHeaderField: "Content-Type")
        // Tana `httpBody` orqali beriladi: Skip'da `upload(for:from:)` uni so'rovga
        // biriktirmaydi va OkHttp "method POST must have a request body" deb xato beradi.
        request.httpBody = body

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode >= 200, http.statusCode < 300 else {
                // Diqqat: javob tanasi jurnalga yozilmaydi — unda bolaning nutqi bo'lishi mumkin.
                logger.info("Nutq tanish: server HTTP \((response as? HTTPURLResponse)?.statusCode ?? -1)")
                throw TranscriptionError.server
            }
            return try JSONDecoder().decode(Reply.self, from: data).text
        } catch let error as TranscriptionError {
            throw error
        } catch {
            // Android'da tarmoq xatosi `URLError` emas (`NetworkErrors` ga qarang).
            if NetworkErrors.isOffline(error) {
                throw TranscriptionError.offline
            }
            logger.info("Nutq tanish: \(String(describing: error))")
            throw TranscriptionError.server
        }
    }

    // MARK: Multipart yig'ish

    private static func utf8(_ text: String) -> Data {
        return text.data(using: String.Encoding.utf8) ?? Data()
    }

    private static func part(boundary: String, name: String, value: String) -> Data {
        return utf8("--" + boundary + "\r\n"
            + "Content-Disposition: form-data; name=\"" + name + "\"\r\n\r\n"
            + value + "\r\n")
    }

    private static func filePart(boundary: String, name: String, fileName: String,
                                 contentType: String, data: Data) -> Data {
        var part = Data()
        part.append(utf8("--" + boundary + "\r\n"
            + "Content-Disposition: form-data; name=\"" + name + "\"; filename=\"" + fileName + "\"\r\n"
            + "Content-Type: " + contentType + "\r\n\r\n"))
        part.append(data)
        part.append(utf8("\r\n"))
        return part
    }

}

enum PronunciationConfig {

    /// Sozlangan xizmat. Tartib muhim:
    /// 1. O'z serveringiz (`OvozchaTranscriptionEndpoint`) — kalit ilovada emas.
    /// 2. Groq kaliti (`OvozchaGroqKey`) — faqat ishlab chiqish uchun.
    /// Ikkalasi ham yo'q bo'lsa `nil`: u holda ilova ovozni faqat yozib qayta eshittiradi.
    static func makeTranscriber() -> (any TranscriptionService)? {
        if let raw = OvozchaConfig.value(for: OvozchaConfig.transcriptionEndpointKey),
           let url = URL(string: raw),
           url.scheme?.lowercased() == "https",
           url.host != nil {
            return HTTPTranscriptionService(endpoint: url)
        }
        if let key = OvozchaConfig.value(for: OvozchaConfig.groqKeyKey) {
            return GroqTranscriptionService(apiKey: key)
        }
        return nil
    }
}
