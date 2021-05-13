//
//  LocationCell.swift
//  Weather
//
//  Created by 장태현 on 2021/04/20.
//

import UIKit

import Alamofire
import RxCocoa
import RxSwift
import SkeletonView

class LocationCell: UITableViewCell {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var locationName: UILabel!
    @IBOutlet weak var temperature: UILabel!
    
    private let cellDisposeBag = DisposeBag()
    
    var disposeBag = DisposeBag()
    
    let item = PublishSubject<LocationVO>()
    
    lazy var itemObserver: AnyObserver<LocationVO> = {
        return item.asObserver()
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        print("awakeFromNib")
        
        self.contentView.isSkeletonable = true
        
        containerView.isSkeletonable = true
        time.isSkeletonable = true
        locationName.isSkeletonable = true
        temperature.isSkeletonable = true
        
        containerView.skeletonCornerRadius = 8
        time.skeletonCornerRadius = 8
        locationName.skeletonCornerRadius = 8
        temperature.skeletonCornerRadius = 8
        
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setRx()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setRx()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        if selected {
            print("setSelected \(selected)")
        }
    }
    
    func setRx() {
        item
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] data in
                
                self?.locationName.text = data.city
                
                if let temp = data.recent_temp {
                    self?.temperature.text = "\(temp)\(fahrenheitOrCelsius.emoji)"
                } else {
                    self?.temperature.text = "--\(fahrenheitOrCelsius.emoji)"
                }
                
                let df = DateFormatter()
                df.calendar = Calendar(identifier: .iso8601)
                df.timeZone = TimeZone(secondsFromGMT: Int(data.timezone))
                df.locale = Locale(identifier: UICommon.getLanguageCountryCode())
                df.dateFormat = "a hh:mm"
                
                self?.time.text = df.string(from: Date())
                

                let param: [String: Any] = ["lat": data.latitude,
                                            "lon": data.longitude]

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
                        self?.temperature.fadeTransition(0.8)
                        self?.temperature.text = "\(temp)\(fahrenheitOrCelsius.emoji)"

                        CoreDataHelper.editByCode(cityCode: json["id"].stringValue, temperature: temp)
                    }
            })
            .disposed(by: cellDisposeBag)
    }
}
