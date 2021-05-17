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
    
    let fahrenheitOrCelsiusRx: BehaviorRelay = BehaviorRelay(value: fahrenheitOrCelsius)
    
    internal private(set) var subject: BehaviorRelay<[SectionOfLocation]> = BehaviorRelay(value: [])
    
    lazy var items: [LocationVO] = {
       
        var vos = [LocationVO]()
        vos.removeAll()
        
        return vos
    }()
    
    init() {
        //fahrenheitOrCelsiusRx = Observable.of(fahrenheitOrCelsius)
        
//        fahrenheitOrCelsiusRx = Observable<FahrenheitOrCelsius>.create { observer -> Disposable in
//            observer.onNext(fahrenheitOrCelsius)
//            return Disposables.create()
//        }
        
        
    }

    func fetchLocationList() {
        
        // 조회
        let result = CoreDataHelper.fetch()
        
        items.removeAll()
        
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
