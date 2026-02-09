//
//  AIViewController.swift
//  TodoNote
//
//  Created by xrt on 2025/11/30.
//

import UIKit
import SnapKit

// MARK: - Model
struct ChatMessage {
    let id: String
    let text: String
    let isUser: Bool
    let date: Date
}

// MARK: - Cell
class ChatBubbleCell: UITableViewCell {
    
    static let identifier = "ChatBubbleCell"
    
    // UI Components
    private let bubbleView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        return view
    }()
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private let avatarImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.backgroundColor = .systemGray5
        iv.layer.cornerRadius = 16
        iv.clipsToBounds = true
        return iv
    }()
    
    // Constraints
    private var leadingConstraint: Constraint?
    private var trailingConstraint: Constraint?
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(bubbleView)
        bubbleView.addSubview(messageLabel)
        
        avatarImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.width.height.equalTo(32)
        }
        
        messageLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12))
        }
        
        bubbleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.bottom.equalToSuperview().offset(-10)
            make.width.lessThanOrEqualTo(UIScreen.main.bounds.width * 0.75)
        }
        
        bubbleView.snp.prepareConstraints { make in
            self.leadingConstraint = make.leading.equalTo(avatarImageView.snp.trailing).offset(8).constraint
            self.trailingConstraint = make.trailing.equalTo(avatarImageView.snp.leading).offset(-8).constraint
        }
    }
    
    func configure(with message: ChatMessage) {
        messageLabel.text = message.text
        
        // Reset constraints
        leadingConstraint?.deactivate()
        trailingConstraint?.deactivate()
        
        avatarImageView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.width.height.equalTo(32)
            if message.isUser {
                make.trailing.equalToSuperview().offset(-16)
            } else {
                make.leading.equalToSuperview().offset(16)
            }
        }
        
        if message.isUser {
            // User: Bubble on right, Blue bg, White text
            bubbleView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            avatarImageView.image = UIImage(systemName: "person.fill")
            avatarImageView.tintColor = .systemBlue
            
            // Layout: Bubble right of Avatar? No, usually avatar is on the right of bubble for user.
            // Setup above: Avatar is pinned to trailing. Bubble should be to the left of avatar.
            trailingConstraint?.activate()
            
        } else {
            // AI: Bubble on left, Gray bg, Black text
            bubbleView.backgroundColor = .secondarySystemBackground
            messageLabel.textColor = .label
            avatarImageView.image = UIImage(systemName: "cpu") // Or some AI icon
            avatarImageView.tintColor = .systemGray
            
            // Layout: Avatar is pinned to leading. Bubble should be to the right of avatar.
            leadingConstraint?.activate()
        }
    }
}

// MARK: - Main ViewController
class AIViewController: UIViewController {
    
    // MARK: - Properties
    
    private var messages: [ChatMessage] = []
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ChatBubbleCell.self, forCellReuseIdentifier: ChatBubbleCell.identifier)
        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemBackground
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .interactive
        return tableView
    }()
    
    private lazy var inputContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.1
        view.layer.shadowOffset = CGSize(width: 0, height: -2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private lazy var textView: XYTextView = {
        let textView = XYTextView()
        textView.placeholder = "请输入你的问题..."
        textView.font = .systemFont(ofSize: 16)
        textView.layer.cornerRadius = 18
        textView.layer.borderWidth = 1
        textView.layer.borderColor = UIColor.systemGray5.cgColor
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)
        textView.isScrollEnabled = false // Allows growing
        return textView
    }()
    
    private lazy var sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "paperplane.fill"), for: .normal)
        button.tintColor = .systemBlue
        button.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupKeyboardObservers()
        
        // Initial Message
        addMessage(ChatMessage(id: UUID().uuidString, text: "你好！我是你的AI助手，有什么可以帮你的吗？", isUser: false, date: Date()))
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(tableView)
        view.addSubview(inputContainerView)
        inputContainerView.addSubview(textView)
        inputContainerView.addSubview(sendButton)
        
        inputContainerView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        textView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.left.equalToSuperview().offset(16)
            make.right.equalTo(sendButton.snp.left).offset(-8)
            make.height.greaterThanOrEqualTo(36)
            make.height.lessThanOrEqualTo(100)
        }
        
        sendButton.snp.makeConstraints { make in
            make.bottom.equalTo(textView.snp.bottom)
            make.right.equalToSuperview().offset(-16)
            make.width.height.equalTo(36)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(inputContainerView.snp.top)
        }
    }
    
    private func setupNavigationBar() {
        title = "AI助手"
        
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .label
        navigationItem.leftBarButtonItem = backButton
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func sendButtonTapped() {
        guard let text = textView.text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        // Add User Message
        let userMsg = ChatMessage(id: UUID().uuidString, text: text, isUser: true, date: Date())
        addMessage(userMsg)
        
        // Clear Input
        textView.text = ""
        
        // 1. Show "Thinking..." message immediately
        let tempId = UUID().uuidString
        let thinkingMsg = ChatMessage(id: tempId, text: "正在检索知识库并思考中...", isUser: false, date: Date())
        addMessage(thinkingMsg)
        
        // 2. Call GLM API
        if let knowledgeId = UserDefaults.standard.string(forKey: "GLM_KnowledgeBaseId") {
            let messages = [GLMChatMessage(role: "user", content: text)]
            
            let tool = GLMTool(
                type: "retrieval",
                retrieval: GLMRetrievalObject(
                    knowledge_id: knowledgeId,
                    prompt_template: """
                    请根据以下规则和参考文档回答用户问题：
                    1. 这是一个关于"{{question}}"的问题。
                    2. 请仔细阅读并在文档库 "{{knowledge}}" 中查找相关信息。
                    3. 如果文档中有极其相关的内容：请基于文档内容，以通俗易懂、逻辑清晰的方式重新组织语言进行详细解答，不要直接复制原文片段，也不要只是简单摘抄，要形成一篇完整的回答，并且要告诉用户知识库里面有这个内容。
                    4. 如果文档中没有找到相关信息：请明确告知用户"知识库中暂时没有相关内容"，然后利用你自己的知识储备，为用户提供一份详尽、专业的解答。
                    5. 保持回答的语气亲切、自然。
                    """
                )
            )
            
            GLMNetworkManager.shared.chatCompletion(messages: messages, tools: [tool]) { [weak self] result in
                DispatchQueue.main.async {
                    // Update the "Thinking..." message with real content or error
                    self?.removeMessage(withId: tempId)
                     
                    switch result {
                    case .success(let response):
                        print(response)
                        let content = response.choices?.first?.message?.content ?? "未能获取到回答"
                        let aiMsg = ChatMessage(id: UUID().uuidString, text: content, isUser: false, date: Date())
                        self?.addMessage(aiMsg)
                        
                    case .failure(let error):
                        let errorMsg = ChatMessage(id: UUID().uuidString, text: "请求失败: \(error.localizedDescription)", isUser: false, date: Date())
                        self?.addMessage(errorMsg)
                    }
                }
            }
        } else {
             // Fallback if no knowledge base ID
             removeMessage(withId: tempId)
             let msg = ChatMessage(id: UUID().uuidString, text: "未找到知识库 ID，请先在设置中配置。", isUser: false, date: Date())
             addMessage(msg)
        }
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        let bottomOffset = keyboardFrame.height - view.safeAreaInsets.bottom
        
        inputContainerView.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-bottomOffset)
        }
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
            self.scrollToBottom()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        inputContainerView.snp.updateConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        
        UIView.animate(withDuration: duration) {
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - Helpers
    
    private func addMessage(_ message: ChatMessage) {
        messages.append(message)
        tableView.reloadData()
        scrollToBottom()
    }
    
    private func removeMessage(withId id: String) {
        if let index = messages.firstIndex(where: { $0.id == id }) {
            messages.remove(at: index)
            tableView.reloadData()
        }
    }
    
    private func scrollToBottom() {
        guard !messages.isEmpty else { return }
        let indexPath = IndexPath(row: messages.count - 1, section: 0)
        tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AIViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ChatBubbleCell.identifier, for: indexPath) as? ChatBubbleCell else {
            return UITableViewCell()
        }
        cell.configure(with: messages[indexPath.row])
        return cell
    }
}
