//
//  KeyboardToolBar.swift
//  TodoNote
//
//  Created by xrt on 2026/1/28.
//

import UIKit
import SnapKit

class KeyboardToolBar: UIView {
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
        //收起点击
        let downLabelGesture = UITapGestureRecognizer(target: self, action: #selector(downLabelTapped))
        downLabel.addGestureRecognizer(downLabelGesture)
        addSubview(downLabel)
        
        
    }
    
    func setupLayout() {
        downLabel.snp.makeConstraints { make in
            make.trailing.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
        }
    }
    @objc
    func downLabelTapped() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIScreen.main.bounds.width - 20, height: 44)
    }
}
