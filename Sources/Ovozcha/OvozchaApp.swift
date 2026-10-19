import Foundation
import OSLog
import SwiftUI

let logger: Logger = Logger(subsystem: "Ovozcha", category: "Ovozcha")

/// Ilovaning umumiy ildiz ko'rinishi. iOS'da `Main.swift`, Android'da `Main.kt`
/// shu view'ni yuklaydi (Skip shabloni shuni talab qiladi, shuning uchun nomi
/// aynan `OvozchaRootView` bo'lishi va `public` bo'lishi shart).
public struct OvozchaRootView: View {
    @State private var router = AppRouter()
    @State private var profile = ProfileStore()

    public init() {
    }

    public var body: some View {
        // Ism kiritilmaguncha ilovaga kirib bo'lmaydi. Ism qurilmada saqlanadi,
        // shuning uchun `SetupView` faqat birinchi ochilishda ko'rinadi.
        Group {
            if profile.isSetUp {
                RootTabView()
            } else {
                SetupView()
            }
        }
            .environment(router)
            .environment(profile)
            // Harflar, Sonlar, Talaffuz va Ota-ona paneli uchun umumiy ombor va sozlamalar (iOS va Android).
            .modifier(LearningStoresModifier())
            // Dizayn maketi faqat yorug' rejimda berilgan. Qorong'i rejim palitrasi
            // tayyor bo'lgach, bu qator olib tashlanadi (DESIGN_RULES.md ga qarang).
            //
            // Android'da bu yerda emas, `Main.kt` dagi `OvozchaLightColors` da beriladi:
            // `preferredColorScheme` SkipUI'da preference sifatida yuqoriga qaytadi va
            // `PresentationRoot` dagi brend palitrasini Material You dinamik rangiga
            // almashtirib yuboradi.
            #if !SKIP
            .preferredColorScheme(.light)
            #endif
    }
}

/// Ilova hayot tsikli funksiyalari. `Main.swift` (iOS) va `Main.kt` (Android) shularni chaqiradi.
public final class OvozchaAppDelegate: Sendable {
    public static let shared = OvozchaAppDelegate()

    private init() {
    }

    public func onInit() {
        logger.debug("onInit")
        // Poppins shriftlarini ro'yxatdan o'tkazamiz (Info.plist'ga tegmasdan).
        // Birinchi ekran chizilishidan oldin chaqiriladi.
        AppFont.registerBundledFonts()
    }

    public func onLaunch() {
        logger.debug("onLaunch")
    }

    public func onResume() {
        logger.debug("onResume")
    }

    public func onPause() {
        logger.debug("onPause")
    }

    public func onStop() {
        logger.debug("onStop")
    }

    public func onDestroy() {
        logger.debug("onDestroy")
    }

    public func onLowMemory() {
        logger.debug("onLowMemory")
    }
}
