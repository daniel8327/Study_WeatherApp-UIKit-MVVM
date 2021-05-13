//
//  LocationViewModel.swift
//  WeatherMVVM
//
//  Created by moonkyoochoi on 2021/05/12.
//

import Foundation

import RxSwift
import RxCocoa

class LocationViewModel {
    
    internal private(set) var subject: BehaviorRelay<[SectionOfLocation]> = BehaviorRelay(value: [])

    func fetchLocationList() {
        
        // 조회
        let result = CoreDataHelper.fetch()
        
        var items: [LocationVO] = []
        
        _ = result.map {
            items.append(
                LocationVO(
                    currentArea: $0.value(forKey: "currentArea") as! Bool,
                    city: $0.value(forKey: "city") as! String,
                    code: $0.value(forKey: "code") as! String,
                    longitude: $0.value(forKey: "longitude") as! String,
                    latitude: $0.value(forKey: "latitude") as! String,
                    recent_temp: $0.value(forKey: "recent_temp") as? Int,
                    timezone: $0.value(forKey: "timezone") as! Int64
                )
            )
        }
        subject.accept([SectionOfLocation(items: items)])
    }
}
