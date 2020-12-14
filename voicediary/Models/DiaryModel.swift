
import Foundation
import RealmSwift

class Diary: Object {
    @objc dynamic var date: Date = Date() // 日付
    @objc dynamic var title: String = "" // タイトル
    @objc dynamic var paths: String = "" // 音声ファイルの保存先のパス
}


