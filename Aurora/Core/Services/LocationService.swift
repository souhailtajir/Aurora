//
//  LocationService.swift
//  Aurora
//

import CoreLocation
import Foundation
import MapKit

@Observable
@MainActor
final class LocationService: NSObject, CLLocationManagerDelegate {
  private let locationManager = CLLocationManager()
  private var locationContinuation: CheckedContinuation<CLLocation?, Never>?

  var authorizationStatus: CLAuthorizationStatus = .notDetermined
  var isLoading = false
  var lastError: String?

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
    authorizationStatus = locationManager.authorizationStatus
  }

  func requestPermission() {
    #if os(iOS)
    locationManager.requestWhenInUseAuthorization()
    #elseif os(macOS)
    locationManager.requestAlwaysAuthorization()
    #endif
  }

  func getCurrentLocation() async -> CLLocation? {
    isLoading = true
    lastError = nil

    // Check authorization
    if authorizationStatus == .notDetermined {
      requestPermission()
      // Wait briefly for authorization
      try? await AsyncTask.sleep(nanoseconds: 500_000_000)
    }

    #if os(iOS)
    guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    else {
      isLoading = false
      lastError = "Location access not authorized"
      return nil
    }
    #elseif os(macOS)
    guard authorizationStatus == .authorizedAlways || authorizationStatus == .authorized
    else {
      isLoading = false
      lastError = "Location access not authorized"
      return nil
    }
    #endif

    return await withCheckedContinuation { continuation in
      locationContinuation = continuation
      locationManager.requestLocation()
    }
  }

  func reverseGeocode(_ location: CLLocation) async -> String? {
    let geocoder = CLGeocoder()
    do {
      let placemarks = try await geocoder.reverseGeocodeLocation(location)
      if let placemark = placemarks.first {
        var components: [String] = []
        if let locality = placemark.locality {
          components.append(locality)
        }
        if let administrativeArea = placemark.administrativeArea {
          components.append(administrativeArea)
        }
        if let country = placemark.country, components.isEmpty {
          components.append(country)
        }
        return components.isEmpty ? nil : components.joined(separator: ", ")
      }
    } catch {
      lastError = error.localizedDescription
    }
    return nil
  }

  // MARK: - CLLocationManagerDelegate

  nonisolated func locationManager(
    _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
  ) {
    AsyncTask { @MainActor in
      self.isLoading = false
      self.locationContinuation?.resume(returning: locations.first)
      self.locationContinuation = nil
    }
  }

  nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
    AsyncTask { @MainActor in
      self.isLoading = false
      self.lastError = error.localizedDescription
      self.locationContinuation?.resume(returning: nil)
      self.locationContinuation = nil
    }
  }

  nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
    let status = manager.authorizationStatus
    AsyncTask { @MainActor in
      self.authorizationStatus = status
    }
  }
}
