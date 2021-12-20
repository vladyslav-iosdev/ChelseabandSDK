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
    // NOTE: for stop observing just pass nil
    func addPointForObserve(pointInfo: (lat: Double, lng: Double, radius: Double)?)
    func requestStateForRegions()
}

final class LocationManagerTracker: NSObject, LocationTracker {
    // MARK: Constants
    public let locationStatusSubject: BehaviorSubject<CLAuthorizationStatus>
    private let locationManager: CLLocationManager
    private let isInAreaPublishSubject: PublishSubject<Bool> = .init()
    
    // MARK: Variables
    var isInAreaObservable: Observable<Bool> { isInAreaPublishSubject }
    private var pointInfoForObserve: (lat: Double, lng: Double, radius: Double)? = nil
    
    override init() {
        locationManager = CLLocationManager()
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.activityType = .otherNavigation
        
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
    func addPointForObserve(pointInfo: (lat: Double, lng: Double, radius: Double)?) {
        pointInfoForObserve = pointInfo
        startObserving()
    }
    
    func requestStateForRegions() {
        locationManager.monitoredRegions.forEach { locationManager.requestState(for: $0) }
    }
    
    // MARK: Private Functions
    private func startObserving() {
        locationManager.requestAlwaysAuthorization()
        startObserveLocation()
    }
    
    private func stopObserving() {
        locationManager.stopUpdatingLocation()
    }
    
    private func startObserveLocation() {
        guard CLLocationManager.locationServicesEnabled(),
              CLLocationManager.authorizationStatus() != .denied,
              CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
        else { return }
        
        locationManager.monitoredRegions.forEach { locationManager.stopMonitoring(for: $0) }
        
        guard let pointInfo = pointInfoForObserve else { return }
        
        let regionCenter = CLLocationCoordinate2D(latitude: pointInfo.lat,
                                                  longitude: pointInfo.lng)
        let region = CLCircularRegion(center: regionCenter,
                                      radius: pointInfo.radius,
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
        startObserveLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationStatusSubject.onNext(status)
        startObserveLocation()
    }
}
