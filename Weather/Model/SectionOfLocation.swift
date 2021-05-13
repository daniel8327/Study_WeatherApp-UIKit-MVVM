//
//  SectionOfLocation.swift
//  WeatherMVVM
//
//  Created by moonkyoochoi on 2021/05/13.
//

import Foundation
import RxDataSources

struct SectionOfLocation {
    var items: [LocationVO]
}

extension SectionOfLocation: SectionModelType {
    typealias Item = LocationVO
    
    init(original: SectionOfLocation, items: [Item]) {
        self = original
        self.items = items
    }
}
