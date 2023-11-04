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
                pathLabel.stringValue = "工程路径：" + selectedPath.replacingOccurrences(of: "file://", with: "")
            }
        }
    }
    var unusedMethods = [Method]()
    var unusedImports = [String: Object]()

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
    }

    @objc func onClickSearchButton() {
        if selectedPath.count > 0 {
            searchingUnusedMethods()
        }
    }

    // MARK: Private
    private func searchingUnusedMethods() {
        DispatchQueue.global().async {
            let files = self.filesIn(path: self.selectedPath)
            self.unusedMethods = CleanUnusedMethods().find(files: files)
            self.unusedImports = CleanUnusedImports().find(files: files)
        }
    }

    private func filesIn(path: String) -> [String: File] {
        let fileFolderPath = path
        let fileFolderStringPath = fileFolderPath.replacingOccurrences(of: "file://", with: "")
        let fileManager = FileManager.default
        // 深度遍历
        let enumeratorAtPath = fileManager.enumerator(atPath: fileFolderStringPath)
        // 过滤文件后缀
        let filterPaths = NSArray(array: (enumeratorAtPath?.allObjects)!).pathsMatchingExtensions(["h", "m"])
        print("过滤后缀后的文件: \(filterPaths)")

        var result = [String: File]()
        // 遍历文件夹下所有文件
        for filePathString in filterPaths {
            var fullPath = fileFolderPath
            fullPath.append(filePathString)
            // 读取文件内容
            let fileUrl = URL(string: fullPath)

            let aFile = File()
            aFile.path = fullPath
            let content = try! String(contentsOf: fileUrl!, encoding: String.Encoding.utf8)
            aFile.content = content
            result[aFile.name] = aFile
        }
        return result
    }

    // MARK: DragViewDelegate
    func dragFileOk(filePath: String) {
        selectedPath = "file://" + filePath + "/"
    }
}
