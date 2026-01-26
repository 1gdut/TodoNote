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
    
    private lazy var centerLabel: UILabel = {
        let label = UILabel()
        label.text = "ai view"
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textColor = .black
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(centerLabel)
        
        centerLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
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
