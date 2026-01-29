//
//  NoteViewController.swift
//  TodoNote
//
//  Created by xrt on 2025/11/30.
//

import UIKit
import SnapKit

class NoteViewController: UIViewController {
    
    // MARK: - Properties
    

    private var viewModel = NoteListViewModel()
    
    // MARK: - UI Components
    
    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无笔记\n点击右上角 + 号创建"
        label.textColor = .lightGray
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    private lazy var collectionView: UICollectionView = {
        let layout = WaterfallLayout()
        layout.delegate = self
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        cv.dataSource = self
        cv.delegate = self
        cv.register(NoteCollectionViewCell.self, forCellWithReuseIdentifier: NoteCollectionViewCell.identifier)
        cv.contentInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        return cv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupGesture()
    }
    
    // 绑定 ViewModel
    private func setupBindings() {
        viewModel.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                // 数据变了，必须手动清理瀑布流的计算缓存
                if let layout = self?.collectionView.collectionViewLayout as? WaterfallLayout {
                    layout.invalidateCache()
                }
                
                // 刷新界面
                self?.collectionView.reloadData()
                self?.checkEmptyState()
            }
        }
    }
    
    // MARK: - Gesture
    
    private func setupGesture() {
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPress)
    }
    
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: point) {
                showDeleteAlert(for: indexPath)
            }
        }
    }
    
    private func showDeleteAlert(for indexPath: IndexPath) {
        let alert = UIAlertController(title: "提示", message: "确定要删除这条笔记吗？", preferredStyle: .alert)
        
        // 震动反馈
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        let deleteAction = UIAlertAction(title: "删除", style: .destructive) { [weak self] _ in
            guard let self = self else { return }
            self.deleteNote(at: indexPath)
        }
        
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        
        alert.addAction(deleteAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    private func deleteNote(at indexPath: IndexPath) {
        viewModel.deleteNote(at: indexPath.item)
        
        // 刷新 UI 动画 (因为 deleteNote 会发通知导致 onDataUpdated 被调用从而 reloadData，
        collectionView.deleteItems(at: [indexPath])
        checkEmptyState()
        
        // 3. 刷新布局缓存
        if let layout = collectionView.collectionViewLayout as? WaterfallLayout {
            layout.invalidateCache()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadData()
    }
    
    private func checkEmptyState() {
        emptyLabel.isHidden = !viewModel.isNotesEmpty
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(collectionView)
        view.addSubview(emptyLabel)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
}

// MARK: - UICollectionViewDataSource & Delegate

extension NoteViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: NoteCollectionViewCell.identifier, for: indexPath) as! NoteCollectionViewCell
        let note = viewModel.note(at: indexPath.item)
        cell.configure(with: note)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let note = viewModel.note(at: indexPath.item)
        let addVC = AddNoteViewController()
        addVC.viewModel = AddNoteViewModel(existingNote: note)
        addVC.hidesBottomBarWhenPushed = true
        let nav = UINavigationController(rootViewController: addVC)
        present(nav, animated: true)
    }
}

// MARK: - WaterfallLayoutDelegate

extension NoteViewController: WaterfallLayoutDelegate {
    
    func collectionView(_ collectionView: UICollectionView, heightForPhotoAtIndexPath indexPath: IndexPath) -> CGFloat {
        return viewModel.heightForItem(at: indexPath.item, screenWidth: view.bounds.width)
    }
}
