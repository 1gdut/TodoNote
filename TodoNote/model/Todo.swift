//
//  Todo.swift
//  TodoNote
//
//  Created by xrt on 2026/2/9.
//

import Foundation

struct Todo: Identifiable, Codable {
    let id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    /// 关联的笔记 ID（实现笔记-待办跳转）
    var noteId: UUID?
    let createdAt: Date
    
    init(id: UUID = UUID(), title: String, isCompleted: Bool = false, dueDate: Date? = nil, noteId: UUID? = nil, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.noteId = noteId
        self.createdAt = createdAt
    }
}
