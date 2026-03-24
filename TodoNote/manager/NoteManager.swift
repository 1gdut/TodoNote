//
//  NoteManager.swift
//  TodoNote
//
//  Created by xrt on 2026/1/28.
//

import Foundation

extension Notification.Name {
    static let noteListChanged = Notification.Name("noteListChanged")
}

class NoteManager {
    static let shared = NoteManager()
    
    // 1. 定义存储文件的路径
    private var notesFileURL: URL {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectory.appendingPathComponent("notes.json")
    }
    
    // 2. 获取所有笔记
    func loadAllNotes() -> [Note] {
        guard FileManager.default.fileExists(atPath: notesFileURL.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: notesFileURL)
            let decoder = JSONDecoder()
            
            // 尝试用本地时间格式解码
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone.current
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            let notes = try decoder.decode([Note].self, from: data)
            return notes.sorted { $0.updatedAt > $1.updatedAt }
        } catch {
            // 如果失败（兼容旧数据），使用标准 ISO8601 再试一次
            do {
                let data = try Data(contentsOf: notesFileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let notes = try decoder.decode([Note].self, from: data)
                return notes.sorted { $0.updatedAt > $1.updatedAt }
            } catch {
                print("读取笔记失败: \(error)")
                return []
            }
        }
    }
    
    // 3. 保存或更新一条笔记
    func saveNote(_ note: Note) {
        var allNotes = loadAllNotes()
        
        if let index = allNotes.firstIndex(where: { $0.id == note.id }) {
            // 如果存在，就更新
            allNotes[index] = note
        } else {
            // 如果不存在，就插入到最前面
            allNotes.insert(note, at: 0)
        }
        
        saveNotesToFile(allNotes)
    }
    
    // 4. 删除笔记
    func deleteNote(id: UUID) {
        var allNotes = loadAllNotes()

        // 删除笔记前，记录关联的 todoIds，用于解除关联（不删除待办本身）
        let linkedTodoIdsToUnlink: [UUID] = allNotes.first(where: { $0.id == id })?.linkedTodoIds ?? []
        
        // 在删除笔记前，顺便把该笔记引用的图片也删掉 
        if let noteToDelete = allNotes.first(where: { $0.id == id }) {
            for imageName in noteToDelete.imageAttachmentNames {
                ImageStorageManager.shared.deleteImage(named: imageName)
            }
        }
        
        allNotes.removeAll { $0.id == id }
        saveNotesToFile(allNotes)

        // 删除笔记时：不删除待办，只解除关联
        // 1) 优先用 linkedTodoIds 做精确解除
        if !linkedTodoIdsToUnlink.isEmpty {
            let todos = TodoManager.shared.loadAllTodos()
            for todoId in linkedTodoIdsToUnlink {
                guard var todo = todos.first(where: { $0.id == todoId }) else { continue }
                if todo.noteId == id {
                    todo.noteId = nil
                    TodoManager.shared.save(todo: todo)
                }
            }
        }

        // 2) 兜底：如果笔记没维护 linkedTodoIds，但 todo.noteId 指向该笔记，也解除
        let todosLinkedByNoteId = TodoManager.shared.loadAllTodos().filter { $0.noteId == id }
        if !todosLinkedByNoteId.isEmpty {
            for var todo in todosLinkedByNoteId {
                todo.noteId = nil
                TodoManager.shared.save(todo: todo)
            }
        }
    }

    func addLinkedTodoId(noteId: UUID, todoId: UUID) {
        let allNotes = loadAllNotes()
        guard let note = allNotes.first(where: { $0.id == noteId }) else { return }
        var updated = note
        var ids = updated.linkedTodoIds ?? []
        guard !ids.contains(todoId) else { return }
        ids.append(todoId)
        updated.linkedTodoIds = ids
        updated.updatedAt = Date()
        saveNote(updated)
    }

    func removeLinkedTodoId(noteId: UUID, todoId: UUID) {
        let allNotes = loadAllNotes()
        guard let note = allNotes.first(where: { $0.id == noteId }) else { return }
        var updated = note
        guard var ids = updated.linkedTodoIds, !ids.isEmpty else { return }
        ids.removeAll { $0 == todoId }
        updated.linkedTodoIds = ids.isEmpty ? nil : ids
        updated.updatedAt = Date()
        saveNote(updated)
    }
    
    // --- 内部私有方法 ---
    
    private func saveNotesToFile(_ notes: [Note]) {
        do {
            // prettyPrinted 让 JSON 更好读，但会增加体积。生产环境可以去掉。
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            // 使用本地时间格式保存
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            formatter.timeZone = TimeZone.current
            encoder.dateEncodingStrategy = .formatted(formatter)
            
            let data = try encoder.encode(notes)
            try data.write(to: notesFileURL)
            // 发送通知
            NotificationCenter.default.post(name: .noteListChanged, object: nil)
            print("笔记保存成功！路径: \(notesFileURL.path)")
        } catch {
            print("写入文件失败: \(error)")
        }
    }
}
