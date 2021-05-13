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
    
    let storage: LocationStorageType
    
    var items: Observable<[LocationVO]> {
        return storage.locationList()
    }
    
    init(storage: LocationStorageType) {
        self.storage = storage
    }
}
