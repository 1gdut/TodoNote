//
//  ImageStorageManager.swift
//  TodoNote
//
//  Created by xrt on 2026/1/28.
//

import UIKit

class ImageStorageManager {
    static let shared = ImageStorageManager()
    
    // 获取图片存储的根目录
    private var imagesDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let dir = documentsDirectory.appendingPathComponent("NoteImages")
        
        // 如果目录不存在，创建它
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }
    
    // 1. 保存图片，返回文件名 (例如 "uuid.jpg")
    func saveImage(_ image: UIImage) -> String? {
        let uuid = UUID().uuidString
        let fileName = "\(uuid).jpg"
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        
        // 压缩图片并写入 (JPEG 0.8是一个不错的平衡点)
        guard let data = image.jpegData(compressionQuality: 0.8) else { return nil }
        
        do {
            try data.write(to: fileURL)
            return fileName
        } catch {
            print("保存图片失败: \(error)")
            return nil
        }
    }
    
    // 2. 读取图片
    func loadImage(named fileName: String) -> UIImage? {
        // 防止文件名为空
        guard !fileName.isEmpty else { return nil }
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    // 3. 删除图片
    func deleteImage(named fileName: String) {
        guard !fileName.isEmpty else { return }
        let fileURL = imagesDirectory.appendingPathComponent(fileName)
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                try FileManager.default.removeItem(at: fileURL)
                print("图片删除成功: \(fileName)")
            }
        } catch {
            print("图片删除失败: \(error)")
        }
    }
}
