import Foundation
import Commander

let currentDir = FileManager.default.currentDirectoryPath

//func getIgnoreFiles(gitignoreFileURL: URL?) -> [URL] {
//
//    guard let gitignoreFileURL = gitignoreFileURL else {
//        return []
//    }
//
//    do {
//        let string = try String(contentsOf: gitignoreFileURL)
//
//        for line in string.split(separator: "\n") {
//            let url = (currentDir as NSString).appendingPathComponent(line)
//        }
//
//    } catch let error {
//        print(error)
//    }
//
//    return []
//}

let main = command(Option("strings", default: "Localizable.strings"),
                   Option("searchDir", default: ""),
                   Option("rPrefix", default: "R.string.localizable"),
                   Option("swiftGenPrefix", default: "L10n")) { strings, searchDir, rprefix, swiftGenPrefix in
    let currentDirURL = URL(fileURLWithPath: currentDir)
    var swiftFiles = [URL]()
    var stringsFileURL: URL? = URL(fileURLWithPath: (currentDir as NSString).appendingPathComponent(strings))
    let searchDirURL = URL(fileURLWithPath: currentDir)
    
    guard let strings = stringsFileURL, strings.pathExtension == "strings" else {
        fatalError()
    }
    
//    let gitignoreFile = (currentDir as NSString).appendingPathComponent(".gitignore")
//
//    let gitignoreFiles = getIgnoreFiles(gitignoreFileURL: URL(fileURLWithPath: gitignoreFile))
    
    let r2SwiftGen = R2SwiftGen(rswiftPrefix: rprefix, swiftGenPrefix: swiftGenPrefix)
    
    let podPath = (currentDir as NSString).appendingPathComponent("Pods")
    
    let vendorPath = (currentDir as NSString).appendingPathComponent("vendor")
    
    let spmToolsPath = (currentDir as NSString).appendingPathComponent("SwiftPMTools")
    
    print("currentDir: \(currentDir), stringsFileURL: \(stringsFileURL), rPrefix: \(rprefix), swiftGenPrefix: \(swiftGenPrefix), podPath: \(podPath), vendorPath: \(vendorPath)")

    if let enumerator = FileManager.default.enumerator(at: currentDirURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
        for case let fileURL as URL in enumerator {
            do {
                let pathExtension = fileURL.pathExtension

                let isDirectory = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? true
                if pathExtension == "swift" {
                    if !fileURL.absoluteString.hasSuffix("main.swift") &&
                        !fileURL.absoluteString.hasSuffix("generated.swift") &&
                        !isDirectory,
                        !fileURL.path.hasPrefix(podPath) &&
                        !fileURL.path.hasPrefix(vendorPath) &&
                        !fileURL.path.hasPrefix(spmToolsPath){
                        swiftFiles.append(fileURL)
                    }
                }

                if pathExtension == "strings" {
                    if stringsFileURL == nil {
                        stringsFileURL = fileURL
                    }
                }

            } catch let error {
                print(error, fileURL)
            }
        }
    }

    print("swiftFiles.count: \(swiftFiles.count)")
    print("strings file: \(stringsFileURL)")

    guard let stringsFileURL = stringsFileURL else {
        fatalError()
    }

    r2SwiftGen.generateCodeTable(stringsFileURL: stringsFileURL)

    for file in swiftFiles {

        r2SwiftGen.replaceFile(inputFile: file)

        print("--------------------replaced file \(file.absoluteString)-----------------------")
    }
}

main.run()

