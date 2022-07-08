import Foundation
import Commander

let currentDir = FileManager.default.currentDirectoryPath

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
    
    let r2SwiftGen = R2SwiftGen(rswiftPrefix: rprefix, swiftGenPrefix: swiftGenPrefix)
    
    let podPath = (currentDir as NSString).appendingPathComponent("Pods")
    
    let vendorPath = (currentDir as NSString).appendingPathComponent("vendor")
    
    print("currentDir: \(currentDir), stringsFileURL: \(stringsFileURL), rPrefix: \(rprefix), swiftGenPrefix: \(swiftGenPrefix), podPath: \(podPath), vendorPath: \(vendorPath)")

    if let enumerator = FileManager.default.enumerator(at: currentDirURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
        for case let fileURL as URL in enumerator {
            do {
                let pathExtension = fileURL.pathExtension

                let isDirectory = (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? true
                if pathExtension == "swift" {
                    if  !fileURL.absoluteString.hasSuffix("generated.swift") &&
                        !isDirectory,
                        !fileURL.path.hasPrefix(podPath) &&
                        !fileURL.path.hasPrefix(vendorPath) {
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

    guard let stringsFileURL = stringsFileURL else {
        fatalError()
    }

    r2SwiftGen.generateCodeTable(stringsFileURL: stringsFileURL)
    
    var failedToReplaceFiles = [String]()

    for file in swiftFiles {
        
        do {
            try r2SwiftGen.replaceFile(inputFile: file)
        } catch let error {
            print(error)
            
            failedToReplaceFiles.append(file.path)
        }
       
        print("--------------------replaced file \(file.absoluteString)-----------------------")
    }
    
    print("---------------------------result-------------------------")
    
    for failedFile in failedToReplaceFiles {
        print("failed to replace for some reason: \(failedFile)")
    }
}

main.run()

