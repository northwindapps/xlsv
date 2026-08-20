import Foundation
import Speech
import AVFoundation

// Shared by ViewController/FileFillViewController/PlaygroundViewController's speechButton.
// Streams live dictation into datainputview.stringbox until tapped again or speech ends.
// startNewSegment() resets the transcript mid-recording (e.g. after a voice
// command like "next") without stopping the mic, by swapping in a fresh
// recognition request/task -- SFSpeechRecognizer has no way to reset a
// transcript in place, it only ever grows within one request.
final class SpeechInputHelper: NSObject {

    private(set) var isRecording = false

    private var speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    // Bumped on every stop()/startNewSegment() so a stale completion handler
    // from a just-cancelled task (which can still fire once after cancel())
    // can recognize it's obsolete and skip calling onResult with old text.
    private var generation = 0

    private var onResult: ((String) -> Void)?
    private var onStateChange: ((Bool) -> Void)?

    func toggle(onResult: @escaping (String) -> Void, onStateChange: @escaping (Bool) -> Void) {
        self.onResult = onResult
        self.onStateChange = onStateChange

        if isRecording {
            stop()
        } else {
            requestAuthorizationAndStart()
        }
    }

    private func requestAuthorizationAndStart() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            print("speech: requestAuthorization ->", authStatus.rawValue)
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                print("speech: requestRecordPermission -> granted=\(granted)")
                DispatchQueue.main.async {
                    guard authStatus == .authorized, granted else {
                        print("speech: not starting -- authStatus=\(authStatus.rawValue) granted=\(granted)")
                        self?.onStateChange?(false)
                        return
                    }
                    self?.start()
                }
            }
        }
    }

    // Locale.current ("en_JP" on the test device) really was usable --
    // confirmed directly: isAvailable reported true and the audio engine
    // started fine on it. supportedLocales() only means "the framework
    // theoretically supports this somewhere," not "this exact locale's
    // model is installed/ready on this device" -- confirmed the hard way
    // too, en-ZA/en-CA/en-GB from that set all came back isAvailable=false
    // here. So: try Locale.current for real first, and only fall back
    // (matching by language, then plain SFSpeechRecognizer()) if that
    // specific recognizer instance reports itself unavailable.
    private func preferredSpeechRecognizer() -> SFSpeechRecognizer? {
        if let candidate = SFSpeechRecognizer(locale: Locale.current), candidate.isAvailable {
            return candidate
        }
        let supported = SFSpeechRecognizer.supportedLocales()
        if let languageMatch = supported.first(where: { $0.languageCode == Locale.current.languageCode }),
           let candidate = SFSpeechRecognizer(locale: languageMatch), candidate.isAvailable {
            return candidate
        }
        return SFSpeechRecognizer()
    }

    private func start() {
        recognitionTask?.cancel()
        recognitionTask = nil

        let recognizer = preferredSpeechRecognizer()
        speechRecognizer = recognizer
        print("speech: Locale.current=\(Locale.current.identifier) recognizer.locale=\(recognizer?.locale.identifier ?? "nil") isAvailable=\(recognizer?.isAvailable ?? false) supportsOnDevice=\(recognizer?.supportsOnDeviceRecognition ?? false)")

        guard let recognizer = recognizer, recognizer.isAvailable else {
            print("speech: not starting -- recognizer unavailable")
            onStateChange?(false)
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord, mode: AVAudioSessionModeMeasurement, options: .duckOthers)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("speech: not starting -- audio session error:", error)
            onStateChange?(false)
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        // Tried forcing requiresOnDeviceRecognition = false here as a test
        // (ruling out an unstable on-device model as the cause) -- same
        // hang/death happened identically either way, so it's not that.
        // Left as framework default (on-device preferred when available)
        // since forcing server-based also risks failing outright on a
        // device with no network connectivity.
        recognitionRequest = request
        print("speech: requiresOnDeviceRecognition=\(request.requiresOnDeviceRecognition)")

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        print("speech: recordingFormat=\(recordingFormat)")
        inputNode.removeTap(onBus: 0)
        // Reads recognitionRequest at append time (not a captured local) so
        // startNewSegment() can redirect audio to a new request without
        // touching the engine or reinstalling the tap.
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            print("speech: not starting -- audioEngine.start() error:", error)
            inputNode.removeTap(onBus: 0)
            onStateChange?(false)
            return
        }

        isRecording = true
        print("speech: started, isRunning=\(audioEngine.isRunning)")
        onStateChange?(true)

        beginRecognitionTask(with: request, recognizer: recognizer)
    }

    // Resets the live transcript to empty while staying "recording" -- the
    // mic/tap/audio engine keep running uninterrupted, only the recognition
    // request+task are swapped out.
    func startNewSegment() {
        guard isRecording, let recognizer = speechRecognizer else { return }

        recognitionTask?.cancel()
        recognitionRequest?.endAudio()

        let newRequest = SFSpeechAudioBufferRecognitionRequest()
        newRequest.shouldReportPartialResults = true
        recognitionRequest = newRequest

        beginRecognitionTask(with: newRequest, recognizer: recognizer)
    }

    private func beginRecognitionTask(with request: SFSpeechAudioBufferRecognitionRequest, recognizer: SFSpeechRecognizer) {
        generation += 1
        let myGeneration = generation

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            // SFSpeechRecognizer doesn't guarantee this fires on the main
            // thread, but generation is only ever written from main (every
            // call into this class comes from ViewController's
            // DispatchQueue.main.async-wrapped handlers) -- reading it here
            // without hopping to main first is an unsynchronized cross-
            // thread race that can let a stale/cancelled task's callback
            // see an out-of-date generation and slip past the guard below.
            DispatchQueue.main.async {
                guard let self = self, self.generation == myGeneration else {
                    print("speech: dropped stale callback (generation mismatch)")
                    return
                }

                if let result = result {
                    print("speech: result -> \"\(result.bestTranscription.formattedString)\" isFinal=\(result.isFinal)")
                    self.onResult?(result.bestTranscription.formattedString)
                }
                if let error = error {
                    print("speech: recognitionTask error:", error)
                }

                if error != nil || (result?.isFinal ?? false) {
                    self.stop()
                }
            }
        }
    }

    func stop() {
        guard isRecording else { return }
        generation += 1

        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()

        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false

        try? AVAudioSession.sharedInstance().setActive(false, with: .notifyOthersOnDeactivation)

        onStateChange?(false)
    }
}
