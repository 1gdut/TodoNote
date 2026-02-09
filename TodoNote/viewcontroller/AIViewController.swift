//
//  AIViewController.swift
//  TodoNote
//
//  Created by xrt on 2025/11/30.
//

import UIKit
import SnapKit

class AIViewController: UIViewController {
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.backgroundColor = .systemBackground
        table.separatorStyle = .none
        table.register(AIMessageCell.self, forCellReuseIdentifier: "AIMessageCell")
        table.delegate = self
        table.dataSource = self
        return table
    }()
    
    private lazy var centerLabel: UILabel = {
        let label = UILabel()
        label.text = "AI助手"
        label.font = .systemFont(ofSize: 18, weight: .medium)
        label.textColor = .systemGray
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    // Sample data for demonstration
    private var messages: [(text: String, isUser: Bool)] = []
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        view.addSubview(centerLabel)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        centerLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        // Show empty state initially
        tableView.isHidden = messages.isEmpty
        centerLabel.isHidden = !messages.isEmpty
    }
    
    private func setupNavigationBar() {
        // 配置导航栏
        title = "AI助手"
        
        // 左侧返回按钮
        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        backButton.tintColor = .black
        navigationItem.leftBarButtonItem = backButton
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate

extension AIViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "AIMessageCell", for: indexPath) as! AIMessageCell
        let message = messages[indexPath.row]
        cell.configure(with: message.text, isUser: message.isUser)
        return cell
    }
}

// MARK: - AIMessageCell

class AIMessageCell: UITableViewCell {
    
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 16
        imageView.backgroundColor = .systemGray5
        return imageView
    }()
    
    private lazy var messageContainerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 15)
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = .clear
        
        contentView.addSubview(avatarImageView)
        contentView.addSubview(messageContainerView)
        messageContainerView.addSubview(messageLabel)
        
        // Avatar size constraint
        avatarImageView.snp.makeConstraints { make in
            make.width.height.equalTo(32)
            make.top.equalToSuperview().offset(8)
        }
        
        // Message label constraints
        messageLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.bottom.equalToSuperview().offset(-12)
        }
    }
    
    func configure(with text: String, isUser: Bool) {
        messageLabel.text = text
        
        if isUser {
            // User message: avatar on RIGHT, message on LEFT
            avatarImageView.image = UIImage(systemName: "person.circle.fill")
            avatarImageView.tintColor = .systemBlue
            messageContainerView.backgroundColor = .systemBlue
            messageLabel.textColor = .white
            
            avatarImageView.snp.remakeConstraints { make in
                make.width.height.equalTo(32)
                make.top.equalToSuperview().offset(8)
                make.trailing.equalToSuperview().offset(-16)
            }
            
            messageContainerView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(8)
                make.bottom.equalToSuperview().offset(-8)
                make.trailing.equalTo(avatarImageView.snp.leading).offset(-8)
                make.leading.greaterThanOrEqualToSuperview().offset(60)
            }
        } else {
            // AI message: avatar on LEFT, message on RIGHT
            avatarImageView.image = UIImage(systemName: "sparkles")
            avatarImageView.tintColor = .systemPurple
            messageContainerView.backgroundColor = .systemGray6
            messageLabel.textColor = .label
            
            avatarImageView.snp.remakeConstraints { make in
                make.width.height.equalTo(32)
                make.top.equalToSuperview().offset(8)
                make.leading.equalToSuperview().offset(16)
            }
            
            messageContainerView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(8)
                make.bottom.equalToSuperview().offset(-8)
                make.leading.equalTo(avatarImageView.snp.trailing).offset(8)
                make.trailing.lessThanOrEqualToSuperview().offset(-60)
            }
        }
    }
}
