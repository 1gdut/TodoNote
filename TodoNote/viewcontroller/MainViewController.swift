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

    
    /// 当前选中的 Tab 索引 (0: 笔记, 1: 待办)

    private var selectedTabIndex = 0

    /// 侧边栏转场代理
    private let sideMenuManager = SideMenuTransitionManager()
    
    // MARK: - Child ViewControllers
    
    private lazy var noteVC: NoteViewController = {
        let vc = NoteViewController()
        return vc
    }()
    
    private lazy var todoVC: TodoViewController = {
        let vc = TodoViewController()
        return vc
    }()
    
    // MARK: - UI Components
    
    /// 导航栏标题容器
    private lazy var titleContainerView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 20
        stack.alignment = .center
        stack.distribution = .fillEqually
        return stack
    }()
    
    /// 笔记 Tab 按钮
    private lazy var noteTabButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("笔记", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        button.setTitleColor(.black, for: .normal)
        button.addTarget(self, action: #selector(noteTabTapped), for: .touchUpInside)
        return button
    }()
    
    /// 待办 Tab 按钮
    private lazy var todoTabButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("待办", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
        button.setTitleColor(.gray, for: .normal)
        button.addTarget(self, action: #selector(todoTabTapped), for: .touchUpInside)
        return button
    }()
    
    
    /// 内容容器
    private lazy var contentContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    /// 内容滚动视图
    private lazy var contentScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.isPagingEnabled = true  // 分页滚动
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.showsVerticalScrollIndicator = false
        scrollView.bounces = false
        scrollView.delegate = self
        return scrollView
    }()
    


    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupNavigationBar()
        setupChildViewControllers()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        // 添加内容容器
        view.addSubview(contentContainerView)
        contentContainerView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        
        // 添加滚动视图
        contentContainerView.addSubview(contentScrollView)
        contentScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func setupNavigationBar() {
        // 配置导航栏外观
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .white
        
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .systemBlue
        
        // 设置自定义标题视图
        setupTitleView()
        
        // 添加右侧加号按钮
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "plus"),
            style: .plain,
            target: self,
            action: #selector(addButtonTapped)
        )
        
        // 添加左侧菜单按钮
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "line.3.horizontal"),
            style: .plain,
            target: self,
            action: #selector(menuButtonTapped)
        )
    }
    
    private func setupTitleView() {
        // 添加按钮到 StackView
        titleContainerView.addArrangedSubview(noteTabButton)
        titleContainerView.addArrangedSubview(todoTabButton)
        
        // 设置 StackView 大小
        titleContainerView.frame = CGRect(x: 0, y: 0, width: 120, height: 44)
        
        navigationItem.titleView = titleContainerView
    }
    
    private func setupChildViewControllers() {
        // 创建包装视图
        let noteWrapper = UIView()
        let todoWrapper = UIView()
        
        contentScrollView.addSubview(noteWrapper)
        contentScrollView.addSubview(todoWrapper)
        
        // 设置包装视图约束
        noteWrapper.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.width.equalTo(contentContainerView)
            make.height.equalTo(contentContainerView)
        }
        
        todoWrapper.snp.makeConstraints { make in
            make.left.equalTo(noteWrapper.snp.right)
            make.top.bottom.equalToSuperview()
            make.width.equalTo(contentContainerView)
            make.height.equalTo(contentContainerView)
            make.right.equalToSuperview()  // 确定 contentSize
        }
        
        // 添加笔记页面
        addChild(noteVC)
        noteWrapper.addSubview(noteVC.view)
        noteVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        noteVC.didMove(toParent: self)
        
        // 添加待办页面
        addChild(todoVC)
        todoWrapper.addSubview(todoVC.view)
        todoVC.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        todoVC.didMove(toParent: self)
    }
    
    private var hasLayoutSubviews = false
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let scrollWidth = contentScrollView.bounds.width
        guard scrollWidth > 0, !hasLayoutSubviews else { return }
        
        hasLayoutSubviews = true
        contentScrollView.contentOffset = CGPoint(x: CGFloat(selectedTabIndex) * scrollWidth, y: 0)
    }
    
    
    // MARK: - Tab Actions
    
    @objc private func noteTabTapped() {
        switchToTab(index: 0)
    }
    
    @objc private func todoTabTapped() {
        switchToTab(index: 1)
    }
    
    private func switchToTab(index: Int) {
        guard selectedTabIndex != index else { return }
        selectedTabIndex = index
        
        updateTabStyle(index: index)
        
        // 滚动到对应页面
        let offsetX = CGFloat(index) * contentScrollView.bounds.width
        contentScrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: true)
    }
    
    private func updateTabStyle(index: Int) {
        // 更新 Tab 样式
        if index == 0 {
            // 选中笔记
            noteTabButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            noteTabButton.setTitleColor(.black, for: .normal)
            todoTabButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
            todoTabButton.setTitleColor(.gray, for: .normal)
        } else {
            // 选中待办
            todoTabButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
            todoTabButton.setTitleColor(.black, for: .normal)
            noteTabButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .regular)
            noteTabButton.setTitleColor(.gray, for: .normal)
        }
    }
    
    // MARK: - Actions
    
    @objc private func addButtonTapped() {
        if selectedTabIndex == 0 {
            //笔记
            let addNoteVC = AddNoteViewController()
            let nav = UINavigationController(rootViewController: addNoteVC)
            present(nav, animated: true)
        } else if selectedTabIndex == 1 {
            //待办
        }
    }
    
    @objc private func menuButtonTapped() {
        let aiVC = AIViewController()
        let nav = UINavigationController(rootViewController: aiVC)
        // 使用 .custom 或 .overFullScreen 保证底部的 MainVC 不会被从视图层级中移除，防止黑屏
        nav.modalPresentationStyle = .custom
        nav.transitioningDelegate = sideMenuManager
        
        present(nav, animated: true, completion: nil)
    }
}


// MARK: - UIScrollViewDelegate

extension MainViewController: UIScrollViewDelegate {
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        // 滑动结束后，根据位置更新 Tab
        let pageIndex = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        if pageIndex != selectedTabIndex {
            selectedTabIndex = pageIndex
            updateTabStyle(index: pageIndex)
        }
    }
}
