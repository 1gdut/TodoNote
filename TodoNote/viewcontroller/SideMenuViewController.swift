//
//  SideMenuViewController.swift
//  TodoNote
//
//  Created by xrt on 2025/11/30.
//

import UIKit
import SnapKit

protocol SideMenuDelegate: AnyObject {
    func sideMenuDidSelectItem(_ item: SideMenuItem)
    func sideMenuDidClose()
}

enum SideMenuItem {
    case profile
    case settings
    case about
    case logout
}

class SideMenuViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: SideMenuDelegate?
    
    // MARK: - UI Components
    
    /// 头像
    private lazy var avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle.fill")
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.layer.cornerRadius = 40
        imageView.clipsToBounds = true
        return imageView
    }()
    
    /// 用户名
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.text = "用户名"
        label.font = .systemFont(ofSize: 18, weight: .semibold)
        label.textColor = .black
        return label
    }()
    
    /// 邮箱
    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.text = "user@example.com"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .gray
        return label
    }()
    
    /// 分割线
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    /// 菜单列表
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.register(SideMenuCell.self, forCellReuseIdentifier: "SideMenuCell")
        return tableView
    }()
    
    /// 版本信息
    private lazy var versionLabel: UILabel = {
        let label = UILabel()
        label.text = "版本 1.0.0"
        label.font = .systemFont(ofSize: 12)
        label.textColor = .lightGray
        label.textAlignment = .center
        return label
    }()
    
    // MARK: - Data
    
    private let menuItems: [(icon: String, title: String, item: SideMenuItem)] = [
        ("person.circle", "个人资料", .profile),
        ("gearshape", "设置", .settings),
        ("info.circle", "关于", .about),
        ("rectangle.portrait.and.arrow.right", "退出登录", .logout)
    ]
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .white
        
        view.addSubview(avatarImageView)
        view.addSubview(usernameLabel)
        view.addSubview(emailLabel)
        view.addSubview(separatorView)
        view.addSubview(tableView)
        view.addSubview(versionLabel)
        
        avatarImageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(30)
            make.left.equalToSuperview().offset(20)
            make.width.height.equalTo(80)
        }
        
        usernameLabel.snp.makeConstraints { make in
            make.top.equalTo(avatarImageView.snp.bottom).offset(16)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
        }
        
        emailLabel.snp.makeConstraints { make in
            make.top.equalTo(usernameLabel.snp.bottom).offset(4)
            make.left.right.equalTo(usernameLabel)
        }
        
        separatorView.snp.makeConstraints { make in
            make.top.equalTo(emailLabel.snp.bottom).offset(20)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview()
            make.height.equalTo(1)
        }
        
        tableView.snp.makeConstraints { make in
            make.top.equalTo(separatorView.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(versionLabel.snp.top).offset(-20)
        }
        
        versionLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.centerX.equalToSuperview()
        }
    }
    
    // MARK: - Public Methods
    
    func updateUserInfo(name: String, email: String, avatar: UIImage?) {
        usernameLabel.text = name
        emailLabel.text = email
        if let avatar = avatar {
            avatarImageView.image = avatar
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension SideMenuViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SideMenuCell", for: indexPath) as! SideMenuCell
        let item = menuItems[indexPath.row]
        cell.configure(icon: item.icon, title: item.title)
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let item = menuItems[indexPath.row]
        delegate?.sideMenuDidSelectItem(item.item)
    }
}

// MARK: - SideMenuCell

class SideMenuCell: UITableViewCell {
    
    private lazy var iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.tintColor = .darkGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .darkGray
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = .clear
        
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconImageView.snp.right).offset(16)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-20)
        }
    }
    
    func configure(icon: String, title: String) {
        iconImageView.image = UIImage(systemName: icon)
        titleLabel.text = title
    }
}
