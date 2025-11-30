//
//  ViewController.swift
//  TodoNote
//
//  Created by xrt on 2025/11/27.
//

import UIKit
import SnapKit

class LaunchViewController: UIViewController {
    
    // MARK: - UI Components
    
    /// Logo 图片视图
    private lazy var logoImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "launchlogo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    /// 应用名称标签
    private lazy var appNameLabel: UILabel = {
        let label = UILabel()
        label.text = "TodoNote"
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        label.textColor = .darkGray
        label.textAlignment = .center
        return label
    }()
    
    /// 副标题标签
    private lazy var subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "打通你的todo和笔记"
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        label.textColor = .gray
        label.textAlignment = .center
        return label
    }()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startLaunchAnimation()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加子视图
        view.addSubview(logoImageView)
        view.addSubview(appNameLabel)
        view.addSubview(subtitleLabel)
        
        // 设置约束
        logoImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-60)
            make.width.height.equalTo(120)
        }
        
        appNameLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(logoImageView.snp.bottom).offset(24)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(appNameLabel.snp.bottom).offset(8)
        }
    }
    
    // MARK: - Animation
    
    private func startLaunchAnimation() {
        // 初始状态
        logoImageView.alpha = 0
        logoImageView.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        appNameLabel.alpha = 0
        subtitleLabel.alpha = 0
        
        // Logo 动画
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.logoImageView.alpha = 1
            self.logoImageView.transform = .identity
        }
        
        // 文字动画
        UIView.animate(withDuration: 0.5, delay: 0.6, options: .curveEaseOut) {
            self.appNameLabel.alpha = 1
        }
        
        UIView.animate(withDuration: 0.5, delay: 0.8, options: .curveEaseOut) {
            self.subtitleLabel.alpha = 1
        } completion: { _ in
            // 动画完成后跳转到主页面
            self.navigateToMainViewController()
        }
    }
    
    // MARK: - Navigation
    
    private func navigateToMainViewController() {
        // 延迟一小段时间让用户看到完整的启动页
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let mainVC = MainViewController()
            // 使用 UINavigationController 包裹，以显示顶部导航栏
            let navController = UINavigationController(rootViewController: mainVC)
            
            // 如果使用 SceneDelegate，切换 rootViewController
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
                    window.rootViewController = navController
                }
            } else {
                // 备用方案：使用 present
                navController.modalPresentationStyle = .fullScreen
                self.present(navController, animated: true)
            }
        }
    }
}

