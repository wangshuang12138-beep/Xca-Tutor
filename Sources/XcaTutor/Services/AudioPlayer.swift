import AVFoundation
import Foundation

// MARK: - Audio Player Protocol

protocol AudioPlayerProtocol {
    var isPlaying: Bool { get }
    var onPlaybackFinished: (() -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
    
    func play(data: Data) throws
    func play(url: URL) throws
    func stop()
}

// MARK: - Audio Player (macOS compatible)

class AudioPlayer: NSObject, AudioPlayerProtocol {
    
    // MARK: - Properties
    
    private var player: AVAudioPlayer?
    
    private(set) var isPlaying = false
    var onPlaybackFinished: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - Initialization
    
    override init() {
        super.init()
        // macOS 不需要设置 AVAudioSession
    }
    
    // MARK: - Playback Control
    
    func play(data: Data) throws {
        stop()
        
        do {
            player = try AVAudioPlayer(data: data)
            player?.delegate = self
            player?.prepareToPlay()
            
            guard player?.play() == true else {
                throw PlaybackError.playbackFailed
            }
            
            isPlaying = true
            print("🔊 开始播放音频...")
        } catch {
            throw PlaybackError.invalidAudioData
        }
    }
    
    func play(url: URL) throws {
        stop()
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.prepareToPlay()
            
            guard player?.play() == true else {
                throw PlaybackError.playbackFailed
            }
            
            isPlaying = true
        } catch {
            throw PlaybackError.fileNotFound
        }
    }
    
    func stop() {
        player?.stop()
        player = nil
        isPlaying = false
    }
}

// MARK: - AVAudioPlayerDelegate

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        isPlaying = false
        onPlaybackFinished?()
        print("🔊 播放完成")
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        isPlaying = false
        if let error = error {
            onError?(error)
        }
    }
}

// MARK: - Playback Errors

enum PlaybackError: Error, LocalizedError {
    case invalidAudioData
    case fileNotFound
    case playbackFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidAudioData:
            return "无效的音频数据"
        case .fileNotFound:
            return "音频文件不存在"
        case .playbackFailed:
            return "播放失败"
        }
    }
}
