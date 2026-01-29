//
//  AddNoteViewModel.swift
//  TodoNote
//
//  Created by xrt on 2026/1/28.
//

import UIKit

class AddNoteViewModel {
    
    // MARK: - Properties
    
    // 当前正在编辑的笔记对象（内存中的草稿）
    private var currentNote: Note
    
    // 标记是否有未保存的更改 
    private(set) var isDirty = false
    
    // 自动保存定时器
    private var autoSaveTimer: Timer?
    
    // 回调通知 View
    var onSaveSuccess: (() -> Void)?
    var onAutoSave: ((String) -> Void)? 
    var onError: ((String) -> Void)?
    
    // MARK: - Init
    
    /// 初始化：如果是编辑旧笔记，传入 existingNote；如果是新建，传入 nil
    init(existingNote: Note? = nil) {
        if let note = existingNote {
            self.currentNote = note
        } else {
            // 新建一个空的笔记
            self.currentNote = Note(title: "", content: "")
        }
        
        startAutoSaveTimer()
    }
    
    deinit {
        // 销毁时停止计时器，并尝试最后保存一次
        autoSaveTimer?.invalidate()
        if isDirty {
            saveImmediate()
        }
        print("AddNoteViewModel deinit")
    }
    
    // MARK: - Data Binding
    
    /// 当 View 的标题更新时调用
    func updateTitle(_ text: String) {
        guard currentNote.title != text else { return }
        currentNote.title = text
        currentNote.updatedAt = Date()
        isDirty = true
    }
    
    /// 当 View 的富文本内容更新时调用
    func updateContent(text: String) {
        // 简单比对一下内容有没有变
        if currentNote.content != text {
            currentNote.content = text
            currentNote.updatedAt = Date()
            isDirty = true
        }
    }
    
    // MARK: - Save Logic
    
    /// 用户点击"完成"按钮时调用 (强制立即保存)
    func saveNote() {
        // 可以在这里加校验，比如标题内容都空就不存
        guard !currentNote.title.isEmpty || !currentNote.content.isEmpty else {
            // 如果是空的，可能意味着用户想取消，或者是误触
            // 这里看产品逻辑，简单起见我们允许存，或者直接 Dismiss
            onSaveSuccess?() 
            return
        }
        
        saveImmediate()
        
        // TODO: 触发云端同步逻辑 (未来实现)
        
        onSaveSuccess?()
    }
    
    /// 触发 30s 自动保存
    private func startAutoSaveTimer() {
        // runLoop mode default 可能会在滚动时暂停，common 模式更稳
        autoSaveTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(timerTick), userInfo: nil, repeats: true)
    }
    
    @objc private func timerTick() {
        if isDirty {
            print("🕒 [AutoSave] 触发自动保存: \(currentNote.id)")
            saveImmediate()
        }
    }
    
    /// 执行真正的写入磁盘操作
    private func saveImmediate() {
        NoteManager.shared.saveNote(currentNote)
        isDirty = false
        
        // 生成当前时间字符串
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let timeStr = "保存于 " + formatter.string(from: Date())
        
        // 通知 UI 更新文字
        onAutoSave?(timeStr)
    }
    
    // Expose data for View
    var initialTitle: String {
        return currentNote.title
    }
    
    var initialContent: String {
        return currentNote.content
    }
}
