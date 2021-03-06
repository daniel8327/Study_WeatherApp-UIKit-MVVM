//
//  ViewController.swift
//  Weather
//
//  Created by 장태현 on 2021/04/17.
//

import CoreLocation
import UIKit

import Alamofire
import SwiftyJSON
import RxSwift
import RxCocoa

typealias ModalClosedAlias = (Int)-> Void

class LocationsVC: UIViewController {
    
    lazy var locationManager: CLLocationManager = {
    
        let locationManager = CLLocationManager()
        locationManager.delegate = self // CLLocationManagerDelegate
        locationManager.requestWhenInUseAuthorization()// 포그라운드에서 권한 요청
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
                
        return locationManager
    }()
    
    var currentLocation: CLLocation?
    
    var viewModel: LocationViewModel
    
    private var disposeBag = DisposeBag()
    
    lazy var tableView: UITableView = {
        
        let tbv = UITableView()
        
        view.addSubview(tbv)
        
        tbv.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            tbv.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tbv.topAnchor.constraint(equalTo: view.topAnchor),
            tbv.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tbv.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tbv.register(UINib(nibName: LocationCell.reusableIdentifier, bundle: nil), forCellReuseIdentifier: LocationCell.reusableIdentifier)
        tbv.separatorStyle = .none
        
        // xib 호출 방법1
        if let loadedNib = Bundle.main.loadNibNamed("LocationFooter", owner: self, options: nil) {
            if let view = loadedNib[1] as? UIView {
                tbv.tableFooterView = view
                
                NotificationCenter
                    .default
                    .addObserver(
                        self,
                        selector: #selector(addLocation),
                        name: .addLocation,
                        object: nil)
                
                NotificationCenter
                    .default
                    .addObserver(
                        self,
                        selector: #selector(changeNotation),
                        name: .changeNotation,
                        object: nil)
            }
        }
        
        // xib 호출 방법2
        //if let aa = UINib(nibName: "LocationFooter", bundle: nil).instantiate(withOwner: self, options: nil).first as? UIView //xib의 첫번째
        /*if let aa = UINib(nibName: "LocationFooter", bundle: nil).instantiate(withOwner: self, options: nil)[1] as? UIView { // xib의 두번째
            tbv.tableFooterView = aa
            
        }*/
        
        return tbv
    }()
    
    var modalClosedAlias: ModalClosedAlias?
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private let dateFormatter: DateFormatter = {
       
        let df = DateFormatter()
        df.calendar = Calendar(identifier: .iso8601)
        df.timeZone = TimeZone.current
        //df.locale = Locale.current
        //df.locale = Locale(identifier: "ko_KR")
        df.locale = Locale(identifier: UICommon.getLanguageCountryCode())

        df.dateFormat = "hh:mm a"
        return df
    }()
    
    init(viewModel: LocationViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        //viewModel.items
            
        
        setRx()
        
        view.backgroundColor = .systemBackground
        
        
        // 아이폰 설정에서의 위치 서비스가 켜진 상태라면
        if CLLocationManager.locationServicesEnabled() {
            print("위치 서비스 On 상태")
            locationManager.startUpdatingLocation() //위치 정보 받아오기 시작 CLLocationManagerDelegate
        } else {
            print("위치 서비스 Off 상태")
            removeCurrentData()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    // MARK: Selectors
    
    /// 섭씨/화씨 전환
    @objc func changeNotation() {
        
        fahrenheitOrCelsius = (fahrenheitOrCelsius == FahrenheitOrCelsius.Celsius) ? .Fahrenheit : .Celsius
        
        // footer 바꾸기
        let footer = self.tableView.tableFooterView as! LocationFooter
        
        let attributeString = NSMutableAttributedString(string: footer.notation.text ?? "")
        
        let str = footer.notation.text!
        
        let r1 = str.range(of: fahrenheitOrCelsius.emoji)!
        // String range to NSRange:
        let n1 = NSRange(r1, in: str)
        
        attributeString.addAttribute(NSAttributedString.Key.foregroundColor, value: UIColor.red, range: n1)

        footer.notation.attributedText = attributeString
        
        // 전체 리스트 바꾸기
        //tableView.reloadData()
        UIView.transition(with: self.tableView, duration: 1.0, options: .transitionCrossDissolve, animations: {self.tableView.reloadData()}, completion: nil)
    }
    
    /// 도시 추가
    @objc func addLocation() {
        
        // 도시 검색
        let vc = LocationAdditionVC()
        vc.saveDelegate = self // SaveLocationDelegate
        self.present(vc, animated: true)
    }
    
    // MARK: User Functions
    
    /// 도시 추가 확인
    func checkLocations() {
        
//        // 설정된 도시 없으면 물어보기
//        if viewModel.items.emp {
//            let alert = UIAlertController(title: "지역 선택", message: "날씨 정보를 받아볼 지역을 검색하세요.", preferredStyle: .alert)
//            let confirmAction = UIAlertAction(title: "확인", style: .default) { _ in
//                self.addLocation()
//            }
//            //let cancelAction = UIAlertAction(title: "취소", style: .cancel)
//
//            alert.addAction(confirmAction)
//            //alert.addAction(cancelAction)
//
//            self.present(alert, animated: true)
//        }
    }
    
    /// 현위치 저장 내역 삭제
    func removeCurrentData() {
        // 기존에 현위치 저장된 것이 있다면 삭제
        if let currentArea = CoreDataHelper.fetchByCurrent() {
            CoreDataHelper.delete(object: currentArea)
            
            _ = viewModel.storage.locationList() // 재조회
        }
    }
    
    private func setRx() {
        
        ///TODO: EditingStyle, editingStyleForRowAt, canEditRowAt, willDisplay
        
        self.tableView.rowHeight = 100
        
        
        tableView
            .rx.itemSelected
            .subscribe(onNext: { [unowned self] indexPath in
                print("\(indexPath.row) selected")
                
                self.modalClosedAlias?(indexPath.row)
                self.dismiss(animated: true)
            })
            .disposed(by: disposeBag)

        viewModel.items
            .debug("list")
            .bind(
                to: tableView
                    .rx
                    .items(
                        cellIdentifier: LocationCell.reusableIdentifier,
                        cellType: LocationCell.self
                    )
            )
            { _, record, cell in
                
                cell.separatorInset = UIEdgeInsets.zero // https://zeddios.tistory.com/235
                
                print("111: \(record.city) \(record.currentArea)")
                
                cell.locationName.text = record.city
                
                if let temp = record.recent_temp {
                    cell.temperature.text = "\(temp)\(fahrenheitOrCelsius.emoji)"
                } else {
                    cell.temperature.text = "--\(fahrenheitOrCelsius.emoji)"
                }
                
                let df = DateFormatter()
                df.calendar = Calendar(identifier: .iso8601)
                df.timeZone = TimeZone(secondsFromGMT: Int(record.timezone))
                df.locale = Locale(identifier: UICommon.getLanguageCountryCode())
                df.dateFormat = "a hh:mm"
                
                cell.time.text = df.string(from: Date())
                
                let param: [String: Any] = ["lat": record.latitude,
                                            "lon": record.longitude]
                
                API.init(session: Session.default)
                    .request(
                        API.WEATHER,
                        method: .get,
                        parameters: param,
                        encoding: URLEncoding.default,
                        headers: nil,
                        interceptor: nil,
                        requestModifier: nil
                    ) { json in
                        let temp = json["main"]["temp"].intValue
                        cell.temperature.fadeTransition(0.8)
                        cell.temperature.text = "\(temp)\(fahrenheitOrCelsius.emoji)"
                        
                        CoreDataHelper.editByCode(cityCode: json["id"].stringValue, temperature: temp)
                    }
            }.disposed(by: disposeBag)
    }
}

extension LocationsVC: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        switch status {
        
        case .authorizedAlways,
             .authorizedWhenInUse:
            
            // 위치 정확도 Best, 배터리 많이 잡아먹음
            manager.desiredAccuracy = kCLLocationAccuracyBest
            
            print(locationManager)
            guard let currentLocation = locationManager.location else { return }
            
            let prevLocation = CoreDataHelper.fetchByCurrent()
            
            if let loc = prevLocation {
                if ((loc.value(forKey: "longitude") as! String).nearBy() == currentLocation.coordinate.longitude.description.nearBy()) &&
                    ((loc.value(forKey: "latitude") as! String).nearBy() == currentLocation.coordinate.latitude.description.nearBy()) {
                    // do nothing
                    
                    print("위치 같아서 안해도 됨")
                    return
                } else {
                    // 지난 현재위치 삭제
                    CoreDataHelper.delete(object: loc)
                }
            }
            
            let param: [String: Any] =
                ["lat": currentLocation.coordinate.latitude,
                 "lon": currentLocation.coordinate.longitude]
    
            API(session: Session.default)
                .request(API.WEATHER,
                         method: .get,
                         parameters: param,
                         encoding: URLEncoding.default,
                         headers: nil,
                         interceptor: nil,
                         requestModifier: nil) { [weak self] json in
                    
                    let locationVO = LocationVO(
                        currentArea: true,
                        city: json["name"].stringValue,
                        code: json["id"].stringValue,
                        longitude: String(currentLocation.coordinate.longitude),
                        latitude: String(currentLocation.coordinate.latitude),
                        recent_temp: json["main"]["temp"].intValue,
                        timezone: json["timezone"].int64Value
                    )
                    
                    // 기존에 현위치 저장된 것이 있다면 업데이트 없으면 인서트
                    CoreDataHelper.save(
                        object: prevLocation,
                        location: locationVO
                    )
                    
                    _ = self?.viewModel.storage.locationList() // 재조회
                }
        default:
            removeCurrentData()
        }
    }
}

extension LocationsVC: SaveLocationDelegate {
    func requestSave(vo: LocationVO) {
        
        CoreDataHelper.save(object: nil, location: vo)
        _ = viewModel.storage.locationList() // 재조회
    }
}
extension LocationsVC {
    static func dataSource() -> RxTableViewSectionedAnimatedDataSource<NumberSection> {
        return RxTableViewSectionedAnimatedDataSource(
            animationConfiguration: AnimationConfiguration(
                insertAnimation: .top, reloadAnimation: .fade, deleteAnimation: .left
            ),
            configureCell: { (dataSource, table, idxPath, item) in
                let cell = table.dequeueReusableCell(withIdentifier: "Cell", for: idxPath)
                cell.textLabel?.text = "\(item)" return cell
            }, titleForHeaderInSection: { (ds, section) -> String? in
                return ds[section].header
            }, canEditRowAtIndexPath: { _, _ in return true
                
            }, canMoveRowAtIndexPath: { _, _ in return true
                
            }
        )
    }
}
