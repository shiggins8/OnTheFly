//
//  Theme.swift
//  On The Fly
//
//  Created by Scott Higgins on 4/25/17.
//  Copyright © 2017 ScottieH. All rights reserved.
//

import UIKit

enum Theme: Int {
    case `default`, dark, crimsonSky
    
    private enum Keys {
        static let selectedTheme = "SelectedTheme"
    }
    
    static var current: Theme {
        let storedTheme = UserDefaults.standard.integer(forKey: Keys.selectedTheme)
        return Theme(rawValue: storedTheme) ?? .default
    }
    
    var mainColor: UIColor {
        switch self {
        case .default:
            return UIColor(red:0.00, green:0.48, blue:1.00, alpha:1.0)
        case .dark:
            return UIColor(red: 255.0/255.0, green: 115.0/255.0, blue: 50.0/255.0, alpha: 1.0)
        case .crimsonSky:
            return UIColor(red:0.93, green:0.38, blue:0.22, alpha:1.0)
        }
    }
    
    var barStyle: UIBarStyle {
        switch self {
        case .default, .crimsonSky:
            return .default
        case .dark:
            return .black
        }
    }
    
    
    func apply() {
        UserDefaults.standard.set(rawValue, forKey: Keys.selectedTheme)
        UserDefaults.standard.synchronize()
        
        UIApplication.shared.delegate?.window??.tintColor = mainColor
        
        UINavigationBar.appearance().barStyle = barStyle
    }
    
    /* From the class with the settings view, call: 
     
     if let selectedTheme = Theme(rawValue: themeSelector.selectedSegmentIndex) {
     selectedTheme.apply()
     }
     
     And ensure that this is also called: 
     
     themeSelector.selectedSegmentIndex = Theme.current.rawValue ( in a situation with a segment selector)
     
    */
}
