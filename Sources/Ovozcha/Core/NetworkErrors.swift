import Foundation

/// Tarmoq xatosi "internet yo'q" turidanmi. IOS va Android (Skip) uchun umumiy.
///
/// Nega alohida: Android'da (Skip) `URLSession` tarmoq xatolarini `URLError` qilib EMAS,
/// asl Java istisnosini o'rab (`ErrorException(IOException)`) qaytaradi. Shuning uchun
/// `catch let error as URLError` Android'da hech qachon ishlamaydi va internet yo'qligi
/// "server xatosi" deb ko'rsatilardi.
enum NetworkErrors {

    /// Ulanishga oid so'rov: `URLRequest(url:timeoutInterval:)` uchun. Standart 60 s —
    /// internet yo'qligini bilish uchun juda uzoq.
    static let requestTimeout: Double = 30.0

    static func isOffline(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            return isOfflineCode(urlError.code)
        }
        #if SKIP
        // Istisnolar zanjiri: ErrorException -> IOException -> ...
        var current: kotlin.Throwable? = error as? kotlin.Throwable
        var depth = 0
        while let throwable = current, depth < 8 {
            if throwable is java.net.UnknownHostException
                || throwable is java.net.ConnectException
                || throwable is java.net.NoRouteToHostException
                || throwable is java.io.InterruptedIOException {
                // InterruptedIOException: OkHttp vaqt chegarasi (SocketTimeoutException ham shu).
                return true
            }
            current = throwable.cause
            depth += 1
        }
        #endif
        return false
    }

    static func isOfflineCode(_ code: URLError.Code) -> Bool {
        switch code {
        case URLError.Code.notConnectedToInternet, URLError.Code.timedOut,
             URLError.Code.networkConnectionLost, URLError.Code.cannotFindHost,
             URLError.Code.cannotConnectToHost:
            return true
        default:
            return false
        }
    }
}
