//
//  TodoTableViewCell.swift
//  TodoNote
//
//  Created by xrt on 2026/2/9.
//

import UIKit
import SnapKit

class TodoTableViewCell: UITableViewCell {
    
    static let identifier = "TodoTableViewCell"
    
    var onToggleCompletion: (() -> Void)?
    
    // MARK: - UI Components
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .gray.withAlphaComponent(0.3)
        view.layer.cornerRadius = 12
        return view
    }()
    
    private lazy var checkButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(systemName: "circle"), for: .normal)
        btn.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        btn.tintColor = .systemBlue
        btn.addTarget(self, action: #selector(checkButtonTapped), for: .touchUpInside)
        return btn
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .regular)
        label.textColor = .label
        label.numberOfLines = 2
        return label
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13)
        label.textColor = .secondaryLabel
        return label
    }()
    
    // MARK: - Initialization
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .none
        
        contentView.addSubview(containerView)
        containerView.addSubview(checkButton)
        containerView.addSubview(titleLabel)
        containerView.addSubview(dateLabel)
        
        containerView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        
        checkButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(checkButton.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
            make.bottom.equalToSuperview().offset(-12)
            make.trailing.equalToSuperview().offset(-12)
        }
    }
    
    // MARK: - Configuration
    
    func configure(with todo: Todo) {
        // Title
        let attributeString = NSMutableAttributedString(string: todo.title)
        if todo.isCompleted {
            attributeString.addAttribute(.strikethroughStyle, value: 1, range: NSRange(location: 0, length: attributeString.length))
            attributeString.addAttribute(.foregroundColor, value: UIColor.tertiaryLabel, range: NSRange(location: 0, length: attributeString.length))
            titleLabel.textColor = .tertiaryLabel
        } else {
            titleLabel.textColor = .label
        }
        titleLabel.attributedText = attributeString
        
        // Status
        checkButton.isSelected = todo.isCompleted
        checkButton.tintColor = todo.isCompleted ? .secondaryLabel : .systemBlue
        
        // Date
        if let date = todo.dueDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM-dd HH:mm"
            dateLabel.text = formatter.string(from: date)
            dateLabel.isHidden = false
            
            // Adjust layout if date is shown
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(checkButton.snp.trailing).offset(12)
                make.top.equalToSuperview().offset(12)
                make.trailing.equalToSuperview().offset(-12)
            }
        } else {
            dateLabel.isHidden = true
            // Center title if no date
            titleLabel.snp.remakeConstraints { make in
                make.leading.equalTo(checkButton.snp.trailing).offset(12)
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview().offset(-12)
            }
        }
    }
    
    // MARK: - Actions
    
    @objc private func checkButtonTapped() {
        onToggleCompletion?()
    }
}
