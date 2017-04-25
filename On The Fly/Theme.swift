//
//  Theme.swift
//  On The Fly
//
//  Created by Scott Higgins on 4/25/17.
//  Copyright © 2017 ScottieH. All rights reserved.
//

import UIKit

enum Theme: Int {
    //1
    case `default`, dark, graphical
    
    //2
    private enum Keys {
        static let selectedTheme = "SelectedTheme"
    }
    
    //3
    static var current: Theme {
        let storedTheme = UserDefaults.standard.integer(forKey: Keys.selectedTheme)
        return Theme(rawValue: storedTheme) ?? .default
    }
}
