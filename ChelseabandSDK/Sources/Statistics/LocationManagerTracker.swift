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

protocol LocationTracker {
    var location: PublishSubject<CLLocationCoordinate2D> {get set}
    func startObserving()
}

final class LocationManagerTracker: NSObject, LocationTracker {
    // MARK: Constants
    private let locationManager = CLLocationManager()
    private let disposeBag = DisposeBag()
    
    // MARK: Variables
    var location = PublishSubject<CLLocationCoordinate2D>()
    
    // MARK: Public Functions
    func startObserving() {
        locationManager.requestAlwaysAuthorization()
        startObservLocation()
    }
    
    // MARK: Private Functions
    private func startObservLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.allowsBackgroundLocationUpdates = true
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        startObservLocation()
    }
}
