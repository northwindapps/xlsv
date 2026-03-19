import UIKit
import PencilKit
import Vision

class HandwritingViewController: UIViewController {

    let canvasView = PKCanvasView()
    // iOS 13ではToolPickerのインスタンスを保持し続ける必要があります
    var toolPicker: PKToolPicker?
    
//    let parseButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("テキストに変換", for: .normal)
//        button.backgroundColor = .systemBlue
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 8
//        button.layer.zPosition = 1
//        return button
//    }()
    
    let parseButton: UIButton = {
        let button = UIButton(type: .custom) // .systemだとアイコンの色が勝手に変わる場合があるので .custom
        
        let icon = UIImage.excelIcon(size: CGSize(width: 44, height: 40), color: .white)
        button.setImage(icon, for: .normal)
        
        // レイアウト調整
        button.backgroundColor = .systemGreen // Excelっぽく緑に
        button.layer.cornerRadius = 10
        button.layer.zPosition = 1
        
        // アイコンのパディング調整（必要なら）
        button.imageEdgeInsets = UIEdgeInsets(top: 5, left: 5, bottom: 5, right: 5)
        
        return button
    }()



    let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("消去", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.zPosition = 1
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupCanvas()
        setupButtons()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupToolPicker()
    }

    private func setupCanvas() {
        canvasView.frame = view.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        // iOS 13以降
        canvasView.allowsFingerDrawing = true
        view.addSubview(canvasView)
    }

    private func setupToolPicker() {
        // iOS 13の互換性を考慮したウィンドウ取得
        guard let window = view.window else { return }
        
        // iOS 13では共有インスタンスではなく直接生成して保持
        if #available(iOS 14.0, *) {
            toolPicker = PKToolPicker()
        } else {
            // iOS 13専用の取得方法
            toolPicker = PKToolPicker.shared(for: window)
        }
        
        toolPicker?.addObserver(canvasView)
        toolPicker?.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    private func setupButtons() {
        view.addSubview(parseButton)
        view.addSubview(clearButton)
        
        parseButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            parseButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            // ToolPickerが下に表示されるのを考慮して少し上に配置
            parseButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -120),
            parseButton.widthAnchor.constraint(equalToConstant: 120),
            parseButton.heightAnchor.constraint(equalToConstant: 50),
            
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            clearButton.bottomAnchor.constraint(equalTo: parseButton.bottomAnchor),
            clearButton.widthAnchor.constraint(equalToConstant: 80),
            clearButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        view.bringSubview(toFront: parseButton)
        view.bringSubview(toFront: clearButton)
        
        parseButton.addTarget(self, action: #selector(parseTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
    }

    @objc func clearTapped() {
        canvasView.drawing = PKDrawing()
    }

    @objc func parseTapped() {
        let bounds = canvasView.bounds
        let renderer = UIGraphicsImageRenderer(bounds: bounds)
        let image = renderer.image { ctx in
            UIColor.white.setFill()
            ctx.fill(bounds)
            canvasView.drawing.image(from: bounds, scale: 1.0).draw(in: bounds)
        }

        guard let cgImage = image.cgImage else { return }

        let request = VNRecognizeTextRequest { [weak self] (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            let resultText = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
            DispatchQueue.main.async {
                self?.showAlert(text: resultText)
            }
        }

        request.recognitionLevel = .accurate
        // iOS 13の日本語認識は限定的ですが、英語は問題なく動作します
        request.recognitionLanguages = ["en-US", "ja-JP"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    func showAlert(text: String) {
        let alert = UIAlertController(title: "認識結果", message: text.isEmpty ? "文字が見つかりません" : text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
extension UIImage {
    static func excelIcon(size: CGSize = CGSize(width: 40, height: 40), color: UIColor = .white) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let path = UIBezierPath()
            let strokeWidth: CGFloat = 2.0
            
            // --- "=" の描画 ---
            path.move(to: CGPoint(x: 5, y: 15))
            path.addLine(to: CGPoint(x: 15, y: 15))
            path.move(to: CGPoint(x: 5, y: 21))
            path.addLine(to: CGPoint(x: 15, y: 21))
            
            // --- "A" の描画 ---
            path.move(to: CGPoint(x: 18, y: 30))
            path.addLine(to: CGPoint(x: 23, y: 10))
            path.addLine(to: CGPoint(x: 28, y: 30))
            path.move(to: CGPoint(x: 20.5, y: 22))
            path.addLine(to: CGPoint(x: 25.5, y: 22))
            
            // --- "3" の描画 ---
            path.move(to: CGPoint(x: 32, y: 11))
            path.addLine(to: CGPoint(x: 38, y: 11))
            path.addLine(to: CGPoint(x: 34, y: 19))
            // 3の下のカーブ
            path.addQuadCurve(to: CGPoint(x: 33, y: 29), controlPoint: CGPoint(x: 42, y: 24))
            
            color.setStroke()
            path.lineWidth = strokeWidth
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
        }
    }
}
