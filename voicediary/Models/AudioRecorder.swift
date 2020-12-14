
import UIKit
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    
    public var recorder: AVAudioRecorder!
    public var player: AVAudioPlayer!
    
    // レコーダーをセットアップ
    func setupAudioRecorder(fileName: String) {
        let session = AVAudioSession.sharedInstance()
        
        do {
            try session.setCategory(.playAndRecord, mode: .default)
            try session.setActive(true)

            // 録音フォーマットの設定
            let settings = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            recorder = try AVAudioRecorder(url: getAudioFileUrl(fileName: fileName), settings: settings)
            recorder.delegate = self
            
        } catch let error {
            print(error)
        }
    }

    // 録音先のパスを取得
    func getAudioFileUrl(fileName: String) -> URL {
        // ドキュメントディレクトリのURL（URL型）
        var documentDirectoryFileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        // ディレクトリのパスにファイル名をつなげてファイルのフルパスを作る
        let audioUrl = documentDirectoryFileURL.appendingPathComponent("\(fileName).m4a")
        documentDirectoryFileURL = audioUrl

        // 保存先のパスをUserDefaultsに保存
        UserDefaults.standard.set(documentDirectoryFileURL, forKey: "audioUrl")
        
        return audioUrl
    }
    
    // 録音
    func record() {
        recorder.record()
    }
    
    // 録音停止
    func stop() {
        recorder.stop()
    }
    
    // 再生
    func play() {
        let fileName = UserDefaults.standard.object(forKey: "selectedDate")!
        player = try! AVAudioPlayer(contentsOf: getAudioFileUrl(fileName: "\(fileName)"))
        player.delegate = self
        player.play()
    }
    
    // 再生一時停止
    func pause() {
        player.pause()
    }
}
