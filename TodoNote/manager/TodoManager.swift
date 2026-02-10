//
//  TodoManager.swift
//  TodoNote
//
//  Created by xrt on 2026/2/9.
//

import Foundation

extension Notification.Name {
    static let todoListChanged = Notification.Name("todoListChanged")
}

class TodoManager {
    static let shared = TodoManager()
    
    private var todosFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("todos.json")
    }
    
    func loadAllTodos() -> [Todo] {
        guard FileManager.default.fileExists(atPath: todosFileURL.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: todosFileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let todos = try decoder.decode([Todo].self, from: data)
            // 按未完成在前，已完成在后；同类按时间倒序
            return todos.sorted {
                if $0.isCompleted != $1.isCompleted {
                    return !$0.isCompleted
                }
                return $0.createdAt > $1.createdAt
            }
        } catch {
            print("读取待办失败: \(error)")
            return []
        }
    }
    
    func save(todo: Todo) {
        var todos = loadAllTodos()
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index] = todo
        } else {
            todos.insert(todo, at: 0)
        }
        saveToDisk(todos: todos)
    }
    
    func delete(todoId: UUID) {
        var todos = loadAllTodos()
        todos.removeAll { $0.id == todoId }
        saveToDisk(todos: todos)
    }
    
    private func saveToDisk(todos: [Todo]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(todos)
            try data.write(to: todosFileURL)
            NotificationCenter.default.post(name: .todoListChanged, object: nil)
        } catch {
            print("保存待办失败: \(error)")
        }
    }
}
