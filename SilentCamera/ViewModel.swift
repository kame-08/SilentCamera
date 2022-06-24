//
//  ViewModel.swift
//  SilentCamera
//
//  Created by Ryo on 2022/06/21.
//

import Foundation
import Photos
import UIKit

class ViewModel:NSObject{
    //入力と出力を管理する機能
    let captureSession = AVCaptureSession()
    
    //デバイス 背面&インナーカメラ(ないかもしれないからオプショナル)
    var mainCamera: AVCaptureDevice?
    var innerCamera: AVCaptureDevice?
    
    //背面orインナーカメラ 使う方
    var device: AVCaptureDevice?
    
    //キャプチャーした画面をアウトプットするための入れ物
    var photoOutput = AVCapturePhotoOutput()
    
    //キャプチャしたイメージデータを保存する入れ物
    var imageData:Data?
    
    //カメラセッティング
    func setupDevice() {
        //設定を開始する
        captureSession.beginConfiguration()
        
        //画像の解像度(.photoは端末に依存する)
        captureSession.sessionPreset = .photo
        
        //MARK: -カメラの設定
        //組み込みカメラ(背面orインナーカメラ)を使う
        //広角カメラ,video,背面orインナーカメラは問わない
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
        
        //条件を満たしたデバイスを取得する
        let devices = deviceDiscoverySession.devices
        
        //取得したデバイスを振り分ける
        for device in devices {
            if device.position == .back {
                mainCamera = device
            } else if device.position == .front {
                innerCamera = device
            }
        }
        
        //実際に起動するカメラは背面が優先、なかったらインナーを使う
        device = mainCamera == nil ? innerCamera : mainCamera
        
        //MARK: -出力の設定
        //falseだったら通さない
        guard captureSession.canAddOutput(photoOutput) else {
            //returnする場合もコミットはしてね
            captureSession.commitConfiguration()
            return
        }
        //ここから下は実行されないかもしれない
        //セッションが使うアウトプットの設定
        captureSession.addOutput(photoOutput)
        //MARK: -入力の設定
        if let device = device {
            guard let captureDeviceInput = try? AVCaptureDeviceInput(device: device),captureSession.canAddInput(captureDeviceInput) else {
                //returnする場合もコミットはしてね
                captureSession.commitConfiguration()
                return
            }
            //セッションが使うインプットの設定
            captureSession.addInput(captureDeviceInput)
        }
        
        //設定終える 設定はコミット
        captureSession.commitConfiguration()
    }
    
    func run() {
        //Mainスレッドではないところで実行(.asyncだから非同期)
        DispatchQueue(label: "Background", qos: .background).async {
            self.captureSession.startRunning()
        }
    }
    
}

extension ViewModel:AVCapturePhotoCaptureDelegate {
    //撮影に関する一連の処理が終わった後に実行する処理
    public func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        //Data型
        self.imageData = photo.fileDataRepresentation()
        //撮影した写真をディスプレイに表示する
        //Image()->直接はimageDataをImage()にできない
        //UIImageからImage()に変換
        _ = UIImage(data: imageData!)
        
    }
    
    //写真をキャプチャーする直前に動作する(シャッター音)
    func photoOutput(_ output: AVCapturePhotoOutput, willCapturePhotoFor resolvedSettings: AVCaptureResolvedPhotoSettings) {
        //シャッター音を消す
        AudioServicesDisposeSystemSoundID(1108)
        //他の音に変更する
        AudioServicesPlaySystemSound(1110)
        
    }
    
    //写真をキャプチャー終わったら何をするか処理を書く
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishCaptureFor resolvedSettings: AVCaptureResolvedPhotoSettings, error: Error?) {
        //写真の保存処理
        PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized else {return}
            //PHPhotoLibraryにアクセスできるように
            //PHPhotoLibraryに変更を要求する。非同期
            PHPhotoLibrary.shared().performChanges {
                // PhotoLibraryに保存するリクエスト
                let creationRequest = PHAssetCreationRequest.forAsset()
                // リクエストに素材を渡す
                // imageDataはオプショナルでデータがないかもしれない。
                guard let imageData = self.imageData else { return }
                creationRequest.addResource(with: .photo, data: imageData, options: nil)
            }
        }
    }
    
    //写真を撮る
    func takePhoto(){
        //キャプチャーに関する設定
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}
