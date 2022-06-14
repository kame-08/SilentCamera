//
//  CameraView.swift
//  SilentCamera
//
//  Created by Ryo on 2022/06/14.
//

import SwiftUI
//カメラ機能を使うためのライブラリ(昔はAVFoundation)
import Photos

class CameraView: UIView{
    //入力と出力を管理する機能
    let captureSession = AVCaptureSession()
    
    //デバイス 背面&インナーカメラ(ないかもしれないからオプショナル)
    var mainCamera: AVCaptureDevice?
    var innerCamera: AVCaptureDevice?
    
    //背面orインナーカメラ 使う方
    var device: AVCaptureDevice?
    
    //キャプチャーした画面をアウトプットするための入れ物
    var photoOutput = AVCapturePhotoOutput()
    
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
    //MARK: -Layerの設定
    
    //プレビュー用のレイヤー
    var cameraPreviewLayer: AVCaptureVideoPreviewLayer?
    
    //レイヤーの設定をする
    func setupLayer() {
        cameraPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        cameraPreviewLayer?.videoGravity = .resizeAspectFill
        //TODO: 画面の向きでカメラのViewがおかしくならないように
        
        //表示する領域の大きさと位置
        self.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: UIScreen.main.bounds.size)
        
        //LayeyもViewと同じ大きさにする
        cameraPreviewLayer?.frame = self.frame
        //オプショナルの値を安全に取り出す
        if let cameraPreviewLayer = cameraPreviewLayer {
            self.layer.addSublayer(cameraPreviewLayer)
        }
    }
    
    func run() {
        captureSession.startRunning()
    }
}

//SwiftUIで使うためのRepresent
struct CameraViewRepresent: UIViewRepresentable {
    typealias UIViewType = CameraView
    
    func makeUIView(context: Context) -> CameraView {
        let view = CameraView()
        view.setupDevice()
        view.setupLayer()
        view.run()
        return view
    }
    
    func updateUIView(_ uiView: CameraView, context: Context) {
        //今回使わない
    }
}
