//
//  AddNoteViewController.swift
//  TodoNote
//
//  Created by xrt on 2026/1/28.
//

import UIKit
import SnapKit

class AddNoteViewController: UIViewController {
    private lazy var titleText: XYTextView = {
        let textView = XYTextView()
        textView.placeholder = "标题"
        textView.placeholderFont = .systemFont(ofSize: 24, weight: .bold)
        textView.font = .systemFont(ofSize: 24, weight: .bold)
        return textView
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
        return textView
    }()
    
    private lazy var keyboardToolBar: KeyboardToolBar = {
        let toolBar = KeyboardToolBar()
        toolBar.alpha = 0
        return toolBar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNav()
        setupUI()
        setupLayout()
        setupNotification()
    }
    
    func setupUI() {
        view.addSubview(titleText)
        view.addSubview(dividerLine)
        view.addSubview(bodyText)
        view.addSubview(keyboardToolBar)
    }
    
    func setupLayout() {
        
        titleText.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(60)
        }
        
        dividerLine.snp.makeConstraints { make in
            make.top.equalTo(titleText.snp.bottom)
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
        dismiss(animated: true, completion: nil)
    }
    
    @objc
    func finishButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

}
