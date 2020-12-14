
import UIKit

extension UIAlertController {
    
    /// ボタンが1つのアラート
    /// - Parameters:
    ///   - title: タイトル
    ///   - message: メッセージ
    ///   - completion: 完了時の処理
    /// - Returns: アラート
    class func singleBtnAlert(title: String, message: String, completion: (() -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: {
            (action:UIAlertAction!) -> Void in
            if let completion = completion {
                completion()
            }
        }))
        
        return alert
    }

    /// ボタンが2つのアラート
    /// - Parameters:
    ///   - title: タイトル
    ///   - message: メッセージ
    ///   - completion: 完了時の処理
    /// - Returns: アラート
    class func doubleBtnAlert(title: String, message: String, completion: (() -> Void)?) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "キャンセル", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "はい", style: .default, handler: {
            (action:UIAlertAction!) -> Void in
            if let completion = completion {
                completion()
            }
        }))
        
        return alert
    }

}
