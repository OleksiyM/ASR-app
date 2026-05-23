import Foundation
import Cocoa
import Carbon
import SwiftUI

enum AppStatus: Equatable {
    case idle
    case recording
    case uploading
    case transcribing
    case success(String)
    case failure(String)
}

enum HotkeyOption: String, CaseIterable, Identifiable {
    case optionSpace = "option_space"
    case controlSpace = "control_space"
    case optionZ = "option_z"
    case cmdShiftK = "cmd_shift_k"
    case cmdOptionK = "cmd_option_k"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .optionSpace: return "Option + Space (⌥Space)"
        case .controlSpace: return "Control + Space (⌃Space)"
        case .optionZ: return "Option + Z (⌥Z)"
        case .cmdShiftK: return "Cmd + Shift + K (⌘⇧K)"
        case .cmdOptionK: return "Cmd + Option + K (⌘⌥K)"
        }
    }
    
    var keyCode: UInt32 {
        switch self {
        case .optionSpace, .controlSpace: return 49
        case .optionZ: return 6
        case .cmdShiftK, .cmdOptionK: return 40
        }
    }
    
    var modifiers: UInt32 {
        switch self {
        case .optionSpace: return 0x0800
        case .controlSpace: return 0x1000
        case .optionZ: return 0x0800
        case .cmdShiftK: return 0x0100 | 0x0200 // cmd + shift
        case .cmdOptionK: return 0x0100 | 0x0800 // cmd + option
        }
    }
}

enum LanguageOption: String, CaseIterable, Identifiable {
    case auto = "auto"
    case ru = "ru"
    case en = "en"
    case uk = "uk" // Added Ukrainian (ISO 'uk')
    
    var id: String { self.rawValue }
}

enum UILanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case en = "en"
    case ru = "ru"
    case ua = "ua"
    
    var id: String { self.rawValue }
}

enum ThemeOption: String, CaseIterable, Identifiable {
    case system = "system"
    case dark = "dark"
    case light = "light"
    
    var id: String { self.rawValue }
}

class AppState: ObservableObject {
    @Published var status: AppStatus = .idle
    @Published var audioLevel: Float = 0.0
    @Published var recordingDuration: TimeInterval = 0.0
    @Published var lastTranscription: String = ""
    
    // Settings persisted in UserDefaults
    @Published var groqApiKey: String {
        didSet {
            UserDefaults.standard.set(groqApiKey, forKey: "groq_api_key")
        }
    }
    
    @Published var autoPasteEnabled: Bool {
        didSet {
            UserDefaults.standard.set(autoPasteEnabled, forKey: "auto_paste_enabled")
        }
    }
    
    @Published var selectedLanguage: String {
        didSet {
            UserDefaults.standard.set(selectedLanguage, forKey: "selected_language")
        }
    }
    
    @Published var selectedHotkey: String {
        didSet {
            UserDefaults.standard.set(selectedHotkey, forKey: "selected_hotkey")
            setupHotkey()
        }
    }
    
    @Published var selectedUILanguage: String {
        didSet {
            UserDefaults.standard.set(selectedUILanguage, forKey: "selected_ui_language")
        }
    }
    
    @Published var selectedTheme: String {
        didSet {
            UserDefaults.standard.set(selectedTheme, forKey: "selected_theme")
            updateApplicationAppearance()
        }
    }
    
    @Published var maxRecordingDuration: Double {
        didSet {
            UserDefaults.standard.set(maxRecordingDuration, forKey: "max_recording_duration")
        }
    }
    
    @Published var customVocabulary: String {
        didSet {
            UserDefaults.standard.set(customVocabulary, forKey: "custom_vocabulary")
        }
    }
    
    // Auto-update states
    @Published var isUpdateAvailable = false
    @Published var serverLatestVersion = ""
    @Published var updateURL = ""
    @Published var isCheckingForUpdates = false
    @Published var updateCheckStatusMessage: String? = nil
    
    private let recorder = AudioRecorder()
    private let apiService = GroqWhisperService()
    private var timer: Timer?
    private var updateTimer: Timer?
    
    init() {
        // Load settings
        self.groqApiKey = UserDefaults.standard.string(forKey: "groq_api_key") ?? ""
        self.autoPasteEnabled = UserDefaults.standard.bool(forKey: "auto_paste_enabled")
        self.selectedLanguage = UserDefaults.standard.string(forKey: "selected_language") ?? "auto"
        self.selectedHotkey = UserDefaults.standard.string(forKey: "selected_hotkey") ?? HotkeyOption.optionSpace.rawValue
        self.selectedUILanguage = UserDefaults.standard.string(forKey: "selected_ui_language") ?? "system"
        self.selectedTheme = UserDefaults.standard.string(forKey: "selected_theme") ?? "system"
        
        self.customVocabulary = UserDefaults.standard.string(forKey: "custom_vocabulary") ?? ""
        
        self.maxRecordingDuration = UserDefaults.standard.double(forKey: "max_recording_duration")
        if self.maxRecordingDuration == 0.0 {
            self.maxRecordingDuration = 180.0
            UserDefaults.standard.set(180.0, forKey: "max_recording_duration")
        }
        
        // Register default state for auto-paste (default to true on first launch)
        if UserDefaults.standard.object(forKey: "auto_paste_enabled") == nil {
            self.autoPasteEnabled = true
            UserDefaults.standard.set(true, forKey: "auto_paste_enabled")
        }
        
        setupHotkey()
        
        // Apply appearance asynchronously after window initialization
        DispatchQueue.main.async {
            self.updateApplicationAppearance()
        }
        
        // Trigger background update check
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            self?.checkForUpdates(explicit: false)
        }
        
        // Set up daily background update check timer (every 24 hours = 86400 seconds)
        self.updateTimer = Timer.scheduledTimer(withTimeInterval: 86400, repeats: true) { [weak self] _ in
            self?.checkForUpdates(explicit: false)
        }
    }
    
    func setupHotkey() {
        GlobalHotkeyManager.shared.onTrigger = { [weak self] in
            guard let self = self else { return }
            self.toggleRecording()
        }
        
        let hotkeyRaw = UserDefaults.standard.string(forKey: "selected_hotkey") ?? HotkeyOption.optionSpace.rawValue
        let option = HotkeyOption(rawValue: hotkeyRaw) ?? .optionSpace
        
        GlobalHotkeyManager.shared.register(keyCode: option.keyCode, modifiers: option.modifiers)
    }
    
    func toggleRecording() {
        if status == .recording {
            stopRecordingAndTranscribe()
        } else if status == .idle || isResetState() {
            startRecordingWithPermission()
        }
    }
    
    private func isResetState() -> Bool {
        switch status {
        case .success, .failure: return true
        default: return false
        }
    }
    
    private func startRecordingWithPermission() {
        recorder.checkPermission { [weak self] granted in
            guard let self = self else { return }
            
            if granted {
                self.startRecording()
            } else {
                self.status = .failure(self.localizedString("no_mic_access"))
                self.scheduleIdleReset(after: 4.0)
            }
        }
    }
    
    private func startRecording() {
        timer?.invalidate()
        recordingDuration = 0.0
        audioLevel = 0.0
        
        let success = recorder.startRecording()
        if success {
            status = .recording
            
            // Timer for UI levels and recording duration
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                self.recordingDuration += 0.05
                self.audioLevel = self.recorder.getAudioLevel()
                
                // Safety limit from user settings
                if self.recordingDuration >= self.maxRecordingDuration {
                    self.stopRecordingAndTranscribe()
                }
            }
        } else {
            status = .failure(self.localizedString("failed_to_start"))
            scheduleIdleReset(after: 4.0)
        }
    }
    
    private func stopRecordingAndTranscribe() {
        timer?.invalidate()
        timer = nil
        
        guard let fileURL = recorder.stopRecording() else {
            status = .failure(self.localizedString("file_not_found"))
            scheduleIdleReset(after: 4.0)
            return
        }
        
        status = .uploading
        
        let baseStylePrompt = "Hello! This is a dynamic, high-quality transcription with perfect punctuation: commas, periods, dashes, and question marks. OK? Привет! Это качественная запись с идеальной пунктуацией."
        var finalPrompt = baseStylePrompt
        let cleanVocab = customVocabulary.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanVocab.isEmpty {
            finalPrompt += " Terms: " + cleanVocab
        }
        
        apiService.transcribe(fileURL: fileURL, apiKey: groqApiKey, language: selectedLanguage, prompt: finalPrompt) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                // Cleanup temp file
                self.recorder.cleanup()
                
                switch result {
                case .success(let text):
                    let cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    self.lastTranscription = cleanedText
                    
                    // Copy to clipboard
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    pasteboard.setString(cleanedText, forType: .string)
                    
                    self.status = .success(cleanedText)
                    print("ASR Success: \(cleanedText)")
                    
                    // Auto-paste if enabled
                    if self.autoPasteEnabled {
                        KeystrokeSimulator.simulatePaste()
                    }
                    
                    self.scheduleIdleReset(after: 3.0)
                    
                case .failure(let error):
                    let errorMessage: String
                    if let serviceError = error as? GroqWhisperService.ServiceError {
                        switch serviceError {
                        case .invalidURL:
                            errorMessage = self.localizedString("error_invalid_url")
                        case .missingAPIKey:
                            errorMessage = self.localizedString("error_missing_api_key")
                        case .badResponse(let code):
                            errorMessage = String(format: self.localizedString("error_bad_response"), code)
                        case .decodingError:
                            errorMessage = self.localizedString("error_decoding_error")
                        case .noData:
                            errorMessage = self.localizedString("error_no_data")
                        }
                    } else {
                        errorMessage = error.localizedDescription
                    }
                    self.status = .failure(errorMessage)
                    self.scheduleIdleReset(after: 5.0)
                }
            }
        }
    }
    
    func resetToIdle() {
        timer?.invalidate()
        timer = nil
        recorder.cleanup()
        status = .idle
    }
    
    private func scheduleIdleReset(after seconds: TimeInterval) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: seconds, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            if self.isResetState() {
                self.status = .idle
            }
        }
    }
    
    // UI Theme color scheme mapping
    var colorScheme: ColorScheme? {
        switch selectedTheme {
        case "dark": return .dark
        case "light": return .light
        default: return nil // System appearance
        }
    }
    
    // Force AppKit window appearance update
    func updateApplicationAppearance() {
        DispatchQueue.main.async {
            let appearance: NSAppearance?
            switch self.selectedTheme {
            case "dark":
                appearance = NSAppearance(named: .darkAqua)
            case "light":
                appearance = NSAppearance(named: .aqua)
            default:
                appearance = nil // Inherit from system
            }
            
            print("Applying appearance: \(self.selectedTheme) to NSApp and windows. Total windows: \(NSApp.windows.count)")
            NSApp.appearance = appearance
            
            for window in NSApp.windows {
                window.appearance = appearance
                // Force window content view appearance update
                window.contentView?.appearance = appearance
            }
        }
    }
    
    // Dynamic localization helper
    func localizedString(_ key: String) -> String {
        let activeLang: String
        if selectedUILanguage == "system" {
            let preferred = Locale.preferredLanguages.first?.prefix(2) ?? "en"
            activeLang = ["en", "ru", "ua"].contains(preferred) ? String(preferred) : "en"
        } else {
            activeLang = selectedUILanguage
        }
        
        let translations: [String: [String: String]] = [
            "en": [
                "ready_to_record": "Click to record",
                "recording": "Recording...",
                "uploading": "Uploading to Whisper...",
                "transcribing": "Transcribing audio...",
                "success": "Success!",
                "success_copied": "Copied to clipboard!",
                "success_pasted": "Pasted & Copied!",
                "done": "Done",
                "back": "Go Back",
                "paste": "Paste",
                "no_mic_access": "No microphone access",
                "file_not_found": "Recording file not found",
                "failed_to_start": "Failed to start recording",
                "settings_title": "ASR-app Settings",
                "settings_groq": "Groq API Settings",
                "enter_api_key": "Enter Groq API Key",
                "api_hint": "You can get your key at console.groq.com. Audio is transcribed via Whisper Large V3 Turbo for instant results.",
                "integration": "Transcription Options",
                "auto_paste_toggle": "Auto-paste text automatically",
                "auto_paste_hint": "If enabled, recognized text is automatically pasted into the active app using simulated Cmd+V.",
                "recording_lang": "Audio Language:",
                "ui_lang": "UI Language:",
                "theme_title": "Appearance Theme:",
                "theme_system": "System",
                "theme_dark": "Dark",
                "theme_light": "Light",
                "hotkey_title": "Global Shortcut",
                "hotkey_lbl": "Shortcut Key:",
                "hotkey_hint": "Use the selected shortcut globally from anywhere.",
                "hotkey_desc": "Press once to start recording, and press again to stop and transcribe.",
                "configure_api_key": "Configure API Key",
                "settings_ui_header": "Appearance & Language",
                "lang_auto": "Auto-detect",
                "lang_ru": "Russian (ru)",
                "lang_en": "English (en)",
                "lang_uk": "Ukrainian (uk)",
                "ui_lang_system": "System Default",
                "ui_lang_en": "English",
                "ui_lang_ru": "Russian",
                "ui_lang_ua": "Ukrainian",
                "exit": "Exit",
                "whisper_model_info": "Using Whisper Large V3 Turbo",
                "about_title": "About ASR-app",
                "about_desc": "Instant, system-wide speech to text powered by Whisper Large V3 Turbo.",
                "about_credits": "Created by Eva for Alex with love & tea 🫂🍵✨",
                "version": "Version",
                "error_invalid_url": "Invalid API URL",
                "error_missing_api_key": "Groq API Key is not configured",
                "error_bad_response": "Groq server error: %d",
                "error_decoding_error": "Failed to parse server response",
                "error_no_data": "Server returned empty response",
                "max_duration_lbl": "Max duration:",
                "duration_1min": "1 minute",
                "duration_2min": "2 minutes",
                "duration_3min": "3 minutes (Default)",
                "duration_5min": "5 minutes",
                "duration_10min": "10 minutes",
                "warning_auto_stop": "Auto-stop in %d sec",
                "custom_vocab_title": "Custom Vocabulary (Terms & Names):",
                "custom_vocab_hint": "Enter custom terms or names separated by commas (up to 30-50 words). Model will use them to recognize complex words.",
                "update_available": "Update Available!",
                "update_btn": "Update",
                "checking_updates": "Checking for updates...",
                "up_to_date": "You're up to date!",
                "update_failed": "Update check failed",
                "check_updates": "Check for Updates"
            ],
            "ru": [
                "ready_to_record": "Нажмите для записи",
                "recording": "Запись...",
                "uploading": "Отправка в Whisper...",
                "transcribing": "Расшифровка...",
                "success": "Успешно!",
                "success_copied": "Скопировано в буфер!",
                "success_pasted": "Вставлено и скопировано!",
                "done": "Готово",
                "back": "Вернуться",
                "paste": "Вставка",
                "no_mic_access": "Нет доступа к микрофону",
                "file_not_found": "Файл записи не найден",
                "failed_to_start": "Не удалось начать запись",
                "settings_title": "Настройки ASR-app",
                "settings_groq": "Настройки Groq API",
                "enter_api_key": "Введите Groq API Key",
                "api_hint": "Получить ключ можно в консоли console.groq.com. Запись отправляется в Whisper Large V3 Turbo для моментального распознавания.",
                "integration": "Параметры распознавания",
                "auto_paste_toggle": "Автоматически вставлять текст",
                "auto_paste_hint": "Если включено, после распознавания текст автоматически вставится в текущее активное приложение с помощью симуляции клавиш Cmd+V.",
                "recording_lang": "Язык записи:",
                "ui_lang": "Язык интерфейса:",
                "theme_title": "Тема оформления:",
                "theme_system": "Системная",
                "theme_dark": "Темная",
                "theme_light": "Светлая",
                "hotkey_title": "Глобальный Хоткей",
                "hotkey_lbl": "Сочетание клавиш:",
                "hotkey_hint": "Используйте выбранный хоткей из любого места в macOS",
                "hotkey_desc": "Нажмите эту комбинацию для начала записи, и нажмите повторно, чтобы остановить запись и отправить на распознавание.",
                "configure_api_key": "Укажите API-ключ",
                "settings_ui_header": "Внешний вид и язык",
                "lang_auto": "Автоопределение",
                "lang_ru": "Русский (ru)",
                "lang_en": "Английский (en)",
                "lang_uk": "Украинский (uk)",
                "ui_lang_system": "По умолчанию системный",
                "ui_lang_en": "Английский (English)",
                "ui_lang_ru": "Русский",
                "ui_lang_ua": "Украинский (Українська)",
                "exit": "Выйти",
                "whisper_model_info": "Используем Whisper Large V3 Turbo",
                "about_title": "О программе ASR-app",
                "about_desc": "Мгновенный ввод текста голосом в любом приложении на базе Whisper Large V3 Turbo.",
                "about_credits": "Создано Эвой для Алекса с любовью и чаем 🫂🍵✨",
                "version": "Версия",
                "error_invalid_url": "Некорректный URL API",
                "error_missing_api_key": "API-ключ Groq не настроен",
                "error_bad_response": "Ошибка сервера Groq: %d",
                "error_decoding_error": "Не удалось распознать ответ сервера",
                "error_no_data": "Сервер вернул пустой ответ",
                "max_duration_lbl": "Макс. время записи:",
                "duration_1min": "1 минута",
                "duration_2min": "2 минуты",
                "duration_3min": "3 минуты (По умолчанию)",
                "duration_5min": "5 минут",
                "duration_10min": "10 минут",
                "warning_auto_stop": "Автостоп через %d сек",
                "custom_vocab_title": "Пользовательский словарь (термины и имена):",
                "custom_vocab_hint": "Введите через запятую специфические термины или имена (не более 30-50 слов). Модель будет использовать их для распознавания сложных слов.",
                "update_available": "Доступно обновление!",
                "update_btn": "Обновить",
                "checking_updates": "Проверка обновлений...",
                "up_to_date": "У вас актуальная версия!",
                "update_failed": "Ошибка проверки обновлений",
                "check_updates": "Проверить обновления"
            ],
            "ua": [
                "ready_to_record": "Натисніть для запису",
                "recording": "Запис...",
                "uploading": "Надсилання у Whisper...",
                "transcribing": "Розшифровка...",
                "success": "Успішно!",
                "success_copied": "Скопійовано в буфер!",
                "success_pasted": "Вставлено та скопійовано!",
                "done": "Готово",
                "back": "Повернутися",
                "paste": "Вставка",
                "no_mic_access": "Немає доступу до мікрофона",
                "file_not_found": "Файл запису не знайдено",
                "failed_to_start": "Не вдалося розпочати запис",
                "settings_title": "Налаштування ASR-app",
                "settings_groq": "Налаштування Groq API",
                "enter_api_key": "Введіть Groq API Key",
                "api_hint": "Отримати ключ можна в консолі console.groq.com. Запись надсилається у Whisper Large V3 Turbo для моментального розпізнавання.",
                "integration": "Параметри розпізнавання",
                "auto_paste_toggle": "Автоматично вставлять текст",
                "auto_paste_hint": "Якщо увімкнено, після розпізнавання текст автоматически вставиться в поточний активний додаток за допомогою симуляції клавіш Cmd+V.",
                "recording_lang": "Мова запису:",
                "ui_lang": "Мова інтерфейсу:",
                "theme_title": "Тема оформлення:",
                "theme_system": "Системна",
                "theme_dark": "Темная",
                "theme_light": "Світла",
                "hotkey_title": "Глобальний Хоткей",
                "hotkey_lbl": "Сполучення клавіш:",
                "hotkey_hint": "Використовуйте обраний хоткей з будь-якого місця в macOS",
                "hotkey_desc": "Натисніть цю комбінацію для початку запису, та натисніть повторно, щоб зупинити запис та відправити на розпізнавання.",
                "configure_api_key": "Вкажіть API-ключ",
                "settings_ui_header": "Зовнішній вигляд та мова",
                "lang_auto": "Автовизначення",
                "lang_ru": "Російська (ru)",
                "lang_en": "Англійська (en)",
                "lang_uk": "Українська (uk)",
                "ui_lang_system": "За замовчуванням системна",
                "ui_lang_en": "Англійська (English)",
                "ui_lang_ru": "Російська (Русский)",
                "ui_lang_ua": "Українська",
                "exit": "Вийти",
                "whisper_model_info": "Використовуємо Whisper Large V3 Turbo",
                "about_title": "Про програму ASR-app",
                "about_desc": "Миттєве введення тексту голосом в будь-якому додатку на базі Whisper Large V3 Turbo.",
                "about_credits": "Створено Евою для Алекса з любов'ю та чаем 🫂🍵✨",
                "version": "Версія",
                "error_invalid_url": "Некоректний URL API",
                "error_missing_api_key": "API-ключ Groq не налаштований",
                "error_bad_response": "Помилка сервера Groq: %d",
                "error_decoding_error": "Не вдалося розпізнати відповідь сервера",
                "error_no_data": "Сервер повернув порожню відповідь",
                "max_duration_lbl": "Макс. час запису:",
                "duration_1min": "1 хвилина",
                "duration_2min": "2 хвилини",
                "duration_3min": "3 хвилини (Типово)",
                "duration_5min": "5 хвилин",
                "duration_10min": "10 хвилин",
                "warning_auto_stop": "Автостоп через %d сек",
                "custom_vocab_title": "Словник користувача (терміни та імена):",
                "custom_vocab_hint": "Введіть через кому специфічні терміни або імена (не більше 30-50 слів). Модель використовуватиме їх для розпізнавання складних слів.",
                "update_available": "Доступне оновлення!",
                "update_btn": "Оновити",
                "checking_updates": "Перевірка оновлень...",
                "up_to_date": "У вас остання версія!",
                "update_failed": "Помилка перевірки оновлень",
                "check_updates": "Перевірити оновлення"
            ]
        ]
        
        let dict = translations[activeLang] ?? translations["en"]!
        return dict[key] ?? key
    }
    
    // Background and manual update checkers
    func checkForUpdates(explicit: Bool = false) {
        guard !isCheckingForUpdates else { return }
        
        isCheckingForUpdates = true
        if explicit {
            updateCheckStatusMessage = localizedString("checking_updates")
        }
        
        guard let url = URL(string: "https://oleksiym.github.io/ASR-app/version.json") else {
            isCheckingForUpdates = false
            if explicit {
                updateCheckStatusMessage = localizedString("update_failed")
            }
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.isCheckingForUpdates = false
                
                if let error = error {
                    print("Update check error: \(error.localizedDescription)")
                    if explicit {
                        self.updateCheckStatusMessage = self.localizedString("update_failed")
                    }
                    return
                }
                
                guard let data = data else {
                    if explicit {
                        self.updateCheckStatusMessage = self.localizedString("update_failed")
                    }
                    return
                }
                
                do {
                    struct VersionConfig: Codable {
                        let latestVersion: String
                        let urls: [String: String]
                    }
                    
                    let config = try JSONDecoder().decode(VersionConfig.self, from: data)
                    let localVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.2.3"
                    
                    if self.isVersion(config.latestVersion, newerThan: localVersion) {
                        self.isUpdateAvailable = true
                        self.serverLatestVersion = config.latestVersion
                        
                        let arch: String
                        #if arch(arm64)
                        arch = "arm64"
                        #else
                        arch = "x86_64"
                        #endif
                        
                        self.updateURL = config.urls[arch] ?? "https://github.com/OleksiyM/ASR-app/releases/latest"
                        
                        if explicit {
                            self.updateCheckStatusMessage = String(format: self.localizedString("update_available") + " \(config.latestVersion)")
                        }
                    } else {
                        self.isUpdateAvailable = false
                        if explicit {
                            self.updateCheckStatusMessage = self.localizedString("up_to_date")
                        }
                    }
                } catch {
                    print("Failed to decode version configuration: \(error)")
                    if explicit {
                        self.updateCheckStatusMessage = self.localizedString("update_failed")
                    }
                }
            }
        }
        task.resume()
    }
    
    private func isVersion(_ serverVersion: String, newerThan localVersion: String) -> Bool {
        let serverComponents = serverVersion.split(separator: ".").compactMap { Int($0) }
        let localComponents = localVersion.split(separator: ".").compactMap { Int($0) }
        
        for i in 0..<max(serverComponents.count, localComponents.count) {
            let serverValue = i < serverComponents.count ? serverComponents[i] : 0
            let localValue = i < localComponents.count ? localComponents[i] : 0
            if serverValue > localValue { return true }
            if serverValue < localValue { return false }
        }
        return false
    }
    
    deinit {
        timer?.invalidate()
        updateTimer?.invalidate()
        recorder.cleanup()
        GlobalHotkeyManager.shared.unregister()
    }
}
