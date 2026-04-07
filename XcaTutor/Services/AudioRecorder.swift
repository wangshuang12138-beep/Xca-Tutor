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

// MARK: - Audio Recorder

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
    private let silenceDuration: TimeInterval = 1.5  // 静音 1.5 秒后自动停止
    private var consecutiveSilentFrames = 0
    private let requiredSilentFrames = 30  // 约 0.5 秒
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    // MARK: - Setup
    
    private func setupAudioSession() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    // MARK: - Recording Control
    
    func startRecording() throws {
        guard !isRecording else { return }
        
        // 请求麦克风权限
        let session = AVAudioSession.sharedInstance()
        guard session.recordPermission == .granted else {
            throw AudioError.permissionDenied
        }
        
        // 创建音频引擎
        let engine = AVAudioEngine()
        self.audioEngine = engine
        
        // 获取输入节点
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        // 创建临时文件
        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent("recording_\(UUID().uuidString).m4a")
        
        // 设置录音格式 (AAC, 24kHz, 单声道)
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 24000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
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
        try engine.start()
        isRecording = true
        
        print("🎙️ 开始录音...")
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        // 停止引擎
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        isRecording = false
        silenceTimer?.invalidate()
        silenceTimer = nil
        
        // 读取录音数据
        if let url = recordingURL {
            do {
                let data = try Data(contentsOf: url)
                print("🎙️ 录音完成，大小: \(data.count) bytes")
                onRecordingFinished?(data)
                
                // 清理临时文件
                try? FileManager.default.removeItem(at: url)
            } catch {
                onError?(AudioError.readFailed)
            }
        }
        
        audioFile = nil
        recordingURL = nil
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
                // 检测到足够长时间的静音
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
