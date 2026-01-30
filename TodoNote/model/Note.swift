//
//  Note.swift
//  TodoNote
//
//  Created by xrt on 2026/1/28.
//
import Foundation
import UIKit

struct Note: Identifiable, Codable {
    /// 笔记的唯一标识符
    let id: UUID
    
    /// 标题
    var title: String
    
    /// 内容 (Markdown 格式，包含 ![image](uuid.jpg) 链接)
    var content: String
    
    /// 创建时间
    let createdAt: Date
    
    /// 最后修改时间
    var updatedAt: Date
    
    /// 智谱 AI 知识库中的文档 ID (用于同步更新：先删后传)
    /// 如果为 nil，说明从未上传过
    var knowledgeDocumentId: String?
    
    /// 笔记中引用的本地图片文件名列表 (用于资源管理)
    var imageAttachmentNames: [String]
    
    //笔记存为pdf后的名字
    var notePDFName: String?
    
    /// 主题色索引 (0-5)
    var themeColorIndex: Int
    
    // MARK: - CodingKeys
    enum CodingKeys: String, CodingKey {
        case id, title, content, createdAt, updatedAt, knowledgeDocumentId, imageAttachmentNames, themeColorIndex, notePDFName
    }
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        knowledgeDocumentId: String? = nil,
        imageAttachmentNames: [String] = [],
        notePDFName: String? = nil,
        themeColorIndex: Int = 0
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.knowledgeDocumentId = knowledgeDocumentId
        self.imageAttachmentNames = imageAttachmentNames
        self.notePDFName = notePDFName
        self.themeColorIndex = themeColorIndex
    }
    
    // 手动实现 Decodable 以兼容旧数据
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        content = try container.decode(String.self, forKey: .content)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        knowledgeDocumentId = try container.decodeIfPresent(String.self, forKey: .knowledgeDocumentId)
        
        // 如果旧数据没有这些字段，提供默认值
        imageAttachmentNames = try container.decodeIfPresent([String].self, forKey: .imageAttachmentNames) ?? []
        themeColorIndex = try container.decodeIfPresent(Int.self, forKey: .themeColorIndex) ?? Int.random(in: 0...5)
        notePDFName = try container.decodeIfPresent(String.self, forKey: .notePDFName)
    }
}



// MARK: - Theme Helpers
extension Note {
    var themeColor: UIColor {
        let colors: [UIColor] = [
            UIColor(hex: "#FEE2E2"), // 柔红
            UIColor(hex: "#FEF3C7"), // 暖黄
            UIColor(hex: "#D1FAE5"), // 薄荷
            UIColor(hex: "#DBEAFE"), // 冰蓝
            UIColor(hex: "#EDE9FE"), // 香芋
            UIColor(hex: "#F3F4F6")  // 银灰
        ]
        let index = max(0, themeColorIndex)
        return colors[index % colors.count]
    }
}
