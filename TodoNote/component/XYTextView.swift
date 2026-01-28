//
//  XYTextView.swift
//  TodoNote
//
//  Created by xrt on 2026/1/28.
//

import UIKit

class XYTextView: UITextView {
    private let placeholderLabel = UILabel()

    var placeholder: String = "" {
        didSet {
            placeholderLabel.text = placeholder
        }
    }

    var placeholderColor: UIColor = .systemGray {
        didSet {
            placeholderLabel.textColor = placeholderColor
        }
    }

    var placeholderFont: UIFont = .systemFont(ofSize: 16) {
        didSet {
            placeholderLabel.font = placeholderFont
        }
    }

    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        setupPlaceholder()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupPlaceholder()
    }

    private func setupPlaceholder() {
        // 配置 placeholderLabel
        placeholderLabel.font = font ?? UIFont.systemFont(ofSize: 16)
        placeholderLabel.textColor = placeholderColor
        placeholderLabel.backgroundColor = .clear
        placeholderLabel.numberOfLines = 0
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderLabel)

        // 布局：与 textView 的 contentInset 对齐（通常 top = 8）
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor
                .constraint(equalTo: topAnchor, constant: 8),
            placeholderLabel.leadingAnchor
                .constraint(equalTo: leadingAnchor, constant: 5),
            placeholderLabel.trailingAnchor
                .constraint(lessThanOrEqualTo: trailingAnchor, constant: -8)
        ])

        // 监听文本变化、开始编辑、结束编辑
        let notifications = [
            UITextView.textDidChangeNotification,
            UITextView.textDidBeginEditingNotification,
            UITextView.textDidEndEditingNotification
        ]
        notifications.forEach {
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(textDidChange),
                name: $0,
                object: self
            )
        }

        // 初始状态
        updatePlaceholderVisibility()
    }

    @objc private func textDidChange() {
        updatePlaceholderVisibility()
    }

    private func updatePlaceholderVisibility() {
        placeholderLabel.isHidden = !text
            .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isFirstResponder
    }

    // 当设置 text 时也要更新 placeholder
    override var text: String! {
        didSet {
            updatePlaceholderVisibility()
        }
    }

    // 可选：当字体变化时同步 placeholder 字体
    override var font: UIFont! {
        didSet {
            placeholderLabel.font = font
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
