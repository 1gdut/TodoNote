//
//  MainViewController.swift
//  TodoNote
//
//  Created by xrt on 2025/11/30.
//

import UIKit

class MainViewController: UIViewController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
    }
    
    private func setupNavigationBar() {
        // 设置标题
        title = "笔记"
        
        // 配置导航栏外观
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        appearance.titleTextAttributes = [.foregroundColor: UIColor.black]
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue
        
        // 添加右侧 AI 按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "sparkles"),
            style: .plain,
            target: self,
            action: #selector(aiButtonTapped)
        )
        
        // 添加左侧菜单按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            style: .plain,
            target: self,
            action: #selector(menuButtonTapped)
        )
    }
    
    // MARK: - Actions
    
    @objc private func aiButtonTapped() {
        print("点击了 AI 按钮")
        // TODO: 打开 AI 助手
    }
    
    @objc private func menuButtonTapped() {
        print("点击了菜单按钮")
        // TODO: 打开侧边菜单
    }
}
