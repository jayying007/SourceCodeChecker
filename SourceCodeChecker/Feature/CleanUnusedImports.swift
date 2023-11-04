//
//  CleanUnusedImports.swift
//  SourceCodeChecker
//
//  Created by janezhuang on 2023/11/4.
//

import Foundation

// 获取递归后所有的import
class CleanUnusedImports: NSObject {
    func find(files: [String: File]) -> [String: Object] {
        var allFiles = [String: File]() // 需要查找的头文件
        var newFiles = [String: File]() // 递归全的文件

        var allObjects = [String: Object]()
        var allUsedObjects = [String: Object]()

        for (_, aFile) in files {
            allFiles[aFile.name] = aFile
        }
        for (_, aFile) in allFiles {
            // 单文件处理
            aFile.recursionImports = self.fetchImports(file: aFile, allFiles: allFiles, allRecursionImports: [Import]())
            // 记录所有import的的类
            for aImport in aFile.recursionImports {
                for (name, aObj) in aImport.file.objects {
                    // 全部类
                    aFile.importObjects[name] = aObj
                    allObjects[name] = aObj
                }
            }
            newFiles[aFile.name] = aFile
            // 处理无用的import
            // 记录所有用过的类
            for aMethod in aFile.methods {
                let results = ParsingMethodContent.parsing(method: aMethod, file: aFile)
                for result in results {
                    let aObj = result
                    allUsedObjects[aObj.name] = aObj
                }
            }
            // 记录类的父类，作为已用类
            for (_, value) in allObjects {
                if value.superName.count > 0 {
                    guard let obj = allObjects[value.superName] else {
                        continue
                    }
                    allUsedObjects[value.superName] = obj
                }
            }
        }
        //            print("\(allObjects.keys)")
        //            print("-----------------------")
        //            print("\(allUsedObjects.keys)")
        // 遍历对比出无用的类
        var allUnUsedObjects = [String: Object]()
        for (key, value) in allObjects {
            guard let _ = allUsedObjects[key] else {
                allUnUsedObjects[key] = value
                continue
            }
        }

        return allUnUsedObjects
    }

    // 递归获取所有import
    func fetchImports(file: File, allFiles: [String: File], allRecursionImports: [Import]) -> [Import] {
        var allRecursionImports = allRecursionImports
        for aImport in file.imports {

            guard let importFile = allFiles[aImport.fileName] else {
                continue
            }
            if !checkIfContain(aImport: aImport, inImports: allRecursionImports) {
                allRecursionImports.append(addFileObjectTo(aImport: aImport, allFiles: allFiles))
            } else {
                continue
            }

            let reRecursionImports = fetchImports(file: importFile, allFiles: allFiles, allRecursionImports: allRecursionImports)
            for aImport in reRecursionImports {
                if !checkIfContain(aImport: aImport, inImports: allRecursionImports) {
                    allRecursionImports.append(addFileObjectTo(aImport: aImport, allFiles: allFiles))
                }
            }

        }
        return allRecursionImports
    }

    func addFileObjectTo(aImport: Import, allFiles: [String: File]) -> Import {
        var mImport = aImport
        guard let aFile =  allFiles[aImport.fileName] else {
            return aImport
        }
        mImport.file = aFile
        return mImport
    }

    func checkIfContain(aImport: Import, inImports: [Import]) -> Bool {
        let tf = inImports.contains { element in
            if aImport.fileName == element.fileName {
                return true
            } else {
                return false
            }
        }
        return tf
    }
}
