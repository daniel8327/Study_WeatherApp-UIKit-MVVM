//
//  LocationStorageType.swift
//  WeatherMVVM
//
//  Created by moonkyoochoi on 2021/05/12.
//

import Foundation

import RxSwift

protocol LocationStorageType {
    
    func locationList() -> Observable<[LocationVO]>
}
