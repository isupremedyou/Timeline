//
//  SearchableRecord.swift
//  Timeline
//
//  Created by Travis Chapman on 11/8/18.
//  Copyright © 2018 Travis Chapman. All rights reserved.
//

import Foundation

protocol SearchableRecord {
    
    func matches(searchTerm: String) -> Bool
}
