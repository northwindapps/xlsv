//
//  BarcodeViewController.swift
//  XLSV
//
//  Created by yano on 2026/05/02.
//  Copyright © 2026 Credera. All rights reserved.
//

import UIKit
import AVFoundation
import Vision


class BarcodeViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {

    // MARK: - Properties
    private let captureSession = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private let sessionQueue = DispatchQueue(label: "camera.session.queue")
    
    // スキャンの一時停止フラグ
    private var isScanning = true
    private var userName = ""
    private var okAction: UIAlertAction?
    
    // MARK: - UI Elements
    // スキャン位置の目安となる枠線（ターゲットボックス）
    let scanBox: UIView = {
        let view = UIView()
        view.layer.borderColor = UIColor.systemGreen.cgColor
        view.layer.borderWidth = 3
        view.layer.cornerRadius = 12
        view.backgroundColor = .clear
        view.layer.zPosition = 2
        return view
    }()

    // 以前のParseボタンを、手動スキャン/リセット用として再利用（基本は自動スキャン）
    let parseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scan", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.zPosition = 3
        button.isHidden = true // 自動で読むため通常は隠す（必要に応じて使ってください）
        return button
    }()

    // 再開ボタン
    let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Retake", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.zPosition = 3
        return button
    }()
    
    let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back", for: .normal)
        button.backgroundColor = .systemGray
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.zPosition = 3
        return button
    }()
    
    // MARK: - User Name Prompt
    private func promptForUserName() {
        let alert = UIAlertController(
            title: "Name Required",
            message: "Please enter your name to start scanning.",
            preferredStyle: .alert
        )
        
        let ok = UIAlertAction(title: "OK", style: .default) { _ in
            guard let name = alert.textFields?.first?.text, !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            
            self.userName = name
            
          
        }
        
        ok.isEnabled = false // Disabled by default
        self.okAction = ok
        alert.addAction(ok)
        
        alert.addTextField { textField in
            textField.placeholder = "Enter your name"
            textField.autocapitalizationType = .words
            
            // MODERN APPROACH: Use UIAction for editingChanged
            textField.addAction(UIAction { _ in
                let text = textField.text ?? ""
                // Enable OK button only if the field is not empty
                self.okAction?.isEnabled = !text.trimmingCharacters(in: .whitespaces).isEmpty
            }, for: .editingChanged)
        }
        
        present(alert, animated: true)
    }


    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        setupUI()
        checkCameraPermissions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        promptForUserName()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer?.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopCamera()
    }

    // MARK: - Camera Setup
    private func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setupCamera()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async { self?.setupCamera() }
                }
            }
        default:
            print("Camera access denied")
        }
    }
    
    private func setupCamera() {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            // 1. カメラ入力
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
                  let videoInput = try? AVCaptureDeviceInput(device: videoDevice),
                  self.captureSession.canAddInput(videoInput) else { return }
            
            self.captureSession.addInput(videoInput)
            
            // 2. メタデータ出力（バーコード・QR用）
            let metadataOutput = AVCaptureMetadataOutput()
            
            guard self.captureSession.canAddOutput(metadataOutput) else { return }
            self.captureSession.addOutput(metadataOutput)
            
            // デリゲートをセット
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            
//            // スキャンしたいコードの種類を指定（QRコード + 主要なバーコード）
//            metadataOutput.metadataObjectTypes = [
//                .qr,            // QRコード
//                .ean13,         // 日本の一般的な商品バーコード(JAN)
//                .ean8,          // 短縮商品バーコード
//                .code128,       // 物流などで使われるコード
//                .upce           // アメリカのコード
//            ]
            metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes
            
            self.captureSession.commitConfiguration()
            
            // 3. プレビューレイヤー
            DispatchQueue.main.async {
                let preview = AVCaptureVideoPreviewLayer(session: self.captureSession)
                preview.frame = self.view.bounds
                preview.videoGravity = .resizeAspectFill
                self.view.layer.insertSublayer(preview, at: 0)
                self.previewLayer = preview
                self.sessionQueue.async {
                    self.captureSession.startRunning()
                }
            }
        }
    }

    // MARK: - Delegate (スキャン成功時に呼ばれる)
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        print("called:", metadataObjects.count)
        
        // スキャンが有効かつ、コードが認識された場合
        guard isScanning, let metadataObject = metadataObjects.first else { return }
        
        guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject,
              let stringValue = readableObject.stringValue else { return }
        
        // 重複実行を防ぐために即座にスキャンを一時停止
        isScanning = false
        AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate)) // ブルっと震わせる
        
        // アラートの表示
        self.showAlert(text: stringValue)
    }

    // MARK: - UI Setup
    private func setupUI() {
        view.addSubview(scanBox)
        view.addSubview(parseButton)
        view.addSubview(clearButton)
        view.addSubview(backButton)
        
        scanBox.translatesAutoresizingMaskIntoConstraints = false
        parseButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonHeight: CGFloat = 50
        let buttonPadding: CGFloat = 10
        let sideMargin: CGFloat = 20

        NSLayoutConstraint.activate([
            // スキャン枠（画面中央に250x250の正方形）
            scanBox.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            scanBox.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            scanBox.widthAnchor.constraint(equalToConstant: 250),
            scanBox.heightAnchor.constraint(equalToConstant: 250),
            
            // ボタンの配置
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sideMargin),
            clearButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            clearButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            backButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: buttonPadding),
            backButton.bottomAnchor.constraint(equalTo: clearButton.bottomAnchor),
            backButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            backButton.widthAnchor.constraint(equalTo: clearButton.widthAnchor),
            
            parseButton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: buttonPadding),
            parseButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sideMargin),
            parseButton.bottomAnchor.constraint(equalTo: clearButton.bottomAnchor),
            parseButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            parseButton.widthAnchor.constraint(equalTo: backButton.widthAnchor)
        ])
        
        parseButton.addTarget(self, action: #selector(parseTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
    }

    // MARK: - Actions
    @objc func backAction() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func clearTapped() {
        // スキャンを再開する
        isScanning = true
        startCamera()
    }

    @objc func parseTapped() {
        // Parseボタンは今回は自動スキャンなので基本使用しません
        clearTapped()
    }

    private func stopCamera() {
        if captureSession.isRunning {
            sessionQueue.async { [weak self] in
                self?.captureSession.stopRunning()
            }
        }
    }
    
    private func startCamera() {
        if !captureSession.isRunning {
            sessionQueue.async { [weak self] in
                self?.captureSession.startRunning()
            }
        }
    }


    func showAlert(text: String) {
        let alert = UIAlertController(
            title: "Scanned! (Copied)",
            message: text,
            preferredStyle: .alert
        )
        
        // 1. Add a Cancel action to dismiss the alert and resume scanning
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                self.clearTapped() // Resets scanning state
            })
        
        // 1. Add a text field for inventory volume
        alert.addTextField { textField in
            textField.placeholder = "Enter inventory volume"
            textField.keyboardType = .numberPad // Shows number pad for easy input
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            // 2. Safely get the entered volume text
            let volume = alert.textFields?.first?.text ?? "0"
            
            if let parentVC = self.presentingViewController as? ViewController {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd:HH:mm:ss"
                let timestamp = formatter.string(from: Date())
                
                // 3. Concatenate timestamp, barcode text, and volume using ";"
                let combinedText = "\(timestamp);\(text);\(volume);\(self.userName)"
                
                parentVC.datainputFromOtherComtroller(sourceText: combinedText, isBarcode: true)
            }

            self.clearTapped()
        })
        
        present(alert, animated: true)
    }

}
