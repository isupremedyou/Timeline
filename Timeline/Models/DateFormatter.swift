//
//  DateFormatter.swift
//  Timeline
//
//  Created by Travis Chapman on 11/8/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

import Foundation

extension Date {
    
    var asString: String {
        
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        
        return formatter.string(from: self)
    }
}
