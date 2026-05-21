import Foundation
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    private var audioRecorder: AVAudioRecorder?
    private var fileURL: URL?
    private(set) var isRecording = false
    
    // Check and request microphone permission
    func checkPermission(completion: @escaping (Bool) -> Void) {
        if #available(macOS 14.0, *) {
            AVAudioApplication.requestRecordPermission { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        } else {
            // Pre-macOS 14 fallback
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    completion(granted)
                }
            }
        }
    }
    
    func startRecording() -> Bool {
        guard !isRecording else { return false }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileName = "asr_recording_\(UUID().uuidString).m4a"
        let outputURL = tempDirectory.appendingPathComponent(fileName)
        self.fileURL = outputURL
        
        // Compact speech recording settings optimized for ASR Whisper
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16000.0, // Whisper works best at 16kHz
            AVNumberOfChannelsKey: 1,  // Mono
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
            AVEncoderBitRateKey: 24000 // Very light file size
        ]
        
        do {
            audioRecorder = try AVAudioRecorder(url: outputURL, settings: settings)
            audioRecorder?.delegate = self
            audioRecorder?.isMeteringEnabled = true
            
            if audioRecorder?.prepareToRecord() == true {
                audioRecorder?.record()
                isRecording = true
                print("Started recording to \(outputURL.path)")
                return true
            }
        } catch {
            print("Failed to set up audio recorder: \(error.localizedDescription)")
        }
        
        return false
    }
    
    func stopRecording() -> URL? {
        guard isRecording else { return nil }
        
        audioRecorder?.stop()
        isRecording = false
        print("Stopped recording. File saved to \(fileURL?.path ?? "")")
        
        let recordedURL = fileURL
        audioRecorder = nil
        return recordedURL
    }
    
    // Returns a normalized level between 0.0 (silent) and 1.0 (loud)
    func getAudioLevel() -> Float {
        guard isRecording, let recorder = audioRecorder else { return 0.0 }
        
        recorder.updateMeters()
        let power = recorder.averagePower(forChannel: 0)
        
        // Convert dB scale (-60 to 0) to linear scale (0 to 1)
        let minDb: Float = -60.0
        if power < minDb {
            return 0.0
        } else if power >= 0.0 {
            return 1.0
        } else {
            return (power - minDb) / -minDb
        }
    }
    
    func cleanup() {
        if isRecording {
            _ = stopRecording()
        }
        if let url = fileURL {
            try? FileManager.default.removeItem(at: url)
            fileURL = nil
        }
    }
}
