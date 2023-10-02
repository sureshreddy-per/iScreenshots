//
//  ExtendedDescriptionView.swift
//  iScreenshots
//
//  Created by Suresh Reddy on 02/10/23.
//

import UIKit
final class ExtendedDescriptionView : BottomBasePopupView {

    lazy var mTableView : UITableView = {
        let table = UITableView(frame: .zero)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.showsVerticalScrollIndicator = true
        table.clipsToBounds = true
        return table
    }()
    
    lazy var topBarView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .darkGray
        view.layer.cornerRadius = 3
        return view
    }()
    
    var text = ""
    
    init(text: String) {
        self.text = text
        super.init(frame: .zero)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {

        backgroundColor = UIColor.white
        mTableView.delegate = self
        mTableView.dataSource = self
        addSubview(topBarView)
        addSubview(mTableView)
        mTableView.register(UITableViewCell.self, forCellReuseIdentifier: "defaultCell")
        topBarView.addConstraints(topAnchor,
                                  bottom: mTableView.topAnchor,
                                  centerX: centerXAnchor,
                                  topConstant: 12,
                                  bottomConstant: 16,
                                  widthConstant: 64,
                                  heightConstant: 6)
        mTableView.addConstraints(left: leftAnchor,
                                       bottom: safeAreaLayoutGuide.bottomAnchor,
                                       right: rightAnchor)
    }
    private func reloadData() {
        DispatchQueue.main.async {
            self.mTableView.reloadData()
        }
    }

    func height()->CGFloat{
        300
    }
}
extension ExtendedDescriptionView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "defaultCell", for: indexPath)
        cell.textLabel?.numberOfLines = 0
        cell.selectionStyle = .none
        cell.textLabel?.text = text
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Description"
    }
}
