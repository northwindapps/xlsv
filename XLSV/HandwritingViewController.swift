import UIKit
import PencilKit
import Vision

class HandwritingViewController: UIViewController {

    let canvasView = PKCanvasView()
    var toolPicker: PKToolPicker?
    
    let parseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Parse", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.zPosition = 1
        return button
    }()



    let clearButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Delete", for: .normal)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.layer.zPosition = 1
        return button
    }()
    
    let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Back", for: .normal)
        button.backgroundColor = .systemGray
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
        
        // 1. Content Mode: Scale To Fill
        self.view.contentMode = .scaleToFill

        // 2. Interaction: User Interaction Enabled
        self.view.isUserInteractionEnabled = true
        
        // 3. Alpha: 0.8
        self.view.alpha = 0.8

        // 4. Background: Clear Color
        self.view.backgroundColor = .clear

        // 5. Drawing: Opaque のチェックを外す (透明にする場合は false)
        self.view.isOpaque = false

        // 6. Drawing: Clears Graphics Context
        self.view.clearsContextBeforeDrawing = true

        // 7. Drawing: Autoresize Subviews
        self.view.autoresizesSubviews = true
        
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupToolPicker()
    }

    private func setupCanvas() {
        canvasView.frame = view.bounds
        canvasView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        canvasView.allowsFingerDrawing = true
        view.addSubview(canvasView)
    }

    private func setupToolPicker() {
        guard let window = view.window else { return }
        
        if #available(iOS 14.0, *) {
            toolPicker = PKToolPicker()
        } else {
            toolPicker = PKToolPicker.shared(for: window)
        }
        
        toolPicker?.addObserver(canvasView)
        toolPicker?.setVisible(true, forFirstResponder: canvasView)
        canvasView.becomeFirstResponder()
    }

    private func setupButtons() {
        view.addSubview(parseButton)
        view.addSubview(clearButton)
        view.addSubview(backButton)
        
        parseButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        backButton.translatesAutoresizingMaskIntoConstraints = false
        
        let buttonHeight: CGFloat = 50
        let buttonPadding: CGFloat = 10
        let sideMargin: CGFloat = 20

        NSLayoutConstraint.activate([
            // 1. Deleteボタン (左)
            clearButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sideMargin),
            clearButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -80),
            clearButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            
            // 2. Backボタン (真ん中)
            backButton.leadingAnchor.constraint(equalTo: clearButton.trailingAnchor, constant: buttonPadding),
            backButton.bottomAnchor.constraint(equalTo: clearButton.bottomAnchor),
            backButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            backButton.widthAnchor.constraint(equalTo: clearButton.widthAnchor), // 幅を揃える
            
            // 3. Parseボタン (右)
            parseButton.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: buttonPadding),
            parseButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sideMargin),
            parseButton.bottomAnchor.constraint(equalTo: clearButton.bottomAnchor),
            parseButton.heightAnchor.constraint(equalToConstant: buttonHeight),
            parseButton.widthAnchor.constraint(equalTo: backButton.widthAnchor) // 全員の幅を等しくする
        ])
        
        view.bringSubview(toFront: parseButton)
        view.bringSubview(toFront: clearButton)
        view.bringSubview(toFront: backButton)
        
        parseButton.addTarget(self, action: #selector(parseTapped), for: .touchUpInside)
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        backButton.addTarget(self, action: #selector(backAction), for: .touchUpInside)
    }

    @objc func backAction() {
        self.dismiss(animated: true, completion: nil)
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
        request.recognitionLanguages = ["en-US", "ja-JP"]
        
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    func showAlert(text: String) {
        if !text.isEmpty {
            UIPasteboard.general.string = text
        }

        let alert = UIAlertController(
            title: "Result (Copied)",
            message: text.isEmpty ? "No Text" : text,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

}
//extension UIImage {
//    static func excelIcon(size: CGSize = CGSize(width: 40, height: 40), color: UIColor = .white) -> UIImage? {
//        let renderer = UIGraphicsImageRenderer(size: size)
//        return renderer.image { context in
//            let path = UIBezierPath()
//            let strokeWidth: CGFloat = 2.0
//            
//            // --- "=" の描画 ---
//            path.move(to: CGPoint(x: 5, y: 15))
//            path.addLine(to: CGPoint(x: 15, y: 15))
//            path.move(to: CGPoint(x: 5, y: 21))
//            path.addLine(to: CGPoint(x: 15, y: 21))
//            
//            // --- "A" の描画 ---
//            path.move(to: CGPoint(x: 18, y: 30))
//            path.addLine(to: CGPoint(x: 23, y: 10))
//            path.addLine(to: CGPoint(x: 28, y: 30))
//            path.move(to: CGPoint(x: 20.5, y: 22))
//            path.addLine(to: CGPoint(x: 25.5, y: 22))
//            
//            // --- "3" の描画 ---
//            path.move(to: CGPoint(x: 32, y: 11))
//            path.addLine(to: CGPoint(x: 38, y: 11))
//            path.addLine(to: CGPoint(x: 34, y: 19))
//            // 3の下のカーブ
//            path.addQuadCurve(to: CGPoint(x: 33, y: 29), controlPoint: CGPoint(x: 42, y: 24))
//            
//            color.setStroke()
//            path.lineWidth = strokeWidth
//            path.lineCapStyle = .round
//            path.lineJoinStyle = .round
//            path.stroke()
//        }
//    }
//}
