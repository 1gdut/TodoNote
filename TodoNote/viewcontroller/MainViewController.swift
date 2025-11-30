//
//  MainViewController.swift
//  TodoNote
//
//  Created by xrt on 2025/11/30.
//

import UIKit
import SnapKit

class MainViewController: UIViewController {
    
    // MARK: - Properties
    
    /// 侧边栏是否显示
    private var isSideMenuOpen = false
    
    /// 侧边栏宽度
    private let sideMenuWidth: CGFloat = 280
    
    // MARK: - UI Components
    
    /// 遮罩层
    private lazy var dimmingView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        view.alpha = 0
        view.isUserInteractionEnabled = false
        return view
    }()
    
    /// 侧边栏容器
    private lazy var sideMenuContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.3
        view.layer.shadowOffset = CGSize(width: 2, height: 0)
        view.layer.shadowRadius = 5
        return view
    }()
    
    /// 侧边栏控制器
    private lazy var sideMenuVC: SideMenuViewController = {
        let vc = SideMenuViewController()
        vc.delegate = self
        return vc
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupSideMenu()
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
    
    private var sideMenuSetup = false
    
    private func setupSideMenu() {
        guard !sideMenuSetup else { return }
        sideMenuSetup = true
        
        guard let window = view.window else { return }
        
        // 添加到 window 上
        window.addSubview(dimmingView)
        window.addSubview(sideMenuContainer)
        
        // 设置遮罩层 frame
        dimmingView.frame = window.bounds
        
        // 设置侧边栏 frame，初始在屏幕左侧外
        sideMenuContainer.frame = CGRect(
            x: -sideMenuWidth,
            y: 0,
            width: sideMenuWidth,
            height: window.bounds.height
        )
        
        // 直接添加侧边栏视图（不使用 child view controller）
        sideMenuVC.delegate = self
        sideMenuContainer.addSubview(sideMenuVC.view)
        sideMenuVC.view.frame = sideMenuContainer.bounds
        
        // 遮罩层点击手势
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeSideMenu))
        dimmingView.addGestureRecognizer(tap)
    }
    
    // MARK: - Actions
    
    @objc private func aiButtonTapped() {
        print("点击了 AI 按钮")
        // TODO: 打开 AI 助手
    }
    
    @objc private func menuButtonTapped() {
        if isSideMenuOpen {
            closeSideMenu()
        } else {
            openSideMenu()
        }
    }
    
    // MARK: - Side Menu Control
    
    private func openSideMenu() {
        isSideMenuOpen = true
        dimmingView.isUserInteractionEnabled = true
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.sideMenuContainer.frame.origin.x = 0
            self.dimmingView.alpha = 1
        }
    }
    
    @objc private func closeSideMenu() {
        isSideMenuOpen = false
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut) {
            self.sideMenuContainer.frame.origin.x = -self.sideMenuWidth
            self.dimmingView.alpha = 0
        } completion: { _ in
            self.dimmingView.isUserInteractionEnabled = false
        }
    }
}

// MARK: - SideMenuDelegate

extension MainViewController: SideMenuDelegate {
    
    func sideMenuDidSelectItem(_ item: SideMenuItem) {
        closeSideMenu()
        
        switch item {
        case .profile:
            print("打开个人资料")
            // TODO: 跳转到个人资料页面
            
        case .settings:
            print("打开设置")
            // TODO: 跳转到设置页面
            
        case .about:
            print("打开关于")
            // TODO: 跳转到关于页面
            
        case .logout:
            print("退出登录")
            // TODO: 处理退出登录逻辑
        }
    }
    
    func sideMenuDidClose() {
        closeSideMenu()
    }
}
