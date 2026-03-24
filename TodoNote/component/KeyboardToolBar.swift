//
//  KeyboardToolBar.swift
//  TodoNote
//
//  Created by xrt on 2026/1/28.
//

import UIKit
import SnapKit

protocol KeyboardToolBarDelegate: AnyObject {
    func keyboardToolBarDidTapDismiss(_ toolBar: KeyboardToolBar)
    func keyboardToolBar(_ toolBar: KeyboardToolBar, didTapItem item: KeyboardToolBar.Item)
}

class KeyboardToolBar: UIView {
    struct Item: Equatable {
        let identifier: String
        let image: UIImage
    }

    weak var delegate: KeyboardToolBarDelegate?

    private var items: [Item] = []

    private lazy var itemsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.alignment = .center
        stack.distribution = .equalSpacing
        stack.spacing = 12
        return stack
    }()

    private lazy var downLabel: UILabel = {
        let label = UILabel()
        label.text = "收起"
        label.font = UIFont.systemFont(ofSize: 16)
        label.isUserInteractionEnabled = true
        return label
    }()

    override init(frame: CGRect) {
        let initialFrame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width - 20, height: 44)
        super.init(frame: initialFrame)
        setupUI()
        setupLayout()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupUI() {
        self.backgroundColor = .tertiarySystemBackground
        
        // 圆角
        self.layer.cornerRadius = 20
        if #available(iOS 13.0, *) {
            self.layer.cornerCurve = .continuous
        }
        
        // 阴影
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2)
        self.layer.shadowOpacity = 0.15
        self.layer.shadowRadius = 8

        addSubview(itemsStackView)
        //收起点击
        let downLabelGesture = UITapGestureRecognizer(target: self, action: #selector(downLabelTapped))
        downLabel.addGestureRecognizer(downLabelGesture)
        addSubview(downLabel)
        
        
    }
    
    func setupLayout() {
        itemsStackView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(12)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(downLabel.snp.leading).offset(-12)
        }

        downLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    func configure(items: [Item]) {
        self.items = items

        itemsStackView.arrangedSubviews.forEach { view in
            itemsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for (index, item) in items.enumerated() {
            let button = UIButton(type: .system)
            button.tintColor = .label
            button.setImage(item.image.withRenderingMode(.alwaysTemplate), for: .normal)
            button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
            button.tag = index
            button.addTarget(self, action: #selector(itemButtonTapped(_:)), for: .touchUpInside)
            itemsStackView.addArrangedSubview(button)
        }
    }

    @objc
    func downLabelTapped() {
        delegate?.keyboardToolBarDidTapDismiss(self)
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    @objc
    private func itemButtonTapped(_ sender: UIButton) {
        let index = sender.tag
        guard items.indices.contains(index) else { return }
        delegate?.keyboardToolBar(self, didTapItem: items[index])
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width - 20, height: 44)
    }
}
