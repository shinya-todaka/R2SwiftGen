import Foundation
import Commander

let currentDir = FileManager.default.currentDirectoryPath

let main = command(Argument<String>("strings"),
                   Option("rPerfix", default: "R.string.localizable"),
                   Option("swiftGenPrefix", default: "L10n")) { strings, rprefix, swiftGenPrefix in
    let currentDirURL = URL(fileURLWithPath: currentDir)
    var swiftFiles = [URL]()
    var stringsFileURL: URL? = URL(fileURLWithPath: (currentDir as NSString).appendingPathComponent(strings))
    
    print("currentDir: \(currentDir), stringsFileURL: \(stringsFileURL), rPrefix: \(rprefix), swiftGenPrefix: \(swiftGenPrefix)")
    
    let r2SwiftGen = R2SwiftGen(rswiftPrefix: rprefix, swiftGenPrefix: swiftGenPrefix)

    if let enumerator = FileManager.default.enumerator(at: currentDirURL, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
        for case let fileURL as URL in enumerator {
            do {
                let pathExtension = fileURL.pathExtension

                if pathExtension == "swift" {
                    if !fileURL.absoluteString.hasSuffix("main.swift") {
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

