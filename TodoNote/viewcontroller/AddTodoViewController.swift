//
//  AddTodoViewController.swift
//  TodoNote
//
//  Created by xrt on 2026/2/9.
//

import UIKit
import SnapKit

class AddTodoViewController: UIViewController {

    private let viewModel = AddTodoViewModel()
    
    // MARK: - UI Components
    
    private lazy var titleTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "准备做点什么？"
        tf.font = .systemFont(ofSize: 22, weight: .medium)
        tf.borderStyle = .none
        tf.returnKeyType = .done
        tf.delegate = self
        return tf
    }()
    
    private lazy var dateContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 10
        view.clipsToBounds = true
        return view
    }()
    
    private lazy var dateLabel: UILabel = {
        let label = UILabel()
        label.text = "截止日期"
        label.font = .systemFont(ofSize: 17)
        return label
    }()
    
    private lazy var dateSwitch: UISwitch = {
        let sw = UISwitch()
        sw.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
        return sw
    }()
    
    private lazy var datePicker: UIDatePicker = {
        let picker = UIDatePicker()
        picker.datePickerMode = .dateAndTime
        picker.preferredDatePickerStyle = .compact
        picker.isHidden = true
        picker.minimumDate = Date()
        picker.locale = Locale(identifier: "zh_CN")
        picker.addTarget(self, action: #selector(dateValueChanged(_:)), for: .valueChanged)
        return picker
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupNav()
        setupUI()
        setupBindings()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        titleTextField.becomeFirstResponder()
    }
    
    // MARK: - Setup
    
    private func setupNav() {
        title = "新建待办"
        
        // Remove standard large titles if inconsistent
        navigationItem.largeTitleDisplayMode = .never
        
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
    
    private func setupUI() {
        view.addSubview(titleTextField)
        view.addSubview(dateContainerView)
        
        dateContainerView.addSubview(dateLabel)
        dateContainerView.addSubview(dateSwitch)
        dateContainerView.addSubview(datePicker)
        
        titleTextField.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.height.equalTo(50)
        }
        
        dateContainerView.snp.makeConstraints { make in
            make.top.equalTo(titleTextField.snp.bottom).offset(20)
            make.leading.trailing.equalTo(titleTextField)
            make.bottom.equalTo(dateLabel.snp.bottom).offset(15) // 初始状态：只包住 Label 和 Switch
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(15)
            make.leading.equalToSuperview().offset(15)
            make.height.equalTo(31) // Match switch height roughly
        }
        
        dateSwitch.snp.makeConstraints { make in
            make.centerY.equalTo(dateLabel)
            make.trailing.equalToSuperview().offset(-15)
        }
        
        // 移除高度为 0 的约束，只保留位置约束
        datePicker.snp.makeConstraints { make in
            make.top.equalTo(dateLabel.snp.bottom).offset(10)
            make.leading.equalToSuperview().offset(15)
        }
    }
    
    private func setupBindings() {
        viewModel.onSuccess = { [weak self] in
            DispatchQueue.main.async {
                self?.dismiss(animated: true)
            }
        }
        
        viewModel.onError = { [weak self] message in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "确定", style: .default))
                self?.present(alert, animated: true)
            }
        }
        
        // Bind text field
        titleTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    // MARK: - Actions
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func finishButtonTapped() {
        viewModel.saveTodo()
    }
    
    @objc private func textFieldDidChange(_ textField: UITextField) {
        viewModel.title = textField.text ?? ""
    }
    
    @objc private func switchValueChanged(_ sender: UISwitch) {
        viewModel.hasDueDate = sender.isOn
        
        datePicker.isHidden = !sender.isOn
        
        // 更新容器的约束，而不是 Picker 的高度
        dateContainerView.snp.remakeConstraints { make in
            make.top.equalTo(titleTextField.snp.bottom).offset(20)
            make.leading.trailing.equalTo(titleTextField)
            
            if sender.isOn {
                // 开启：底部对齐 DatePicker
                make.bottom.equalTo(datePicker.snp.bottom).offset(10)
            } else {
                // 关闭：底部对齐 Label (收起)
                make.bottom.equalTo(dateLabel.snp.bottom).offset(15)
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func dateValueChanged(_ sender: UIDatePicker) {
        viewModel.dueDate = sender.date
    }
}

extension AddTodoViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
