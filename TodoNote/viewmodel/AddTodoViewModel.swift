//
//  AddTodoViewModel.swift
//  TodoNote
//
//  Created by xrt on 2026/2/9.
//

import Foundation

class AddTodoViewModel {
    
    // MARK: - Inputs
    var title: String = ""
    var dueDate: Date = Date()
    var hasDueDate: Bool = false
    /// 可选：关联的笔记 ID
    var relatedNoteId: UUID?
    
    // MARK: - Outputs
    var onError: ((String) -> Void)?
    var onSuccess: (() -> Void)?
    
    // MARK: - Actions
    func saveTodo() {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            onError?("内容不能为空")
            return
        }
        
        let due = hasDueDate ? dueDate : nil
        let newTodo = Todo(title: title, dueDate: due, noteId: relatedNoteId)
        
        TodoManager.shared.save(todo: newTodo)
        onSuccess?()
    }
}
