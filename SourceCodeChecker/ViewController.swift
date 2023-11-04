//
//  ViewController.swift
//  SourceCodeChecker
//
//  Created by janezhuang on 2023/11/4.
//

import Cocoa
import SnapKit

class ViewController: NSViewController, DragViewDelegate {

    var dragView = DragView()
    var pathLabel = NSTextField(string: "工程路径：")
    var searchButton = NSButton(title: "查找", target: self, action: #selector(onClickSearchButton))

    var selectedPath: String = "" {
        didSet {
            if selectedPath.count > 0 {
                let ud = UserDefaults()
                ud.set(selectedPath, forKey: "selectedPath")
                ud.synchronize()
                pathLabel.stringValue = "工程路径：" + selectedPath.replacingOccurrences(of: "file://", with: "")
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        dragView.delegate = self
        view.addSubview(dragView)
        pathLabel.isEditable = false
        dragView.addSubview(pathLabel)
        dragView.addSubview(searchButton)

        dragView.snp.makeConstraints { make in
            make.edges.equalTo(self.view.snp.edges)
        }
        pathLabel.snp.makeConstraints { make in
            make.top.equalTo(dragView.snp.top)
        }
        searchButton.snp.makeConstraints { make in
            make.top.equalTo(dragView.snp.top)
            make.right.equalTo(dragView.snp.right)
        }

        if UserDefaults().object(forKey: "selectedPath") != nil {
            selectedPath = UserDefaults().value(forKey: "selectedPath") as! String
        }
    }

    @objc func onClickSearchButton() {
        print(selectedPath)
    }

    // MARK: DragViewDelegate
    func dragFileOk(filePath: String) {
        selectedPath = "file://" + filePath + "/"
    }
}
