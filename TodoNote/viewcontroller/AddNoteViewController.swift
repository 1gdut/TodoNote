//
//  AddNoteViewController.swift
//  TodoNote
//
//  Created by xrt on 2026/1/28.
//

import UIKit
import SnapKit

class AddNoteViewController: UIViewController, UITextViewDelegate {
    
    // MARK: - ViewModel
    var viewModel: AddNoteViewModel!
    
    private lazy var titleText: XYTextView = {
        let textView = XYTextView()
        textView.placeholder = "标题"
        textView.placeholderFont = .systemFont(ofSize: 24, weight: .bold)
        textView.font = .systemFont(ofSize: 24, weight: .bold)
        textView.backgroundColor = .clear // 设置透明背景
        textView.delegate = self
        return textView
    }()

    private lazy var saveTimeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray
        label.textAlignment = .center 
        label.isHidden = true
        label.frame = CGRect(x: 0, y: 0, width: 200, height: 44)
        return label
    }()
    
    private lazy var dividerLine: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    private lazy var bodyText: XYTextView = {
        let textView = XYTextView()
        textView.placeholder = "记录美好生活..."
        textView.placeholderFont = .systemFont(ofSize: 20)
        textView.font = .systemFont(ofSize: 20)
        textView.backgroundColor = .clear // 设置透明背景
        textView.delegate = self
        return textView
    }()
    
    private lazy var keyboardToolBar: KeyboardToolBar = {
        let toolBar = KeyboardToolBar()
        toolBar.alpha = 0
        return toolBar
    }()

    private var todoLoadingToastView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(hex: "F5F5F5")
        setupNav()
        setupUI()
        setupLayout()
        setupNotification()
        setupBindings()
        setupData()
    }
    
    func setupData() {
        guard let vm = viewModel else { return }
        titleText.text = vm.initialTitle
        bodyText.text = vm.initialContent
        
        // 解决 UITextView 在初始设置文本后可能无法正确滚动的问题
        // 通过切换 isScrollEnabled 强制重新计算 contentSize 和 layout
        DispatchQueue.main.async {
            self.titleText.isScrollEnabled = false
            self.titleText.isScrollEnabled = true
            self.bodyText.isScrollEnabled = false
            self.bodyText.isScrollEnabled = true
        }
        
        if titleText.text.isEmpty && bodyText.text.isEmpty {
            titleText.becomeFirstResponder()
        } else if !bodyText.text.isEmpty {
            bodyText.becomeFirstResponder()
        } else {
            titleText.becomeFirstResponder()
        }
    }
    
    func setupBindings() {
        guard let vm = viewModel else { return }
        
        vm.onSaveSuccess = { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let nav = self.navigationController, nav.viewControllers.count > 1 {
                    nav.popViewController(animated: true)
                } else {
                    self.dismiss(animated: true, completion: nil)
                }
            }
        }
        
        vm.onAutoSave = { [weak self] timeStr in
            DispatchQueue.main.async {
                self?.saveTimeLabel.text = timeStr
                self?.saveTimeLabel.isHidden = false
            }
        }
        
        vm.onError = { errorMsg in
            print("Error: \(errorMsg)")
        }
    }
    
    func setupUI() {
        view.addSubview(titleText)
        view.addSubview(dividerLine)
        view.addSubview(bodyText)
        view.addSubview(keyboardToolBar)

        keyboardToolBar.delegate = self
        let todoImage = UIImage(systemName: "checkmark.circle") ?? UIImage()
        keyboardToolBar.configure(items: [
            KeyboardToolBar.Item(identifier: "todo", image: todoImage)
        ])
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewDidChange(_ textView: UITextView) {
        guard let vm = viewModel else { return }
        
        if textView == titleText {
            vm.updateTitle(textView.text)
        } else if textView == bodyText {
            vm.updateContent(text: textView.text)
        }
    }
    
    func setupLayout() {
        
        titleText.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(60)
        }
        
        dividerLine.snp.makeConstraints { make in
            make.top.equalTo(titleText.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(0.5)
        }
        
        bodyText.snp.makeConstraints { make in
            make.top.equalTo(dividerLine.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.bottom.equalToSuperview()
        }
        
        keyboardToolBar.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
            make.bottom.equalToSuperview()
            make.height.equalTo(44)
        }


        navigationItem.titleView = saveTimeLabel
    }

    private func setTodoLoading(_ isLoading: Bool) {
        DispatchQueue.main.async {
            if isLoading {
                self.showTodoLoadingToast(message: "正在生成待办")
            } else {
                self.hideTodoLoadingToast()
            }
            self.keyboardToolBar.isUserInteractionEnabled = !isLoading
        }
    }

    private func showTodoLoadingToast(message: String) {
        guard todoLoadingToastView == nil else { return }

        let containerView = UIView()
        containerView.backgroundColor = UIColor(white: 0, alpha: 0.8)
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        containerView.alpha = 0.0

        let iconView = UIImageView(image: UIImage(systemName: "hourglass"))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit

        let toastLabel = UILabel()
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 15, weight: .medium)
        toastLabel.textAlignment = .center
        toastLabel.text = message

        containerView.addSubview(iconView)
        containerView.addSubview(toastLabel)

        let hostView: UIView
        if let window = view.window {
            hostView = window
        } else {
            hostView = view
        }
        hostView.addSubview(containerView)

        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(130)
        }

        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(22)
            make.width.height.equalTo(34)
        }

        toastLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
        }

        todoLoadingToastView = containerView

        UIView.animate(withDuration: 0.2) {
            containerView.alpha = 1.0
        }
    }

    private func hideTodoLoadingToast() {
        guard let loadingView = todoLoadingToastView else { return }
        todoLoadingToastView = nil

        UIView.animate(withDuration: 0.2, animations: {
            loadingView.alpha = 0.0
        }) { _ in
            loadingView.removeFromSuperview()
        }
    }
    
    func setupNotification() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame(_:)), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
    }

    @objc private func keyboardWillChangeFrame(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }

        let keyboardFrameInView = view.convert(keyboardFrame, from: nil)
        let keyboardHeight = max(0, view.bounds.height - keyboardFrameInView.minY)
        let isKeyboardVisible = keyboardHeight > 0
        let space = 10.0
        
        keyboardToolBar.snp.updateConstraints { make in
            if isKeyboardVisible {
                make.bottom.equalToSuperview().offset(-keyboardHeight - space)
            } else {
                make.bottom.equalToSuperview().offset(100)
            }
        }
        
        let bottomInset = isKeyboardVisible ? keyboardHeight + 44 + space : 0
        bodyText.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: bottomInset, right: 0)
        bodyText.scrollIndicatorInsets = bodyText.contentInset
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.keyboardToolBar.alpha = isKeyboardVisible ? 1.0 : 0.0
        }
    }

    func setupNav() {
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
        let finishButton = UIBarButtonItem(
            image: UIImage(systemName: "checkmark"),
            style: .plain,
            target: self,
            action: #selector(finishButtonTapped)
        )
        navigationItem.rightBarButtonItem = finishButton
    }
    
    @objc
    func backButtonTapped() {
        guard let vm = viewModel else {
            dismiss(animated: true)
            return
        }
        
        if vm.isDirty {
            showToast(message: "已保存")
            // 只有在数据变脏时才执行保存
            vm.saveNote()
        } else {
            // 没有修改直接关闭
            dismiss(animated: true)
        }
    }
    
    private func showToast(message: String) {
        // Container
        let containerView = UIView()
        containerView.backgroundColor = UIColor(white: 0, alpha: 0.8)
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        containerView.alpha = 0.0
        
        // Icon
        let iconView = UIImageView(image: UIImage(systemName: "checkmark"))
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        
        // Label
        let toastLabel = UILabel()
        toastLabel.textColor = .white
        toastLabel.font = .systemFont(ofSize: 15, weight: .medium)
        toastLabel.textAlignment = .center
        toastLabel.text = message
        
        containerView.addSubview(iconView)
        containerView.addSubview(toastLabel)
        
        // 添加到 Window 上，这样即使 VC pop 了也能看到
        guard let window = view.window else { return }
        window.addSubview(containerView)
        
        containerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(110) // 正方形
        }
        
        iconView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(22)
            make.width.height.equalTo(36)
        }
        
        toastLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(iconView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(8)
        }
        
        // 动画
        UIView.animate(withDuration: 0.25, animations: {
            containerView.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.25, delay: 1.0, options: .curveEaseOut, animations: {
                containerView.alpha = 0.0
            }) { _ in
                containerView.removeFromSuperview()
            }
        }
    }
    
    @objc
    func finishButtonTapped() {
        showToast(message: "已保存")
        viewModel?.saveNote()
    }

}

extension AddNoteViewController: KeyboardToolBarDelegate {
    func keyboardToolBarDidTapDismiss(_ toolBar: KeyboardToolBar) {
        // 默认行为在 KeyboardToolBar 内部已做 resignFirstResponder
    }

    func keyboardToolBar(_ toolBar: KeyboardToolBar, didTapItem item: KeyboardToolBar.Item) {
        switch item.identifier {
        case "todo":
            requestTodoSuggestionFromCurrentNote()
        default:
            break
        }
    }

    private func requestTodoSuggestionFromCurrentNote() {
        setTodoLoading(true)
        let noteTitle = titleText.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let noteContent = bodyText.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        let noteText = """
        标题：\(noteTitle.isEmpty ? "(空)" : noteTitle)
        正文：\(noteContent.isEmpty ? "(空)" : noteContent)
        """

          let systemPrompt = """
          你是一个从笔记中提取待办事项的助手。
          你必须严格按以下规则输出：
          1) 如果笔记内容中没有明确、可执行、具体的待办事项：只输出 NO_TODO（不加引号，不要输出其他任何文字）。
          2) 如果存在待办：只输出一个 JSON 对象（不允许 Markdown 代码块，不要输出解释文字），格式必须是：
              {"title":"..."}
          3) title 用一句话概括待办，尽量短。
          """

        let messages = [
            GLMChatMessage(role: "system", content: systemPrompt),
            GLMChatMessage(role: "user", content: "请从下面笔记中提取最多 1 条待办：\n\n\(noteText)")
        ]

        GLMNetworkManager.shared.chatCompletion(
            messages: messages,
            temperature: 0.2,
            topP: 0.9,
            maxTokens: 2048
        ) { [weak self] result in
            self?.setTodoLoading(false)
            switch result {
            case .success(let response):
                guard let firstChoice = response.choices?.first else {
                    print("[Todo Suggestion] 返回 choices 为空")
                    print("[Todo Suggestion] Response: \(response)")
                    return
                }

                guard let rawContent = firstChoice.message?.content else {
                    print("[Todo Suggestion] choice.message 为空")
                    print("[Todo Suggestion] Response: \(response)")
                    return
                }

                let content = rawContent.trimmingCharacters(in: .whitespacesAndNewlines)

                if content.isEmpty {
                    print("[Todo Suggestion] 返回 content 为空字符串")
                    print("[Todo Suggestion] Response: \(response)")
                    return
                }

                if content == "NO_TODO" || content.uppercased().contains("NO_TODO") {
                    print("[Todo Suggestion] 当前内容没有待办")
                    DispatchQueue.main.async {
                        self?.showToast(message: "当前内容没有待办")
                    }
                    return
                }

                guard let jsonText = Self.extractFirstJSONObject(from: content) else {
                    print("[Todo Suggestion] 无法解析模型返回内容（不是 JSON 或包含多余文本）")
                    print("[Todo Suggestion] Raw: \(content)")
                    return
                }

                do {
                    struct TodoSuggestion: Codable {
                        let title: String
                    }

                    let data = Data(jsonText.utf8)
                    let suggestion = try JSONDecoder().decode(TodoSuggestion.self, from: data)
                    let noteId = self?.viewModel?.currentNoteId
                    let todo = Todo(title: suggestion.title, isCompleted: false, dueDate: nil, noteId: noteId, createdAt: Date())

                    TodoManager.shared.save(todo: todo)
                    if let _ = noteId {
                        self?.viewModel?.linkTodoId(todo.id)
                    }

                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "zh_CN")
                    formatter.timeZone = .current
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss ZZZZ"
                    print("[Todo Suggestion] 解析成功：\(todo)")
                    print("[Todo Suggestion] createdAt(本地): \(formatter.string(from: todo.createdAt))")
                    print("[Todo Suggestion] Suggestion JSON: \(jsonText)")

                    DispatchQueue.main.async {
                        self?.showToast(message: "已生成待办")
                    }
                } catch {
                    print("[Todo Suggestion] JSON 解码失败：\(error)")
                    print("[Todo Suggestion] JSON: \(jsonText)")
                }

            case .failure(let error):
                print("[Todo Suggestion] 请求失败：\(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.showToast(message: "生成待办失败")
                }
            }
        }
    }

    private static func extractFirstJSONObject(from text: String) -> String? {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // 去掉常见代码块围栏
        if trimmed.hasPrefix("```") {
            trimmed = trimmed
                .replacingOccurrences(of: "```json", with: "")
                .replacingOccurrences(of: "```JSON", with: "")
                .replacingOccurrences(of: "```", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // 如果本身就是一个 JSON 对象
        if trimmed.hasPrefix("{") && trimmed.hasSuffix("}") {
            return trimmed
        }

        // 截取第一个“括号配对完整”的 JSON 对象（更稳，避免 lastIndex 把多段内容全吞了）
        var depth = 0
        var start: String.Index?
        for index in trimmed.indices {
            let ch = trimmed[index]
            if ch == "{" {
                if depth == 0 {
                    start = index
                }
                depth += 1
            } else if ch == "}" {
                if depth > 0 {
                    depth -= 1
                    if depth == 0, let startIndex = start {
                        return String(trimmed[startIndex...index])
                    }
                }
            }
        }

        return nil
    }
}

