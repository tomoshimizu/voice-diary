
import Foundation
import UIKit
import AVFoundation

class RecordViewController: UIViewController, UINavigationBarDelegate {

    @IBOutlet weak var naviBar: UINavigationBar!
    @IBOutlet weak var counterLbl: UILabel!
    @IBOutlet weak var statusBtn: UIButton!

    private var isRecording = false // 録音フラグ
    var timer: Timer? // タイマー
    private var counter = 180 // 録音時間の制限（3分）
    private let audioRecorder = AudioRecorder() // AudioRecorderクラスをインスタンス化
    
    
    /*------------------------------
     ビュー
    ------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        naviBar.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // デフォルトは録音ボタン
        let img = UIImage(named: "record")
        statusBtn.setBackgroundImage(img, for: .normal)
        
        // 選択された日付を取得
        let date = UserDefaults.standard.object(forKey: "selectedDate")!
        
        // オーディオプレイヤーをセットアップ
        audioRecorder.setupAudioRecorder(fileName: "\(date)")
    }
    
    /// ナビゲーション バーをステータスバーまで広げる
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
        
    /*------------------------------
     アクション
    ------------------------------*/
    
    // ステータス（録音 / 停止）ボタン押下
    @IBAction func recordBtnTapped(_ sender: Any) {
        // 録音中の場合
        if isRecording {
            self.stop()
        } else {
            self.record()
        }
    }
    
    
    /*------------------------------
     録音関連の処理
    ------------------------------*/
    
    // 録音
    func record() {
        audioRecorder.record()
        // カウントダウン開始
        self.startTimer()
        // 停止ボタンに変更
        let img = UIImage(named: "stop")
        statusBtn.setBackgroundImage(img, for: .normal)
        
        isRecording = true
    }
    
    // 停止
    func stop() {
        // 録音停止
        audioRecorder.stop()
        // カウントダウン停止
        self.timer?.invalidate()
        self.counter = 180
        self.counterLbl.text = "3:00"
        // 録音ボタンに変更
        let img = UIImage(named: "record")
        statusBtn.setBackgroundImage(img, for: .normal)
        // ポップアップを表示
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "modalVC") as! ModalViewController
        self.present(vc, animated: true, completion: nil)
        
        isRecording = false
    }
    
    
    /*------------------------------
     タイマー関連の処理
    ------------------------------*/
    
    // カウントダウン開始
    func startTimer() {
        self.timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateCounter), userInfo: nil, repeats: true)
    }

    // カウンターを更新
    @objc func updateCounter() {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .positional
        formatter.allowedUnits = [.minute,.hour,.second]
        
        if counter > 0 {
            counter -= 1
            let temp: TimeInterval = TimeInterval(counter)
            self.counterLbl.text = formatter.string(from: temp)
        } else {
            self.stop()
        }
    }
}
