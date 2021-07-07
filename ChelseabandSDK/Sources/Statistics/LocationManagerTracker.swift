//
//  LocationManagerTracker.swift
//  ChelseabandSDK
//
//  Created by Sergey Pohrebnuak on 17.03.2021.
//

import Foundation
import MapKit
import CoreLocation
import RxSwift

public protocol LocationManager: AnyObject {
    var locationStatusSubject: BehaviorSubject<CLAuthorizationStatus> { get }
    func makeRequestForUseLocationPermission()
}

protocol LocationTracker: LocationManager {
    var location: PublishSubject<CLLocationCoordinate2D> {get set}
    func startObserving()
    func stopObserving()
}

final class LocationManagerTracker: NSObject, LocationTracker {
    // MARK: Constants
    public let locationStatusSubject: BehaviorSubject<CLAuthorizationStatus>
    private let locationManager: CLLocationManager
    private let disposeBag: DisposeBag
    
    // MARK: Variables
    var location = PublishSubject<CLLocationCoordinate2D>()
    
    override init() {
        locationManager = CLLocationManager()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        disposeBag = DisposeBag()
        
        if #available(iOS 14.0, *) {
            locationStatusSubject = .init(value: locationManager.authorizationStatus)
        } else {
            locationStatusSubject = .init(value: CLLocationManager.authorizationStatus())
        }
        
        super.init()
        
        locationManager.delegate = self
    }
    
    // MARK: Public Functions
    public func makeRequestForUseLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    // MARK: Internal Functions
    func startObserving() {
        locationManager.requestAlwaysAuthorization()
        startObservLocation()
    }
    
    func stopObserving() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: Private Functions
    private func startObservLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }
}

// MARK: - Extensions
extension LocationManagerTracker: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        location.onNext(locValue)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            locationStatusSubject.onNext(manager.authorizationStatus)
        } else {
            locationStatusSubject.onNext(CLLocationManager.authorizationStatus())
        }
        startObservLocation()
    }
}
