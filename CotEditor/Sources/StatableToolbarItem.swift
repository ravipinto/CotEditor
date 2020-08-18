//
//  StatableToolbarItem.swift
//
//  CotEditor
//  https://coteditor.com
//
//  Created by 1024jp on 2016-05-26.
//
//  ---------------------------------------------------------------------------
//
//  © 2016-2020 1024jp
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  https://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import AppKit

extension StatableItem where Self: NSToolbarItem {
    
    var state: NSControl.StateValue {
        
        get {
            return (self.image?.name()?.hasSuffix("On") == true) ? .on : .off
        }
        
        set {
            guard newValue != self.state else { return }
            
            let suffix = (newValue == .on) ? "On" : "Off"
            
            guard
                let base = self.image?.name()?.components(separatedBy: "_").first,
                let image = NSImage(named: base + "_" + suffix)
            else { return assertionFailure("StatableToolbarItem must habe an image that has name with \"_On\" and \"_Off\" suffixes.") }
            
            self.image = image
        }
    }
}


final class StatableToolbarItem: NSToolbarItem, StatableItem { }
