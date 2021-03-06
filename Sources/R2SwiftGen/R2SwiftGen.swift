//
//  R2SwiftGen.swift
//  R2SwiftGen
//
//  Created by 戸高 新也 on 2022/06/26.
//

import Foundation

extension String.SubSequence {
    func uppercasedFirst() -> String.SubSequence {
    guard let first = self.first else {
      return self
    }
    return first.uppercased() + self.dropFirst()
  }
    
    func lowercasedFirst() -> String.SubSequence {
        guard let first = self.first else {
            return self
        }
        return first.lowercased() + self.dropFirst()
    }
}

extension String {
    func lowerFirstWord() -> String {
      guard !self.isEmpty else { return "" }
      let characterSet = CharacterSet.uppercaseLetters
      let scalars = self.unicodeScalars
      let start = scalars.startIndex
      var idx = start
      while idx < scalars.endIndex, let scalar = UnicodeScalar(scalars[idx].value), characterSet.contains(scalar) {
        idx = scalars.index(after: idx)
      }
      if idx > scalars.index(after: start) && idx < scalars.endIndex,
        let scalar = UnicodeScalar(scalars[idx].value),
        CharacterSet.lowercaseLetters.contains(scalar) {
        idx = scalars.index(before: idx)
      }
      let transformed = String(scalars[start..<idx]).lowercased() + String(scalars[idx..<scalars.endIndex])
      return transformed
    }
}
enum R2SwiftGenError: Error {
    case failedToGencode
}

class R2SwiftGen {
    let rSwiftPrefix: String
    let swiftGenPrefix: String
    var rCode2GenCodeDict = [String: String]()
    
    init(rswiftPrefix: String, swiftGenPrefix: String) {
        self.rSwiftPrefix = rswiftPrefix
        self.swiftGenPrefix = swiftGenPrefix
    }
    
    private func replaceRCode2SwiftGen(filePath: String, fileString: String) throws -> String {
        
        var newString = fileString
        
        let pattern = #"(\#(rSwiftPrefix)\..*?)\(([.|\s|\S]*?)\)"#

        let regex = try! NSRegularExpression(pattern: pattern, options: [])

        let results = regex.matches(in: fileString, options: [], range: NSRange(0..<fileString.count))
        
        var replacedOffset = 0

        for result in results {
            let start = newString.index(newString.startIndex, offsetBy: result.range(at: 1).location + replacedOffset)
            let end = newString.index(start, offsetBy: result.range(at: 1).length)
            
            let matchedRString = newString[start..<end]
            
            let Rcode = String(matchedRString.dropFirst((rSwiftPrefix + ".").count))
            
            let paramsElementStart = newString.index(newString.startIndex, offsetBy: result.range(at: 2).location + replacedOffset)
            let paramsElementEnd = newString.index(paramsElementStart, offsetBy: result.range(at: 2).length)
            
            let paramsString = newString[paramsElementStart..<paramsElementEnd]
            
            let replaceBraces = paramsString == ""
            
            let replaceBracesCount = replaceBraces ? 2 : 0
            
            guard let genCode = rCode2GenCodeDict[Rcode] else {
                print("failed to find swift gen code from: \(Rcode), filePath: \(filePath)")
                throw R2SwiftGenError.failedToGencode
            }
            
            let replacingString = swiftGenPrefix + "." + genCode
            
            let replaceStartIndex = start
            let replaceEndIndex = newString.index(replaceStartIndex, offsetBy: matchedRString.count + replaceBracesCount)
            
            newString = newString.replacingCharacters(in: replaceStartIndex..<replaceEndIndex, with: replacingString)
            
            replacedOffset += replacingString.count - matchedRString.count - replaceBracesCount
        }
        
        return newString
    }
    
    func replaceFile(inputFile: URL) throws  {
        guard let fileString = try? String(contentsOf: inputFile, encoding: .utf8) else {
            fatalError("cannot get string of \(inputFile.absoluteString)")
        }
        
        let newString = try replaceRCode2SwiftGen(filePath: inputFile.path, fileString: fileString)
        
        do {
            try newString.write(toFile: inputFile.path, atomically: true, encoding: .utf8)
            
            print("success write to swift file!!!! \(inputFile.path)")
        } catch let error {
            fatalError("failed to write file to \(inputFile.path)")
        }
    }
    
    func keyToRCode (key: String) -> String {
        var new = ""
        
        let _key = key.trimmingCharacters(in: .whitespacesAndNewlines)
        
        var separatedByDot = _key.split(separator: ".")
        
        guard separatedByDot.count > 1 else {
            return _key
        }
        
        let firstElement = separatedByDot.removeFirst()
        
        new += firstElement.lowercasedFirst()
        
        for element in separatedByDot {
            new += element.uppercasedFirst()
        }
        
        return new
    }
    
    func separateByUnderBar(element: String.SubSequence) -> String {
        var new = ""
        
        var separatedByDot = element.split(separator: "_")
        
        guard separatedByDot.count > 1 else {
            return String(element)
        }
        
        let firstElement = separatedByDot.removeFirst()
        
        new += firstElement.lowercasedFirst()
        
        for element in separatedByDot {
            new += element.uppercasedFirst()
        }
        
        return new
    }

    func keyToSwiftGenCode(key: String) -> String {
        var new = ""
        
        var separatedByDot = key.split(separator: ".")
        
        guard separatedByDot.count > 1 else {
            return key.first!.lowercased() + key.dropFirst()
        }
        
        let lastElement = separateByUnderBar(element: separatedByDot.removeLast())
        
        for element in separatedByDot {
            new += element.uppercasedFirst() + "."
        }
        
        new += lastElement.lowerFirstWord()
        
        return new
    }
    
    func generateCodeTable(stringsFileURL: URL) {
        guard let stringDict = NSDictionary(contentsOf: stringsFileURL) as? [String: String] else {
            fatalError()
        }
        let keys = [String](stringDict.keys)
        
        for key in keys {
            let RCode = keyToRCode(key: key)
            let swiftGenCode = keyToSwiftGenCode(key: key)
            
            rCode2GenCodeDict[RCode] = swiftGenCode
        }
    }
}

