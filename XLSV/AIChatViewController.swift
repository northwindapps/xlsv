//
//  AIChatViewController.swift
//  XLSV
//
//  The "Ask about this sheet" panel. Programmatic UI (no xib) -- the feature
//  is small and this keeps it out of the storyboard/xib merge churn the
//  project has had.
//
//  Data never leaves the device until the user accepts the one-time consent
//  prompt (AIConfig.consentGranted). The panel is handed three closures by
//  AISpreadsheetBridge so it never reaches into a view controller directly.
//

import UIKit

final class AIChatViewController: UIViewController, UITextFieldDelegate {

    private enum Scope: Int { case selection, sheet, workbook }

    private let currentSheetProvider: () -> SheetSnapshot?
    private let bookProvider: () -> [SheetSnapshot]
    private let selectionProvider: () -> [IndexPath]

    private let client = OpenAIClient()
    private var inFlight: URLSessionDataTask?
    private var history: [OpenAIClient.Message] = []

    // MARK: UI
    private let scopeControl = UISegmentedControl(items: [
        AIConfig.localized("Selection", ja: "選択範囲"),
        AIConfig.localized("Sheet", ja: "シート"),
        AIConfig.localized("Workbook", ja: "ブック")
    ])
    private let transcript = UITextView()
    private let inputField = UITextField()
    private let sendButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
    private let disclosure = UILabel()
    private var inputBottomConstraint: NSLayoutConstraint!

    init(currentSheet: @escaping () -> SheetSnapshot?,
         book: @escaping () -> [SheetSnapshot],
         selection: @escaping () -> [IndexPath]) {
        self.currentSheetProvider = currentSheet
        self.bookProvider = book
        self.selectionProvider = selection
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        title = AIConfig.localized("Ask AI", ja: "AIに質問")

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: AIConfig.localized("Close", ja: "閉じる"),
            style: .plain, target: self, action: #selector(close))
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: nil, style: .plain, target: self, action: #selector(openKeyInfo))
        navigationItem.rightBarButtonItem?.title = AIConfig.localized("API key", ja: "APIキー")

        buildLayout()
        refreshScopeAvailability()
        appendSystemNote(AIConfig.localized(
            "Ask a question about your spreadsheet. Cell values for the chosen scope are sent to OpenAI.",
            ja: "スプレッドシートについて質問できます。選択した範囲のセル値がOpenAIに送信されます。"))

        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardChange(_:)),
            name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !AIKeychain.hasAPIKey { openKeyInfo() }
    }

    // MARK: Layout

    private func buildLayout() {
        // Default to Selection when the user already has cells picked, else Sheet.
        scopeControl.selectedSegmentIndex = selectionProvider().isEmpty
            ? Scope.sheet.rawValue : Scope.selection.rawValue
        scopeControl.translatesAutoresizingMaskIntoConstraints = false

        transcript.isEditable = false
        transcript.font = .systemFont(ofSize: 15)
        transcript.alwaysBounceVertical = true
        transcript.translatesAutoresizingMaskIntoConstraints = false

        disclosure.text = AIConfig.localized("Sends selected cell values to OpenAI.",
                                             ja: "選択したセルの値をOpenAIに送信します。")
        disclosure.font = .systemFont(ofSize: 11)
        disclosure.textColor = .gray
        disclosure.numberOfLines = 0
        disclosure.translatesAutoresizingMaskIntoConstraints = false

        inputField.placeholder = AIConfig.localized("Ask a question…", ja: "質問を入力…")
        inputField.borderStyle = .roundedRect
        inputField.returnKeyType = .send
        inputField.delegate = self
        inputField.translatesAutoresizingMaskIntoConstraints = false

        sendButton.setTitle(AIConfig.localized("Send", ja: "送信"), for: .normal)
        sendButton.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.setContentHuggingPriority(.required, for: .horizontal)

        spinner.hidesWhenStopped = true
        spinner.translatesAutoresizingMaskIntoConstraints = false

        let inputRow = UIStackView(arrangedSubviews: [inputField, spinner, sendButton])
        inputRow.axis = .horizontal
        inputRow.spacing = 8
        inputRow.alignment = .center
        inputRow.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(scopeControl)
        view.addSubview(transcript)
        view.addSubview(disclosure)
        view.addSubview(inputRow)

        let guide = view.safeAreaLayoutGuide
        inputBottomConstraint = inputRow.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -8)

        NSLayoutConstraint.activate([
            scopeControl.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            scopeControl.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            scopeControl.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),

            transcript.topAnchor.constraint(equalTo: scopeControl.bottomAnchor, constant: 8),
            transcript.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            transcript.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            disclosure.topAnchor.constraint(equalTo: transcript.bottomAnchor, constant: 4),
            disclosure.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            disclosure.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),

            inputRow.topAnchor.constraint(equalTo: disclosure.bottomAnchor, constant: 6),
            inputRow.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 12),
            inputRow.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -12),
            inputBottomConstraint
        ])
    }

    // MARK: Scope

    private func refreshScopeAvailability() {
        let hasSelection = !selectionProvider().isEmpty
        scopeControl.setEnabled(hasSelection, forSegmentAt: Scope.selection.rawValue)
        if !hasSelection && scopeControl.selectedSegmentIndex == Scope.selection.rawValue {
            scopeControl.selectedSegmentIndex = Scope.sheet.rawValue
        }
        let count = selectionProvider().count
        if count > 0 {
            scopeControl.setTitle(AIConfig.localized("Selection (\(count))", ja: "選択(\(count))"),
                                  forSegmentAt: Scope.selection.rawValue)
        }
    }

    /// Serializes the chosen scope, respecting AIConfig.maxCellsPerRequest.
    private func buildContext() -> (text: String, truncated: Bool)? {
        let budget = AIConfig.maxCellsPerRequest
        switch Scope(rawValue: scopeControl.selectedSegmentIndex) ?? .sheet {
        case .selection:
            guard let snap = currentSheetProvider() else { return nil }
            let r = SheetContextBuilder.table(from: snap, selection: selectionProvider(), maxCells: budget)
            return ("Sheet \"\(snap.name)\" (selected cells):\n\(r.text)", r.truncated)

        case .sheet:
            guard let snap = currentSheetProvider() else { return nil }
            let r = SheetContextBuilder.table(from: snap, maxCells: budget)
            return ("Sheet \"\(snap.name)\":\n\(r.text)", r.truncated)

        case .workbook:
            let snaps = bookProvider()
            guard !snaps.isEmpty else { return nil }
            var parts: [String] = []
            var remaining = budget
            var truncated = false
            for snap in snaps {
                guard remaining > 0 else { truncated = true; break }
                let r = SheetContextBuilder.table(from: snap, maxCells: remaining)
                parts.append("=== Sheet \"\(snap.name)\" ===\n\(r.text)")
                remaining -= r.cellsIncluded
                truncated = truncated || r.truncated
            }
            return (parts.joined(separator: "\n\n"), truncated)
        }
    }

    // MARK: Send

    @objc private func sendTapped() {
        let question = (inputField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        guard AIKeychain.hasAPIKey else { openKeyInfo(); return }

        guard AIConfig.consentGranted else {
            presentConsent { [weak self] granted in
                if granted { self?.sendTapped() }
            }
            return
        }

        guard let ctx = buildContext(), !ctx.text.isEmpty else {
            appendSystemNote(AIConfig.localized("Nothing to send for this scope.",
                                                ja: "この範囲には送信できるデータがありません。"))
            return
        }

        inputField.text = ""
        appendMessage(role: .user, text: question)
        setLoading(true)

        // Rebuild the payload each turn: fresh sheet context + running Q&A history.
        let system = OpenAIClient.Message(role: "system", content: systemPrompt(truncated: ctx.truncated))
        let contextMessage = OpenAIClient.Message(
            role: "user",
            content: "Spreadsheet data:\n\n\(ctx.text)\n\n---\nQuestion: \(question)")

        var payload: [OpenAIClient.Message] = [system]
        payload.append(contentsOf: history)
        payload.append(contextMessage)

        history.append(OpenAIClient.Message(role: "user", content: question))

        inFlight = client.send(messages: payload) { [weak self] result in
            guard let self = self else { return }
            self.setLoading(false)
            switch result {
            case .success(let answer):
                self.history.append(OpenAIClient.Message(role: "assistant", content: answer))
                self.appendMessage(role: .assistant, text: answer)
            case .failure(let error):
                self.appendSystemNote(error.localizedDescription)
            }
        }
    }

    private func systemPrompt(truncated: Bool) -> String {
        var p = """
        You are a data analyst helping the user understand a spreadsheet shown as \
        a tab-separated table. The first column is the row number and the header \
        row lists spreadsheet column letters. Answer concisely. If a calculation \
        is requested, show the figure and briefly how you got it. If the data \
        needed to answer is not present, say so.
        """
        if truncated {
            p += "\n\nNote: the table was truncated to fit; some rows/cells are missing."
        }
        return p
    }

    private func setLoading(_ loading: Bool) {
        if loading { spinner.startAnimating() } else { spinner.stopAnimating() }
        sendButton.isEnabled = !loading
        inputField.isEnabled = !loading
        scopeControl.isEnabled = !loading
    }

    // MARK: Transcript

    private enum Role { case user, assistant }

    private func appendMessage(role: Role, text: String) {
        let label = role == .user
            ? AIConfig.localized("You", ja: "あなた")
            : "AI"
        appendRaw("\(label): \(text)\n\n")
    }

    private func appendSystemNote(_ text: String) {
        appendRaw("• \(text)\n\n")
    }

    private func appendRaw(_ s: String) {
        transcript.text = (transcript.text ?? "") + s
        let end = NSRange(location: (transcript.text as NSString).length, length: 0)
        transcript.scrollRangeToVisible(end)
    }

    // MARK: Consent / key

    private func presentConsent(_ completion: @escaping (Bool) -> Void) {
        let alert = UIAlertController(
            title: AIConfig.localized("Send data to OpenAI?", ja: "OpenAIにデータを送信しますか？"),
            message: AIConfig.localized(
                "To answer your question, the cell values in the selected scope will be sent to OpenAI's API over the internet. Don't use this for confidential or personal data.",
                ja: "質問に回答するため、選択範囲のセル値がインターネット経由でOpenAIのAPIに送信されます。機密情報や個人情報には使用しないでください。"),
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: AIConfig.localized("Cancel", ja: "キャンセル"),
                                      style: .cancel) { _ in completion(false) })
        alert.addAction(UIAlertAction(title: AIConfig.localized("Agree & Continue", ja: "同意して続行"),
                                      style: .default) { _ in
            AIConfig.consentGranted = true
            completion(true)
        })
        present(alert, animated: true)
    }

    @objc private func openKeyInfo() {
        let alert = UIAlertController(
            title: AIConfig.localized("OpenAI API key", ja: "OpenAI APIキー"),
            message: AIConfig.localized(
                "Paste an API key from platform.openai.com. It is stored only in this device's Keychain.",
                ja: "platform.openai.com のAPIキーを貼り付けてください。キーはこの端末のKeychainにのみ保存されます。"),
            preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "sk-…"
            tf.isSecureTextEntry = true
            tf.text = AIKeychain.apiKey()
        }
        alert.addAction(UIAlertAction(title: AIConfig.localized("Cancel", ja: "キャンセル"), style: .cancel))
        alert.addAction(UIAlertAction(title: AIConfig.localized("Save", ja: "保存"), style: .default) { [weak alert] _ in
            AIKeychain.setAPIKey(alert?.textFields?.first?.text)
        })
        if AIKeychain.hasAPIKey {
            alert.addAction(UIAlertAction(title: AIConfig.localized("Remove key", ja: "キーを削除"),
                                          style: .destructive) { _ in
                AIKeychain.setAPIKey(nil)
            })
        }
        present(alert, animated: true)
    }

    // MARK: Keyboard / misc

    @objc private func keyboardChange(_ note: Notification) {
        guard let frame = (note.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue
        else { return }
        let overlap = max(0, view.bounds.maxY - view.convert(frame, from: nil).minY)
        inputBottomConstraint.constant = overlap > 0 ? -(overlap - view.safeAreaInsets.bottom + 8) : -8
        UIView.animate(withDuration: 0.2) { self.view.layoutIfNeeded() }
    }

    @objc private func close() {
        inFlight?.cancel()
        dismiss(animated: true)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        sendTapped()
        return false
    }

    deinit { NotificationCenter.default.removeObserver(self) }
}
