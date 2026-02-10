//
//  TodoListViewModel.swift
//  TodoNote
//
//  Created by xrt on 2026/2/9.
//

import Foundation

class TodoListViewModel {
    
    // MARK: - Properties
    
    private(set) var todos: [Todo] = []
    
    // MARK: - Outputs
    
    var onDataUpdated: (() -> Void)?
    
    // MARK: - Initialization
    
    init() {
        // 监听数据变化通知
        NotificationCenter.default.addObserver(self, selector: #selector(handleTodoListChanged), name: .todoListChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func loadTodos() {
        todos = TodoManager.shared.loadAllTodos()
        onDataUpdated?()
    }
    
    func deleteTodo(at index: Int) {
        guard index >= 0 && index < todos.count else { return }
        let todo = todos[index]
        TodoManager.shared.delete(todoId: todo.id)
        // Manager will post notification, which triggers reload, or we can update locally for speed
        // For now relying on notification or re-fetching is safer for consistency
    }
    
    func toggleCompletion(at index: Int) {
        guard index >= 0 && index < todos.count else { return }
        var todo = todos[index]
        todo.isCompleted.toggle()
        TodoManager.shared.save(todo: todo)
    }
    
    // MARK: - Private Methods
    
    @objc private func handleTodoListChanged() {
        loadTodos()
    }
}
