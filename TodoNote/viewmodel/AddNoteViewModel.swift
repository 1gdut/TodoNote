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
            onSaveSuccess?() 
            return
        }
        // 1.保存为pdf，名字存到相印字段
        if let pdfURL = PDFGenerator.createPDF(from: currentNote) {
            let fileManager = FileManager.default
            // 获取 Documents 目录
            if let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
                // 如果之前有 PDF 文件名，拼接完整路径并删除旧文件
                if let oldFileName = currentNote.notePDFName {
                    // 兼容处理：如果旧数据存的是绝对路径，直接尝试删除
                    if oldFileName.hasPrefix("/") {
                        if fileManager.fileExists(atPath: oldFileName) {
                            try? fileManager.removeItem(atPath: oldFileName)
                            print("Deleted old PDF at absolute path: \(oldFileName)")
                        }
                    } else {
                        // 标准处理：拼接 Documents 路径
                        let oldPDFPath = documentsDir.appendingPathComponent(oldFileName).path
                        if fileManager.fileExists(atPath: oldPDFPath) {
                            try? fileManager.removeItem(atPath: oldPDFPath)
                            print("Deleted old PDF at: \(oldPDFPath)")
                        }
                    }
                }
            }
            
            // 只保存文件名，不存绝对路径
            currentNote.notePDFName = pdfURL.lastPathComponent
            print("PDF generated at: \(pdfURL.path)")
        }
        
        // 2.先检查如果有旧的id，先调用删除接口，后上传文件，保存文档id
        if currentNote.knowledgeDocumentId != nil {
            //掉用删除文档方法，然后上传新的文档
        } else {
            //上传并保存文档id
        }
        saveImmediate()
        

        
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
