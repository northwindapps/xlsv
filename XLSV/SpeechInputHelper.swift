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
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                DispatchQueue.main.async {
                    guard authStatus == .authorized, granted else {
                        self?.onStateChange?(false)
                        return
                    }
                    self?.start()
                }
            }
        }
    }

    private func start() {
        recognitionTask?.cancel()
        recognitionTask = nil

        let recognizer = SFSpeechRecognizer(locale: Locale.current) ?? SFSpeechRecognizer()
        speechRecognizer = recognizer

        guard let recognizer = recognizer, recognizer.isAvailable else {
            onStateChange?(false)
            return
        }

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord, mode: AVAudioSessionModeMeasurement, options: .duckOthers)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            onStateChange?(false)
            return
        }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
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
            inputNode.removeTap(onBus: 0)
            onStateChange?(false)
            return
        }

        isRecording = true
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
                guard let self = self, self.generation == myGeneration else { return }

                if let result = result {
                    self.onResult?(result.bestTranscription.formattedString)
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
