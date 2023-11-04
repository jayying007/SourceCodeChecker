//
//  CleanUnusedMethods.swift
//  SourceCodeChecker
//
//  Created by janezhuang on 2023/11/4.
//

import Foundation

class CleanUnusedMethods: NSObject {

    private var methodsDefinedInHFile = [Method]() // h文件定义的方法集合
    private var methodsDefinedInMFile = [Method]() // m文件定义的方法集合
    private var methodsUsed = [Method]()    // 用过的方法集合
    private var protocols = [String: Protocol]() // delegate
    private var marcros = [String: Macro]()     // 宏

    func find(files: [String: File]) -> [Method] {
        var index = 1
        for (fileName, aFile) in files {
            // 显示parsing的状态
            print("进度：\(index)/\(files.count) 正在查询文件：\(fileName)")
            index += 1
            self.findIn(file: aFile)
        }

        // todo:去重
        let methodsUsedSet = Set(methodsUsed.map({ method in
            return method.pnameId
        })) // 用过方法
        let methodsMFileSet = Set(methodsDefinedInMFile.map({ method in
            return method.pnameId
        })) // m的映射文件

        print("H方法：\(methodsDefinedInHFile.count)个")
        print("M方法：\(methodsDefinedInMFile.count)个")
        print("用过方法(包括系统的)：\(methodsUsed.count)个")
        // 找出h文件中没有用过的方法
        var unUsedMethods = [Method]()
        for aHMethod in methodsDefinedInHFile {
            // 第一种无参数的情况暂时先过滤。
            if aHMethod.params.count == 1 && aHMethod.params[0].type == "" {
                continue
            }
            // 第二种^这种情况过滤
            if aHMethod.returnTypeBlockTf {
                continue
            }
            // 这里判断的是delegate类型，m里一定没有定义，所以这里过滤了各个delegate
            // todo:处理delegate这样的情况
            // 翻译一下：找到那些h有定义、m有实现，但是没有调用过的方法
            if !methodsUsedSet.contains(aHMethod.pnameId) && methodsMFileSet.contains(aHMethod.pnameId) {
                // todo:定义一些继承的类，将继承方法加入头文件中的情况
                unUsedMethods.append(aHMethod)
            }
        }

        return unUsedMethods
    }
    // 删除
    func clean(methods: [Method]) {
        ParsingBase.delete(methods: methods)
    }

    // MARK: Private
    private func findIn(file aFile: File) {
        self.parsing(withFile: aFile)
        // h文件 m文件
        guard aFile.type == FileType.FileH || aFile.type == FileType.FileM else {
            return
        }

        let content = aFile.content
        let tokens = ParsingBase.createOCTokens(conent: content)
        // ---------根据token切割-----------
        // 方法解析
        var mtdArr = [String]() // 方法字符串
        var psMtdTf = false // 是否在解析方法
        var psMtdStep = 0
        // 方法内部解析
        var mtdContentArr = [String]()
        var psMtdContentClass = Method() // 正在解析的那个方法
        var psMtdContentTf = false  // 是否正在解析那个方法中实现部分内容
        var psMtdContentBraceCount = 0 // 大括号计数
        // 获取当前object
        var currentObject = Object()
        var parseImplementationTf = false

        for tk in tokens {
            // 设置使用哪个obj，根据implement
            if aFile.type == FileType.FileM {
                if tk == Sb.atImplementation && !parseImplementationTf {
                    parseImplementationTf = true
                    continue
                }
                if parseImplementationTf {
                    parseImplementationTf = false

                    guard let cObject = aFile.objects[tk] else {
                        continue
                    }
                    currentObject = cObject
                    continue
                }
            }

            // 解析方法内容
            if psMtdContentTf {
                if tk == Sb.braceL {
                    mtdContentArr.append(tk)
                    psMtdContentBraceCount += 1
                } else if tk == Sb.braceR {
                    mtdContentArr.append(tk)
                    psMtdContentBraceCount -= 1
                    if psMtdContentBraceCount == 0 {
                        var reMethod = ParsingMethodContent.parsing(contentArr: mtdContentArr, inMethod: psMtdContentClass)
                        aFile.methods.append(reMethod)
                        currentObject.methods.append(reMethod)
                        reMethod.filePath = aFile.path // 将m文件路径赋给方法
                        methodsDefinedInMFile.append(reMethod)
                        if reMethod.usedMethod.count > 0 {
                            for aUsedMethod in reMethod.usedMethod {
                                // 将用过的方法添加到集合中
                                methodsUsed.append(aUsedMethod)
                            }
                        }
                        // 结束
                        mtdContentArr = []
                        psMtdTf = false
                        psMtdContentTf = false
                    }
                } else {
                    // 解析方法内容中
                    // 先解析使用的方法
                    mtdContentArr.append(tk)
                }
                continue
            } // 方法内容处理结束

            // 方法解析
            // 如果-和(没有连接起来直接判断不是方法
            if psMtdStep == 1 && tk != Sb.rBktL {
                psMtdStep = 0
                psMtdTf = false
                mtdArr = []
            }

            if (tk == Sb.minus || tk == Sb.add) && psMtdStep == 0 && !psMtdTf {
                psMtdTf = true
                psMtdStep = 1
                mtdArr.append(tk)
            } else if tk == Sb.rBktL && psMtdStep == 1 && psMtdTf {
                psMtdStep = 2
                mtdArr.append(tk)
            } else if (tk == Sb.semicolon || tk == Sb.braceL) && psMtdStep == 2 && psMtdTf {
                mtdArr.append(tk)
                var parsedMethod = ParsingMethod.parsing(tokens: mtdArr)
                // 开始处理方法内部
                if tk == Sb.braceL {
                    psMtdContentClass = parsedMethod
                    psMtdContentTf = true
                    psMtdContentBraceCount += 1
                    mtdContentArr.append(tk)
                } else {
                    aFile.methods.append(parsedMethod)
                    parsedMethod.filePath = aFile.path // 将h文件的路径赋给方法
                    methodsDefinedInHFile.append(parsedMethod)
                    psMtdTf = false
                }
                // 重置
                psMtdStep = 0
                mtdArr = []
            } else if psMtdTf {
                mtdArr.append(tk)
            }
        }
    }

    // 解析aFile中的数据结构
    private func parsing(withFile aFile: File) {
        // ----------根据行数切割----------
        let content = aFile.content
        let lines = ParsingBase.createOCLines(content: content)

        var inInterfaceTf = false
        var inImplementationTf = false
        var inProtocolTf = false
        var currentProtocolName = ""
        var obj = Object()

        for var aLine in lines {
            // 清理头尾
            aLine = aLine.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
            if aLine.count == 0 {
                continue
            }

            let tokens = ParsingBase.createOCTokens(conent: aLine)
            // 处理 #define start
            if aLine.hasPrefix(Sb.defineStr) {
                // 处理宏定义的方法
                let reMethod = ParsingMethodContent.parsing(contentArr: tokens, inMethod: Method())
                if reMethod.usedMethod.count > 0 {
                    for aUsedMethod in reMethod.usedMethod {
                        // 将用过的方法添加到集合中
                        methodsUsed.append(aUsedMethod)
                    }
                }
                // 保存在文件结构体中
                let aMarcro = ParsingMacro.parsing(line: aLine)
                aFile.macros[aMarcro.name] = aMarcro // 添加到文件的集合里
                marcros[aMarcro.name] = aMarcro      // 添加到全局里
                continue
            }// #define end

            // 处理 #import start
            if aLine.hasPrefix(Sb.importStr) {
                let imp = ParsingImport.parsing(tokens: tokens)
                guard imp.fileName.count > 0 else {
                    continue
                }
                aFile.imports.append(imp)
                continue
            }// #import end

            // 处理 @interface
            if aLine.hasPrefix(Sb.atInteface) && !inInterfaceTf {
                inInterfaceTf = true
                inProtocolTf = false
                currentProtocolName = ""

                // 查找文件中是否有该类，有就使用那个，没有就创建一个
                let objName = ParsingInterface.parsingNameFrom(line: aLine)
                if !aFile.objects.keys.contains(objName) {
                    obj = Object()
                    aFile.objects[objName] = obj
                }

                ParsingInterface.parsing(line: aLine, inObject: obj)
                continue
            }
            if inInterfaceTf && aLine.hasPrefix(Sb.atProperty) {
                // 处理属性
                let aProperty = ParsingProperty.parsing(tokens: tokens)
                obj.properties.append(aProperty)
            }
            if aLine.hasPrefix(Sb.atEnd) && inInterfaceTf {
                inInterfaceTf = false
                inProtocolTf = false
                currentProtocolName = ""
                continue
            }

            // 处理 @implementation
            if aLine.hasPrefix(Sb.atImplementation) && !inImplementationTf {
                inImplementationTf = true
                // 暂不处理
                continue
            }
            if aLine.hasPrefix(Sb.atEnd) && inImplementationTf {
                inImplementationTf = false
                inProtocolTf = false
                currentProtocolName = ""
                continue
            }

            // 处理 @protocol
            if aLine.hasPrefix(Sb.atProtocol) && !inProtocolTf {
                inProtocolTf = true
                currentProtocolName = ParsingProtocol.parsingNameFrom(line: aLine)
                // 检查是否已经存在该protocol
                if !protocols.keys.contains(currentProtocolName) {
                    var newPro = Protocol()
                    newPro.name = currentProtocolName
                    protocols[currentProtocolName] = newPro
                }
                continue
            }
            if inProtocolTf && currentProtocolName != "" {
                // 开始处理protocol里的方法
                if !aLine.hasPrefix(Sb.atOptional) || !aLine.hasPrefix(Sb.atRequired) {
                    let pMtd = ParsingMethod.parsing(tokens: tokens)
                    if pMtd.pnameId != "" {
                        protocols[currentProtocolName]?.methods.append(pMtd)
                    }
                }
            }
            if aLine.hasPrefix(Sb.atEnd) && inProtocolTf {
                inProtocolTf = false
                currentProtocolName = ""
                continue
            }
        } // 遍历lines，行数组
    }
}
