//
//  TodoViewController.swift
//  TodoNote
//
//  Created by xrt on 2025/11/30.
//

import UIKit
import SnapKit

class TodoViewController: UIViewController {
    
    private let viewModel = TodoListViewModel()
    
    // MARK: - UI Components
    
    private lazy var tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.backgroundColor = .white
        tv.delegate = self
        tv.dataSource = self
        tv.register(TodoTableViewCell.self, forCellReuseIdentifier: TodoTableViewCell.identifier)
        tv.separatorStyle = .none
        tv.estimatedRowHeight = 60
        tv.rowHeight = UITableView.automaticDimension
        return tv
    }()
    
    private lazy var emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "暂无待办，去创建一个吧~"
        label.textColor = .secondaryLabel
        label.font = .systemFont(ofSize: 16)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        
        // Initial load
        viewModel.loadTodos()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(tableView)
        view.addSubview(emptyLabel)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-50)
        }
    }
    
    private func setupBindings() {
        viewModel.onDataUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.tableView.reloadData()
                self?.updateEmptyState()
            }
        }
    }
    
    private func updateEmptyState() {
        let isEmpty = viewModel.todos.isEmpty
        emptyLabel.isHidden = !isEmpty
        tableView.isHidden = isEmpty
    }
    
}

// MARK: - UITableViewDelegate, UITableViewDataSource
extension TodoViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.todos.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TodoTableViewCell.identifier, for: indexPath) as? TodoTableViewCell else {
            return UITableViewCell()
        }
        
        let todo = viewModel.todos[indexPath.row]
        cell.configure(with: todo)
        
        // Handle checkbox tap
        cell.onToggleCompletion = { [weak self] in
            // UI update handled by reload from notification in ViewModel -> View
            self?.viewModel.toggleCompletion(at: indexPath.row)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let todo = viewModel.todos[indexPath.row]
        if let noteId = todo.noteId {
            print("Trying to jump to note: \(noteId)")
            // TODO: Implement navigation to linked note
        }
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "删除") { [weak self] (action, view, completion) in
            self?.viewModel.deleteTodo(at: indexPath.row)
            completion(true)
        }
        deleteAction.image = UIImage(systemName: "trash")
        
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}
