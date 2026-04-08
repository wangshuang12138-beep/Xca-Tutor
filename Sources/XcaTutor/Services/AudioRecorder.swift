import AVFoundation
import Foundation

// MARK: - Audio Recorder Protocol

protocol AudioRecorderProtocol {
    var isRecording: Bool { get }
    var onRecordingFinished: ((Data) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
    
    func startRecording() throws
    func stopRecording()
}

// MARK: - Audio Recorder (macOS compatible)

class AudioRecorder: NSObject, AudioRecorderProtocol {
    
    // MARK: - Properties
    
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var recordingURL: URL?
    
    private(set) var isRecording = false
    var onRecordingFinished: ((Data) -> Void)?
    var onError: ((Error) -> Void)?
    
    // VAD (Voice Activity Detection) 参数
    private var silenceTimer: Timer?
    private let silenceThreshold: Float = -40.0  // dB
    private let silenceDuration: TimeInterval = 1.5
    private var consecutiveSilentFrames = 0
    private let requiredSilentFrames = 30
    
    // Chunk callback for streaming ASR
    var onAudioChunk: ((Data) -> Void)?
    private var chunkTimer: Timer?
    private let chunkInterval: TimeInterval = 0.1 // 100ms chunks
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        checkMicrophonePermission()
    }
    
    // MARK: - Permission Check (macOS)
    
    private func checkMicrophonePermission() {
        // macOS 10.14+ 需要麦克风权限
        // 首次使用时会自动弹出权限请求
        #if os(macOS)
        _ = AVCaptureDevice.authorizationStatus(for: .audio)
        #endif
    }
    
    // MARK: - Recording Control
    
    func startRecording() throws {
        guard !isRecording else { return }
        
        // macOS 不需要像 iOS 那样设置 AVAudioSession
        
        // 创建音频引擎
        let engine = AVAudioEngine()
        self.audioEngine = engine
        
        // 获取输入节点
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent("recording_\(UUID().uuidString).wav")
        
        // 设置录音格式 (PCM/WAV, 16kHz, 单声道) - Whisper 推荐格式
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatLinearPCM),
            AVSampleRateKey: 16000,
            AVNumberOfChannelsKey: 1,
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]
        
        do {
            audioFile = try AVAudioFile(forWriting: recordingURL!, settings: settings)
        } catch {
            throw AudioError.fileCreationFailed
        }
        
        // 安装音频 tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
        
        // 启动引擎
        do {
            try engine.start()
        } catch {
            throw AudioError.engineStartFailed
        }
        
        isRecording = true
        print("🎙️ 开始录音...")
        
        // Start chunk timer for streaming ASR
        startChunkTimer()
    }
    
    private func startChunkTimer() {
        chunkTimer?.invalidate()
        chunkTimer = Timer.scheduledTimer(withTimeInterval: chunkInterval, repeats: true) { [weak self] _ in
            self?.sendAudioChunk()
        }
    }
    
    private func sendAudioChunk() {
        guard let url = recordingURL,
              let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let fileSize = attributes[.size] as? UInt64,
              fileSize > 0 else { return }
        
        // Read current audio data and send as chunk
        guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else { return }
        
        // Only send new data since last chunk (simplified)
        onAudioChunk?(data)
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        // Stop chunk timer
        chunkTimer?.invalidate()
        chunkTimer = nil
        
        // 停止引擎
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        isRecording = false
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        // 读取录音数据并添加 WAV 头
        if let url = recordingURL {
            do {
                let pcmData = try Data(contentsOf: url)
                let wavData = createWAVData(pcmData: pcmData, sampleRate: 16000, channels: 1, bitsPerSample: 16)
                print("🎙️ 录音完成，PCM: \(pcmData.count) bytes, WAV: \(wavData.count) bytes")
                onRecordingFinished?(wavData)
                
                // 清理临时文件
                try? FileManager.default.removeItem(at: url)
            } catch {
                onError?(AudioError.readFailed)
            }
        }
        
        audioFile = nil
        recordingURL = nil
    }
    
    // MARK: - WAV Header Creation
    
    private func createWAVData(pcmData: Data, sampleRate: UInt32, channels: UInt16, bitsPerSample: UInt16) -> Data {
        let byteRate = sampleRate * UInt32(channels) * UInt32(bitsPerSample) / 8
        let blockAlign = channels * bitsPerSample / 8
        let dataSize = UInt32(pcmData.count)
        let totalSize = dataSize + 36
        
        var wavData = Data()
        
        // RIFF header
        wavData.append("RIFF".data(using: .ascii)!)
        wavData.append(totalSize.littleEndianBytes)
        wavData.append("WAVE".data(using: .ascii)!)
        
        // fmt subchunk
        wavData.append("fmt ".data(using: .ascii)!)
        wavData.append(UInt32(16).littleEndianBytes)  // Subchunk1Size
        wavData.append(UInt16(1).littleEndianBytes)   // AudioFormat (PCM)
        wavData.append(channels.littleEndianBytes)
        wavData.append(sampleRate.littleEndianBytes)
        wavData.append(byteRate.littleEndianBytes)
        wavData.append(blockAlign.littleEndianBytes)
        wavData.append(bitsPerSample.littleEndianBytes)
        
        // data subchunk
        wavData.append("data".data(using: .ascii)!)
        wavData.append(dataSize.littleEndianBytes)
        wavData.append(pcmData)
        
        return wavData
    }
    
    // MARK: - Audio Processing
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let audioFile = audioFile else { return }
        
        // 计算音量（用于 VAD）
        let level = calculateAudioLevel(buffer)
        
        // 写入文件
        do {
            try audioFile.write(from: buffer)
        } catch {
            print("Failed to write audio buffer: \(error)")
        }
        
        // VAD 检测
        if level < silenceThreshold {
            consecutiveSilentFrames += 1
            
            if consecutiveSilentFrames >= requiredSilentFrames {
                DispatchQueue.main.async { [weak self] in
                    self?.handleSilenceDetected()
                }
            }
        } else {
            consecutiveSilentFrames = 0
            silenceTimer?.invalidate()
            silenceTimer = nil
        }
    }
    
    private func calculateAudioLevel(_ buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return -160 }
        
        let channelDataValue = channelData.pointee
        let channelDataValueArray = stride(from: 0, to: Int(buffer.frameLength), by: buffer.stride)
            .map { channelDataValue[$0] }
        
        let rms = sqrt(channelDataValueArray.map { $0 * $0 }.reduce(0, +) / Float(buffer.frameLength))
        let avgPower = 20 * log10(rms)
        
        return avgPower
    }
    
    private func handleSilenceDetected() {
        guard silenceTimer == nil else { return }
        
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceDuration, repeats: false) { [weak self] _ in
            print("🎙️ 检测到静音，自动停止录音")
            self?.stopRecording()
        }
    }
}

// MARK: - Audio Errors

enum AudioError: Error, LocalizedError {
    case permissionDenied
    case fileCreationFailed
    case readFailed
    case engineStartFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "需要麦克风权限，请在系统设置中允许访问"
        case .fileCreationFailed:
            return "无法创建录音文件"
        case .readFailed:
            return "读取录音数据失败"
        case .engineStartFailed:
            return "启动音频引擎失败"
        }
    }
}

// MARK: - Integer Extensions for Little Endian

extension UInt32 {
    var littleEndianBytes: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt32>.size)
    }
}

extension UInt16 {
    var littleEndianBytes: Data {
        var value = self.littleEndian
        return Data(bytes: &value, count: MemoryLayout<UInt16>.size)
    }
}
