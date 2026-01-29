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
        textView.delegate = self
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

