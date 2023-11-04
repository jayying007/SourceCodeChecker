//
//  DragView.swift
//  SourceCodeChecker
//
//  Created by janezhuang on 2023/11/4.
//

import Cocoa

protocol DragViewDelegate: NSObjectProtocol {
    func dragFileOk(filePath: String)
}

class DragView: NSView {
    weak var delegate: DragViewDelegate?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.registerForDraggedTypes([.fileURL, .URL, .tiff])
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.generic
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        var filePath = ""
        if let board = sender.draggingPasteboard.propertyList(forType: NSPasteboard.PasteboardType(rawValue: "NSFilenamesPboardType")) as? NSArray {
            for path in board {
                filePath = path as! String
            }
        }
        if let delegate = self.delegate {
            delegate.dragFileOk(filePath: filePath)
        }
        return true
    }
}
