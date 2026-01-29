//
//  NoteCollectionViewCell.swift
//  TodoNote
//
//  Created by xrt on 2026/1/28.
//

import UIKit
import SnapKit

class NoteCollectionViewCell: UICollectionViewCell {
    static let identifier = "NoteCollectionViewCell"
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.numberOfLines = 2 
        label.textColor = .black
        return label
    }()
    
    private let contentLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.numberOfLines = 6
        label.textColor = .darkGray
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12)
        label.textColor = .systemGray2
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        // 卡片样式
        contentView.layer.cornerRadius = 12
        contentView.layer.masksToBounds = true
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(contentLabel)
        contentView.addSubview(dateLabel)
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12) 
            make.leading.equalToSuperview().offset(12)
            make.trailing.equalToSuperview().offset(-12)
            make.height.greaterThanOrEqualTo(24)
        }
        
        contentLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.equalTo(titleLabel)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.top.equalTo(contentLabel.snp.bottom).offset(12)
            make.leading.equalTo(titleLabel)
            make.bottom.equalToSuperview().offset(-16)
        }
    }
    
    func configure(with note: Note) {
        contentView.backgroundColor = note.themeColor
        
        titleLabel.text = note.title.isEmpty ? "无标题" : note.title
        // 简单去除 Markdown 图片标记，只保留文字预览
        let cleanContent = note.content.replacingOccurrences(of: "!\\[.*?\\]\\(.*?\\)", with: "[图片]", options: .regularExpression)
        contentLabel.text = cleanContent
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateLabel.text = formatter.string(from: note.updatedAt)
        
        // 如果标题为空，让内容顶上去；反之亦然。这里 AutoLayout 会自动适应
        titleLabel.isHidden = note.title.isEmpty
    }
}
