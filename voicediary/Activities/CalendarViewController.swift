
import UIKit
import FSCalendar
import CalculateCalendarLogic
import RealmSwift
import AVFoundation

// カレンダー
class CalendarViewController: UIViewController, UINavigationBarDelegate, FSCalendarDelegate, FSCalendarDataSource, FSCalendarDelegateAppearance {

    @IBOutlet weak var naviBar: UINavigationBar!
    @IBOutlet weak var calendar: FSCalendar! // カレンダー
    @IBOutlet weak var diaryView: UIView!
    @IBOutlet weak var diaryDate: UILabel! // 日付
    @IBOutlet weak var diaryTitle: UILabel! // タイトル
    @IBOutlet weak var diaryListenBtn: UIButton! // [声を聴く]ボタン
    
    private let audioRecorder = AudioRecorder() // AudioRecorderクラスをインスタンス化
    let formatter = DateFormatter()
    
    var hasDiary: Bool = false // 日記の有無
    var isPlaying = false // 声日記が再生中か否か
    
    
    /*------------------------------
     ビュー
    ------------------------------*/

    override func viewDidLoad() {
        super.viewDidLoad()

        // DBのマイグレーションを行う
        let config = Realm.Configuration(
            schemaVersion: 1,
            migrationBlock: { migration, oldSchemaVersion in
                if (oldSchemaVersion < 1) {

                }
            })
        Realm.Configuration.defaultConfiguration = config
        
        naviBar.delegate = self
        
        // カレンダーの設定
        setUpCalendar()
        
        // 日記ビューの設定
        diaryView.layer.cornerRadius = 10
        diaryListenBtn.backgroundColor = .gray
        diaryListenBtn.setTitleColor(UIColor.white, for: UIControl.State.normal)
        diaryListenBtn.layer.cornerRadius = 10
        
        // 起動時はタイトルと「聴く」ボタンは非表示
        diaryTitle.isHidden = true
        diaryListenBtn.isHidden = true
        diaryListenBtn.setTitle("声を聴く", for: .normal)
        
        // 起動時は今日の日付を表示
        diaryDate.text = getToday()
        
        // 日付を日本時間に設定
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yMMdd", options: 0, locale: Locale(identifier: "ja_JP"))
        
        // デフォルトは今日を選択
        UserDefaults.standard.set(formatter.date(from: getToday()), forKey: "selectedDate")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let isReload = UserDefaults.standard.integer(forKey: "isReload")
        if isReload == 1 {
            self.reload()
        }
    }

    /// ナビゲーション バーをステータスバーまで広げる
    func position(for bar: UIBarPositioning) -> UIBarPosition {
        return .topAttached
    }
    
    // リロード
    func reload() {
        self.loadView()
        self.viewDidLoad()
        
        calendar.reloadData()
    }
    
    
    /*------------------------------
     アクション
    ------------------------------*/
    
    // [今日] をタップすると今日の日付にフォーカス
    // 描画し直す
    @IBAction func todayBtnTapped(_ sender: Any) {
        self.reload()
    }
    
    // [+] をタップすると録音画面へ遷移
    @IBAction func addBtnTapped(_ sender: Any) {
        // すでに声日記がある場合はアラートを表示
        if hasDiary {
            let alert = UIAlertController.doubleBtnAlert(title: "確認", message: "声日記は1日1つまでです。上書きされますがよろしいですか？", completion: {
                self.performSegue(withIdentifier: "toRecordVC", sender: nil)
            })
            self.present(alert, animated: true, completion: nil)
            UserDefaults.standard.set(1, forKey: "isUpdate")
            return
        }
        UserDefaults.standard.set(0, forKey: "isUpdate")
    }
    
    // [声を聴く] ボタンをタップすると声が流れる
    @IBAction func diaryListenBtnTapped(_ sender: Any) {
        if isPlaying {
            audioRecorder.pause()
            diaryListenBtn.setTitle("声を聴く", for: .normal)
            self.isPlaying = false
        } else {
            audioRecorder.play()
            diaryListenBtn.setTitle("停止", for: .normal)
            self.isPlaying = true
        }
    }
    
    
    /*------------------------------
     FSCalendarのデリゲートメソッド
    ------------------------------*/
    
    // 土日および祝日の文字色を変更
    func calendar(_ calendar: FSCalendar, appearance: FSCalendarAppearance, titleDefaultColorFor date: Date) -> UIColor? {
        // 曜日ごとのインデックスを取得
        // 日曜日：1〜土曜日：7
        let weekday = Calendar(identifier: .gregorian).component(.weekday, from: date)

        // 日曜日および祝日を赤色に
        if weekday == 1 || self.isHoliday(date) {
            return UIColor.red
        // 土曜日を青色に
        } else if weekday == 7 {
            return UIColor.blue
        } else {
            return UIColor.darkGray
        }
    }
    
    // 選択された日付を取得
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        let tmpDate = Calendar(identifier: .gregorian)
        let year = tmpDate.component(.year, from: date)
        let month = tmpDate.component(.month, from: date)
        let day = tmpDate.component(.day, from: date)
        
        // 選択された日付を表示
        let dateStr = "\(year)/\(month)/\(day)"
        diaryDate.text = dateStr
        
        // 日付をUserDefaultsに保存
        UserDefaults.standard.set(formatter.date(from: dateStr), forKey: "selectedDate")
        
        // 選択された日と同じ日のデータをRealmから取得
        let realm = try! Realm()
        if (1 == realm.objects(Diary.self).filter("date == %@", date).count) {
            let result = realm.objects(Diary.self).filter("date == %@", date)
            self.hasDiary = true
            
            // タイトルを表示
            diaryTitle.isHidden = false
            diaryTitle.text = String(result[0].title)
            
            // 「聴く」ボタンを表示
            diaryListenBtn.isHidden = false
            diaryListenBtn.setTitle("声を聴く", for: .normal)
            self.isPlaying = false
            UserDefaults.standard.set(result[0].paths, forKey: "selectedAudioUrl")
        } else {
            self.hasDiary = false
            diaryTitle.isHidden = true
            diaryListenBtn.isHidden = true
        }
    }
    
    // 声日記がある日に音符マーク
    func calendar(_ calendar: FSCalendar, imageFor date: Date) -> UIImage? {
        var result: Results<Diary>!
        // 対象の日付が設定されているデータを取得する
        do {
            let realm = try Realm()
            result = realm.objects(Diary.self).filter("date == %@", date)
        } catch {
        }
        
        if result != nil {
            if result.count == 1 {
                return UIImage(named: "note")
            }
        }
        
        return nil
    }

    
    /*------------------------------
     カレンダー関連のメソッド
    ------------------------------*/
    
    func setUpCalendar() {
        // カレンダーのスクロールの方向（縦）
        calendar.scrollDirection = .vertical
        
        // ビューを角丸に
        calendar.layer.cornerRadius = 10
        
        // 年月を日本語表記に
        calendar.appearance.headerDateFormat = "YYYY年MM月"
        
        // 曜日を日本語表記に
        calendar.calendarWeekdayView.weekdayLabels[0].text = "日"
        calendar.calendarWeekdayView.weekdayLabels[1].text = "月"
        calendar.calendarWeekdayView.weekdayLabels[2].text = "火"
        calendar.calendarWeekdayView.weekdayLabels[3].text = "水"
        calendar.calendarWeekdayView.weekdayLabels[4].text = "木"
        calendar.calendarWeekdayView.weekdayLabels[5].text = "金"
        calendar.calendarWeekdayView.weekdayLabels[6].text = "土"
        
        // 曜日の色を変更
        calendar.calendarWeekdayView.weekdayLabels[0].textColor = UIColor.red
        calendar.calendarWeekdayView.weekdayLabels[5].textColor = UIColor.gray
        calendar.calendarWeekdayView.weekdayLabels[6].textColor = UIColor.blue
    }
    
    // 祝日判定を行い結果を返すメソッド(True:祝日)
    func isHoliday(_ date : Date) -> Bool {
        // 祝日判定用のカレンダークラスのインスタンス
        let tmpCalendar = Calendar(identifier: .gregorian)

        // 祝日判定を行う日にちの年、月、日を取得
        let year = tmpCalendar.component(.year, from: date)
        let month = tmpCalendar.component(.month, from: date)
        let day = tmpCalendar.component(.day, from: date)

        // 祝日判定のインスタンスの生成
        let holiday = CalculateCalendarLogic()

        return holiday.judgeJapaneseHoliday(year: year, month: month, day: day)
    }
    
    // 今日の日付を取得（String型）
    func getToday() -> String {
        let now = Date()
        
        return formatter.string(from: now as Date)
    }
}
