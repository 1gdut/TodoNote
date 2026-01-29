//
//  NoteListViewModel.swift
//  TodoNote
//
//  Created by xrt on 2026/1/29.
//

import UIKit

class NoteListViewModel {
    
    // MARK: - Properties
    
    private(set) var notes: [Note] = []
    
    // 数据更新回调
    var onDataUpdated: (() -> Void)?
    
    init() {
        // 监听数据变化通知
        NotificationCenter.default.addObserver(self, selector: #selector(loadData), name: .noteListChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Data Operations
    
    @objc func loadData() {
        notes = NoteManager.shared.loadAllNotes()
        onDataUpdated?()
    }
    
    func deleteNote(at index: Int) {
        guard index < notes.count else { return }
        let note = notes[index]
        
        //删除本地文件 (NoteManager 会发出 .noteListChanged 通知)
        // 从内存移除，防止并在异步刷新前数据源不一致
        notes.remove(at: index)
        
        NoteManager.shared.deleteNote(id: note.id)
    }
    
    // MARK: - Accessors
    
    var numberOfItems: Int {
        return notes.count
    }
    
    func note(at index: Int) -> Note {
        return notes[index]
    }
    
    var isNotesEmpty: Bool {
        return notes.isEmpty
    }
    
    // MARK: - Layout Calculation
    
    /// 计算 Item 高度
    /// - Parameters:
    ///   - index: 索引
    ///   - screenWidth: 屏幕宽度
    /// - Returns: 计算出的高度
    func heightForItem(at index: Int, screenWidth: CGFloat) -> CGFloat {
        guard index < notes.count else { return 100 }
        let note = notes[index]
        
        // MARK: - 布局常量 (和 VC/Layout/Cell 保持一致)
        // 瀑布流列数
        let columnCount: CGFloat = 2
        // UICollectionView 的左右 ContentInset (10 + 10)
        let collectionViewContentInset: CGFloat = 20
        // WaterfallLayout 的 cellPadding (8)，每个 Cell 左右各有一个 Padding，两列就是 4 个 Padding
        // 左Cell左Pad + 左Cell右Pad + 右Cell左Pad + 右Cell右Pad = 8 * 4 = 32
        // 但实际 WaterfallLayout 实现中，frame.insetBy(dx: cellPadding) 导致每个 item 宽度减少了 2 * padding
        // 总宽度通过 (screenWidth - 20) / 2 算出的是"包含Padding的列宽"
        // 实际上用于显示的宽度还要减去左右 Padding (8+8=16)
        // 所以这里直接根据 NoteViewController 的 visual width 反推：
        // 屏幕宽 - inset(20) - 中间及两边所有padding
        
        // 简化计算逻辑：
        // 1. 容器总宽 = screenWidth
        // 2. 减去 CollectionView 左右 Inset (10*2 = 20) -> screenWidth - 20
        // 3. 减去 Cell 之间的间距（WaterfallLayout 每个 Cell 把自己 inset 8，导致 cell 之间间距 16，cell 与边缘间距 8）
        // 这里的 52 是一个经验值：20(inset) + 32(padding*4) = 52
        let totalHorizontalPadding: CGFloat = 52
        let itemWidth = (screenWidth - totalHorizontalPadding) / columnCount
        
        // Cell 内部左右间距 (contentView 里的约束 offset)
        let cellInnerPadding: CGFloat = 24 // left(12) + right(12)
        let textAvailableWidth = itemWidth - cellInnerPadding
        
        // 垂直方向间距
        let topPadding: CGFloat = 12       // 标题距离顶部
        let titleToContent: CGFloat = 8    // 标题到正文
        let contentToTime: CGFloat = 12    // 正文到时间
        let timeHeight: CGFloat = 15       // 时间 Label 高度
        let bottomPadding: CGFloat = 16    // 底部距离
        
        // MARK: - 标题高度
        let titleFont = UIFont.systemFont(ofSize: 18, weight: .bold)
        // 1. 计算完全展开的高度
        let exactTitleHeight = note.title.boundingRect(
            with: CGSize(width: textAvailableWidth, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            attributes: [.font: titleFont],
            context: nil
        ).height
        
        // 2. 计算最大允许高度 (2行)
        // lineHeight * 2 + 少量buffer
        let maxTitleHeight = titleFont.lineHeight * 2 + 2
        // 取较小值，并向上取整避免渲染模糊
        let finalTitleHeight = min(ceil(exactTitleHeight), ceil(maxTitleHeight))
        
        // MARK: - 正文高度
        // 将 Markdown 图片占位符替换为短文本，避免计算偏差
        let contentText = note.content.replacingOccurrences(of: "!\\[.*?\\]\\(.*?\\)", with: "[图片]", options: .regularExpression)
        
        // 限制正文最大高度为 120 (约 6 行)
        let maxContentRenderHeight: CGFloat = 120
        let contentHeight = contentText.boundingRect(
            with: CGSize(width: textAvailableWidth, height: maxContentRenderHeight),
            options: .usesLineFragmentOrigin,
            attributes: [.font: UIFont.systemFont(ofSize: 14)],
            context: nil
        ).height
        
        // MARK: - 总高度汇总
        let totalHeight = topPadding +
                          finalTitleHeight +
                          titleToContent +
                          ceil(contentHeight) +
                          contentToTime +
                          timeHeight +
                          bottomPadding
        
        return totalHeight
    }
}
