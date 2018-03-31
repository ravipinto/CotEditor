/*
 
 BatchReplacement.swift
 
 CotEditor
 https://coteditor.com
 
 Created by 1024jp on 2017-02-19.
 
 ------------------------------------------------------------------------------
 
 © 2017-2018 1024jp
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 https://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 
 */

import Foundation

final class BatchReplacement: Codable {
    
    struct Replacement {
        
        var findString: String
        var replacementString: String
        var usesRegularExpression: Bool
        var ignoresCase: Bool
        var isEnabled = true
        var description: String?
        
        
        init(findString: String, replacementString: String, usesRegularExpression: Bool, ignoresCase: Bool, description: String? = nil, isEnabled: Bool = true) {
            
            self.findString = findString
            self.replacementString = replacementString
            self.ignoresCase = ignoresCase
            self.usesRegularExpression = usesRegularExpression
            self.description = description
            self.isEnabled = isEnabled
        }
        
        
        init() {
            
            self.findString = ""
            self.replacementString = ""
            self.ignoresCase = false
            self.usesRegularExpression = false
        }
    }
    
    
    struct Settings {
        
        var textualOptions: NSString.CompareOptions
        var regexOptions: NSRegularExpression.Options
        var unescapesReplacementString: Bool
        
        
        init(textualOptions: NSString.CompareOptions = [], regexOptions: NSRegularExpression.Options = [.anchorsMatchLines], unescapesReplacementString: Bool = true) {
            
            self.textualOptions = textualOptions
            self.regexOptions = regexOptions
            self.unescapesReplacementString = unescapesReplacementString
        }
    }
    
    
    
    var replacements: [Replacement]
    var settings: Settings
    
    
    init(replacements: [Replacement] = [], settings: Settings = Settings()) {
        
        self.replacements = replacements
        self.settings = settings
    }
    
}



// MARK: - Equatable

extension BatchReplacement.Replacement: Equatable {
    
    static func == (lhs: BatchReplacement.Replacement, rhs: BatchReplacement.Replacement) -> Bool {
        
        return lhs.findString == rhs.findString &&
            lhs.replacementString == rhs.replacementString &&
            lhs.usesRegularExpression == rhs.usesRegularExpression &&
            lhs.ignoresCase == rhs.ignoresCase &&
            lhs.description == rhs.description &&
            lhs.isEnabled == rhs.isEnabled
    }
    
}


extension BatchReplacement.Settings: Equatable {
    
    static func == (lhs: BatchReplacement.Settings, rhs: BatchReplacement.Settings) -> Bool {
        
        return lhs.textualOptions == rhs.textualOptions &&
            lhs.regexOptions == rhs.regexOptions &&
            lhs.unescapesReplacementString == rhs.unescapesReplacementString
    }
}



// MARK: - Replacement

extension BatchReplacement {
    
    struct Result {
        
        var string: String
        var selectedRanges: [NSRange]?
        var count = 0
        
        
        fileprivate init(string: String, selectedRanges: [NSRange]?) {
            
            self.string = string
            self.selectedRanges = selectedRanges
        }
    }
    
    
    
    // MARK: Public Methods
    
    /// Batch-find in given string.
    ///
    /// - Parameters:
    ///   - string: The string to find in.
    ///   - ranges: The ranges of selection in the text view.
    ///   - inSelection: Whether find only in selection.
    ///   - block: The block enumerates the matches.
    ///   - count: The number of replaces so far.
    ///   - stop: A reference to a Bool value. The block can set the value to true to stop further processing.
    /// - Returns: The found ranges. This method will return first all search finished.
    func find(string: String, ranges: [NSRange], inSelection: Bool, using block: (_ count: Int, _ stop: inout Bool) -> Void) -> [NSRange] {
        
        var result = [NSRange]()
        
        guard !string.isEmpty else { return result }
        
        for replacement in self.replacements {
            guard replacement.isEnabled else { continue }
            
            let textualOptions = self.settings.textualOptions.union(replacement.ignoresCase ? [.caseInsensitive] : [])
            let regexOptions = self.settings.regexOptions.union(replacement.ignoresCase ? [.caseInsensitive] : [])
            let settings = TextFind.Settings(usesRegularExpression: replacement.usesRegularExpression,
                                             isWrap: false,
                                             inSelection: inSelection,
                                             textualOptions: textualOptions,
                                             regexOptions: regexOptions,
                                             unescapesReplacementString: self.settings.unescapesReplacementString)
            
            // -> Invalid replacement sets will be just ignored.
            let textFind: TextFind
            do {
                textFind = try TextFind(for: string, findString: replacement.findString, settings: settings, selectedRanges: ranges)
            } catch {
                print(error.localizedDescription)
                continue
            }
            
            // process replacement
            var cancelled = false
            textFind.findAll { (ranges, stop) in
                block(result.count, &stop)
                cancelled = stop
                
                result.append(ranges.first!)
            }
            
            guard !cancelled else { return [] }
        }
        
        return result
    }
    
    
    /// Batch-replace matches in given string.
    ///
    /// - Parameters:
    ///   - string: The string to replace.
    ///   - ranges: The ranges of selection in the text view.
    ///   - inSelection: Whether replace only in selection.
    ///   - block: The block enumerates the matches.
    ///   - count: The number of replaces so far.
    ///   - stop: A reference to a Bool value. The block can set the value to true to stop further processing.
    /// - Returns: The result of the replacement. This method will return first all replacement finished.
    func replace(string: String, ranges: [NSRange], inSelection: Bool, using block: @escaping (_ count: Int, _ stop: inout Bool) -> Void) -> Result {
        
        var result = Result(string: string, selectedRanges: ranges)
        
        guard !string.isEmpty else { return result }
        
        for replacement in self.replacements {
            guard replacement.isEnabled else { continue }
            
            let textualOptions = self.settings.textualOptions.union(replacement.ignoresCase ? [.caseInsensitive] : [])
            let regexOptions = self.settings.regexOptions.union(replacement.ignoresCase ? [.caseInsensitive] : [])
            let settings = TextFind.Settings(usesRegularExpression: replacement.usesRegularExpression,
                                             isWrap: false,
                                             inSelection: inSelection,
                                             textualOptions: textualOptions,
                                             regexOptions: regexOptions,
                                             unescapesReplacementString: self.settings.unescapesReplacementString)
            let findRanges = result.selectedRanges ?? [result.string.nsRange]
            
            // -> Invalid replacement sets will be just ignored.
            let textFind: TextFind
            do {
                textFind = try TextFind(for: result.string, findString: replacement.findString, settings: settings, selectedRanges: findRanges)
            } catch {
                print(error.localizedDescription)
                continue
            }
            
            // process replacement
            var cancelled = false
            let (replacementItems, selectedRanges) = textFind.replaceAll(with: replacement.replacementString) { (flag, stop) in
                
                switch flag {
                case .findProgress, .foundCount:
                    break
                case .replacementProgress:
                    result.count += 1
                    block(result.count, &stop)
                    cancelled = stop
                }
            }
            
            // finish if cancelled
            guard !cancelled else { return Result(string: string, selectedRanges: ranges) }
            
            // update string
            for item in replacementItems.reversed() {
                result.string = (result.string as NSString).replacingCharacters(in: item.range, with: item.string)
            }
            
            // update selected ranges
            result.selectedRanges = selectedRanges
        }
        
        return result
    }
    
}



// MARK: - Validation

extension BatchReplacement.Replacement {
    
    /// check if replacement definition is valid
    ///
    /// - Throws: TextFindError
    func validate(regexOptions: NSRegularExpression.Options = []) throws {
        
        guard !self.findString.isEmpty else {
            throw TextFindError.emptyFindString
        }
        
        if self.usesRegularExpression {
            do {
                _ = try NSRegularExpression(pattern: self.findString, options: regexOptions)
            } catch {
                let failureReason = error.localizedDescription
                throw TextFindError.regularExpression(reason: failureReason)
            }
        }
    }
    
}


extension BatchReplacement {
    
    /// current errors in replacement definitions
    var errors: [TextFindError] {
        
        return self.replacements.compactMap {
            do {
                try $0.validate()
            } catch {
                return error as? TextFindError
            }
            return nil
        }
    }
    
}
