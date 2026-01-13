//
//  SpeechRecognizer.swift
//  WeatherDashboard
//
// Speech recognition service for voice-to-text conversion
// Uses Apple's Speech for real-time transcription
import SwiftUI
import SwiftData
import Speech
internal import Combine

class SpeechRecognizer: ObservableObject {
    
    // MARK: - Published Properties
    @Published var transcript: String = ""                  /// Transcription text from speech recognition
    @Published var isRecording: Bool = false                /// Flag indicating if recording is active
    @Published var isAuthorized: Bool = false               /// Flag indicating if user has granted microphone and speech recognition permissions
    
    // MARK: - Private Properties
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?                  /// Audio request object - takes audio chunks and sends them to recogniser
    private var recognitionTask: SFSpeechRecognitionTask?                                   /// Active recognition task
    private let audioEngine = AVAudioEngine()                                               /// Audio engine - captures microphone input
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))  /// Speech recogniser configured with support for "en-US"
    private var autoStopTimer: Timer?                                                       /// Timer for automatic stop after silence (2 seconds after speaking)
    
    
    // MARK: - Authorization
    
    // Requests both microphone and speech recognition permissions
    // Must be called before attempting to use speech recognition
    // User should see system permission dialogs on first call only
    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                self?.isAuthorized = authStatus == .authorized
            }
        }
    }
    
    // MARK: - Recording Control
    
    // Starts speech recognition and microphone recording
    // Configures audio session, recognition request, and audio engine
    func startRecording() {
        
        // STEP 1: Clean up any existing recognition task
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        // STEP 2: Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio session setup failed: \(error)")
            return
        }
        
        // STEP 3: Create recognition request
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            print("Unable to create recognition request")
            return
        }
        recognitionRequest.shouldReportPartialResults = true
        
        // STEP 4: Get audio input node
        let inputNode = audioEngine.inputNode
        
        // Timer to auto-stop after 3 seconds of receiving transcript
        var autoStopTimer: Timer?
        
        // STEP 5: Start recognition task
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }
            
            // Debug logging
            print("🎙️ Recognition callback - error: \(String(describing: error)), result: \(result != nil)")
                        
            var isFinal = false
            
            if let result = result {
                let newTranscript = result.bestTranscription.formattedString
                print("🎙️ Transcript: '\(newTranscript)', isFinal: \(result.isFinal)")
                
                DispatchQueue.main.async {
                    self.transcript = newTranscript
                                        
                    // Cancel existing timer
                    autoStopTimer?.invalidate()
                    
                    // Start new timer - auto-stop 2 seconds after last speech detected
                    if !newTranscript.isEmpty {
                        autoStopTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                            print("⏰ Auto-stop timer fired")
                            self.stopRecording()
                        }
                    }
                }
                isFinal = result.isFinal
            }
            
            // STEP 6: Handle completion or errors
            //  Stop on error or when speech recognition says it's final
            if error != nil || isFinal {
                print("🎙️ Stopping due to: error=\(error != nil), isFinal=\(isFinal)")
                DispatchQueue.main.async {
                    autoStopTimer?.invalidate()
                    self.stopRecording()
                }
            }
        }
        
        // STEP 7: Configure microphone input
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        
        // STEP 8: Start audio engine
        audioEngine.prepare()
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
                self.transcript = ""
            }
        } catch {
            print("Audio engine failed to start: \(error)")
        }
    }
    
    // Stops speech recognition and releases audio resources
    // Performs complete cleanup of all recording components
    func stopRecording() {
        print("🛑 stopRecording called, isRecording before: \(isRecording)")
        
        // STEP 1: Stop the audio engine if it's running
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        
        // STEP 2: End the recognition request
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        
        // STEP 3: Cancel the recognition task
        recognitionTask?.cancel()
        recognitionTask = nil
        
        // STEP 4: Deactivate audio session
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Failed to deactivate audio session: \(error)")
        }
        
        // STEP 5: Update recording state
        DispatchQueue.main.async {
            self.isRecording = false
        }
    }

}
