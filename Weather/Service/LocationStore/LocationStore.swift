//
//  LocationStore.swift
//  WeatherMVVM
//
//  Created by moonkyoochoi on 2021/05/12.
//

import Foundation

import RxSwift
import RxCocoa

class LocationStore: LocationStorageType {
    
    var disposeBag = DisposeBag()
    
    private lazy var store = BehaviorSubject<[LocationVO]>(value: [])
    
    func locationList() -> Observable<[LocationVO]> {
        
        _ = Observable.create { emitter -> Disposable in
            self.fetch { result in
                switch result {
                case let .success(items):
                    emitter.onNext(items)
                    emitter.onCompleted()
                case let .failure(error):
                    emitter.onError(error)
                }
            }
            return Disposables.create()
        }.subscribe(onNext: store.onNext)
        
        return store.asObserver()
    }
    
    func fetch(completeHandler: @escaping (Result<[LocationVO], Error>) -> Void) {
        
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
        
        completeHandler(.success(items))
    }
    
}
