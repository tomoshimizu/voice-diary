//
//  ModalViewController.swift
//  voicediary
//
//  Created by 志水智 on 2020/09/20.
//  Copyright © 2020 志水智. All rights reserved.
//

import UIKit
import RealmSwift

@IBDesignable
class ModalViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var modalView: UIView! // モーダルビュー
    @IBOutlet weak var saveBtn: UIButton! // [保存]ボタン
    @IBOutlet weak var cancelBtn: UIButton! // [キャンセル]ボタン
    @IBOutlet weak var titleTextField: UITextField! // タイトル入力欄
    @IBOutlet weak var errorMessage: UILabel! // エラーメッセージ
    
    // Realm DBのインスタンス
    private let realm = try! Realm()
    
    
    /*------------------------------
     ビュー
    ------------------------------*/
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 角丸に設定
        modalView.layer.cornerRadius = 10
        saveBtn.layer.cornerRadius = 10
        cancelBtn.layer.cornerRadius = 10
        
        // デフォルトはエラーメッセージは非表示
        titleTextField.delegate = self
        errorMessage.isHidden = true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        // キーボードを閉じる
        textField.resignFirstResponder()
        return true
    }
    
    
    /*------------------------------
     アクション
    ------------------------------*/
    
    // [保存] 押下
    @IBAction func saveBtnTapped(_ sender: Any) {
        // タイトル未入力の場合はエラーメッセージを表示
        if titleTextField.text! == "" {
            errorMessage.isHidden = false
            return
        }
        
        // 日付を取得
        let value = UserDefaults.standard.object(forKey: "selectedDate")
        guard let date = value as? Date else {
            return
        }
        // タイトルを取得
        let title = titleTextField.text!
        // 保存先のURLを取得
        let audioUrl = UserDefaults.standard.url(forKey: "audioUrl")!
        
        // 録音ファイルの保存先のパスをRealmに保存
        // キャンセル：削除 / 保存：タイトルをつけて更新
        let diary = Diary()
        diary.date = date // カレンダーでクリックされた日付
        diary.title = title // タイトル
        diary.paths = "\(audioUrl)" // 録音ファイルの保存先のパス
        
        // 更新フラグが1の場合は既にある声日記を上書き
        let isUpdate = UserDefaults.standard.integer(forKey: "isUpdate")
        if isUpdate == 1 {
            let currentDiary = realm.objects(Diary.self).filter("date == %@", date)
            try! realm.write {
                currentDiary[0].title = title
                currentDiary[0].paths = "\(audioUrl)"
            }
        } else {
            try! realm.write {
                realm.add(diary)
            }
        }
        
        // リロードフラグを立てる
        UserDefaults.standard.set(1, forKey: "isReload")
        
        // 確認ダイアログを表示
        let alert = UIAlertController.singleBtnAlert(title: "", message: "保存しました", completion: {
            self.dismiss(animated: true, completion: nil)
        })
        self.present(alert, animated: true, completion: nil)
        
        print(Realm.Configuration.defaultConfiguration.fileURL!)
    }
    
    // [キャンセル] 押下
    @IBAction func cancelBtnTapped(_ sender: Any) {
        let audioUrl = UserDefaults.standard.url(forKey: "audioUrl")
        
        // Documentディレクトリ直下に保存さえた録音ファイルを削除
        do {
            try FileManager.default.removeItem(atPath: audioUrl!.path)
        } catch {
            print("削除失敗：\(audioUrl!.path)")
        }

        UserDefaults.standard.set(0, forKey: "isReload")
        self.dismiss(animated: true, completion: nil)
    }
}
