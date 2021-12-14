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
    var isInAreaObservable: Observable<Bool> { get }
    func startObserving()
    func stopObserving()
}

final class LocationManagerTracker: NSObject, LocationTracker {
    // MARK: Constants
    public let locationStatusSubject: BehaviorSubject<CLAuthorizationStatus>
    private let locationManager: CLLocationManager
    private let disposeBag: DisposeBag
    private let isInAreaPublishSubject: PublishSubject<Bool> = .init()
    
    // MARK: Variables
    var isInAreaObservable: Observable<Bool> { isInAreaPublishSubject }
    
    override init() {
        locationManager = CLLocationManager()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .otherNavigation
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
        guard CLLocationManager.locationServicesEnabled(),
              CLLocationManager.authorizationStatus() != .denied,
              CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
        else { return }
        
        let regionCenter = CLLocationCoordinate2D(latitude: 33.75741395979292,
                                                  longitude: -84.39633513106129)
        let region = CLCircularRegion(center: regionCenter,
                                      radius: 300,
                                      identifier: "State Farm Arena")
        region.notifyOnExit = true
        region.notifyOnEntry = true
        locationManager.startMonitoring(for: region)
    }
}

// MARK: - Extensions
extension LocationManagerTracker: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard let location: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        
        switch state {
        case .inside:
            isInAreaPublishSubject.onNext(true)
        case .outside:
            isInAreaPublishSubject.onNext(false)
        case .unknown:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if #available(iOS 14.0, *) {
            locationStatusSubject.onNext(manager.authorizationStatus)
        }
        startObservLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatusSubject.onNext(status)
        startObservLocation()
    }
}
