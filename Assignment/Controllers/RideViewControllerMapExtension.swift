//
//  RideViewControllerMapExtension.swift
//  Assignment
//
//  Created by Christi John on 11/07/18.
//  Copyright © 2018 Chris Inc. All rights reserved.
//

import Foundation
import GoogleMaps
import GooglePlaces

extension RideViewController {
    
    private struct Constants {
        static let mapInfoWindowNibName = "MapIconView"
        static let mapIconViewNibName = "MapInfoView"
    }
    
    /// This method is used to add Google map with Dubai location in holder view.
    ///
    internal func addMapView() {
        let camera = GMSCameraPosition.camera(withLatitude: 25.27,
                                              longitude: 55.309,
                                              zoom: 15.0)
        mapView = GMSMapView.map(withFrame: mapHolderView.bounds, camera: camera)
//        mapView.isMyLocationEnabled = true
//        mapView.delegate = self
        mapHolderView.addSubview(mapView)
    }

    /// This method is used to update user's current location on map
    /// It also updates Pickup location as current location
    ///
    internal func updateCurrentPlace() {
        placesClient.currentPlace(callback: {
            (placeLikelihoodList, error) -> Void in
            if let error = error {
                print("Pick Place error: \(error.localizedDescription)")
                return
            }
            
            if let placeLikelihoodList = placeLikelihoodList {
                let place = placeLikelihoodList.likelihoods.first?.place
                if let place = place {
                    self.origin = place.coordinate
                    self.pickupLocationField.text = place.name
                    
                    self.addMarkerAt(place: place, isSource: true)
                    self.adjustMapCamera()
                    
                }
            }
        })
    }
    
    /// This method is used to add a Marker on Map
    ///
    /// - Parameter place: GMSPlace
    /// - Parameter isSource: Bool - Indicating whether the place is pick/drop
    ///
    internal func addMarkerAt(place: GMSPlace, isSource: Bool) {

        let marker = GMSMarker()
        marker.position = CLLocationCoordinate2D(latitude: place.coordinate.latitude,
                                                 longitude: place.coordinate.longitude)
        marker.title = place.name
        marker.icon = (isSource) ? UIImage(named: "pickupMarker") : UIImage(named: "destinationMarker")
        marker.iconView = getMarkerIconView(name: place.name)
        marker.tracksViewChanges = true
        marker.map = mapView
        
        clearMarkers(isSource: isSource)
       
        if isSource == true {
            sourceMarker = marker
        } else {
            destinationMarker = marker
//            mapView.selectedMarker = marker  //To show info window programatically select marker
        }
    }
    
    /// Method retreives map marker icon view
    ///
    /// - Parameter name: Place name to be shown on marjer icon view
    ///
    private func getMarkerIconView(name: String?) -> UIView {
        let iconView = Bundle.main.loadNibNamed(
                        Constants.mapIconViewNibName, owner: self, options: nil)![0] as! MapIconView
        iconView.nameLabel.text = name ?? " "
        return iconView
    }
    
    /// This will adjust Map camera's zoomscale and location inorder to make existing markers visible
    ///
    internal func adjustMapCamera() {
        if let origin = origin,
            let destination = destination
        {
            var bounds = GMSCoordinateBounds(coordinate: origin, coordinate: destination)
            bounds = bounds.includingCoordinate(origin)
            bounds = bounds.includingCoordinate(destination)
//            mapView.animate(with:GMSCameraUpdate.fit(bounds, withPadding: 150.0))
            
            if let camera = mapView.camera(for: bounds, insets: UIEdgeInsetsMake(100, 0, 100, 0)) {
                 mapView.camera = camera
            }
           
        }
        else {
            let markerPoint = (origin != nil) ? origin : destination
            if let markerPoint = markerPoint {
                let camera = GMSCameraPosition.camera(withLatitude: markerPoint.latitude,
                                                      longitude:markerPoint.longitude,
                                                      zoom: 15.0)
                mapView.camera = camera
            }
        }
        
    }
    
    ///
    internal func showAutoCompletionView() {
        let autocompleteController = GMSAutocompleteViewController()
        autocompleteController.delegate = self
        
        present(autocompleteController, animated: true, completion: {
            if let initialText = self.activeTextField.text {
                let views = autocompleteController.view.subviews
                let subviewsOfSubview = views.first!.subviews
                let subOfNavTransitionView = subviewsOfSubview[1].subviews
                let subOfContentView = subOfNavTransitionView[2].subviews
                let searchBar = subOfContentView[0] as! UISearchBar
                searchBar.placeholder = initialText
                searchBar.delegate?.searchBar?(searchBar, textDidChange: initialText)
            }
        })
    }
    
    private func clearMarkers(isSource: Bool) {
        if isSource == true {
            sourceMarker?.map = nil
        } else {
            destinationMarker?.map = nil
        }
    }
}

//MARK: GMSAutocompleteViewControllerDelegate Methods

extension RideViewController: GMSAutocompleteViewControllerDelegate {
    
    // Handle the user's selection.
    func viewController(_ viewController: GMSAutocompleteViewController,
                        didAutocompleteWith place: GMSPlace) {
        activeTextField.text = place.name
        
        if activeTextField == pickupLocationField {
            origin = place.coordinate
        } else {
            destination = place.coordinate
        }
        
        if let _ = origin,
            let _ = destination {
            calculateDistanceBetweenTwoLocations()
        }
        
        addMarkerAt(place: place, isSource: (activeTextField == pickupLocationField))
        adjustMapCamera()
        dismiss(animated: true, completion: nil)
        
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController,
                        didFailAutocompleteWithError error: Error) {
        // TODO: handle the error.
        print("Error: ", error.localizedDescription)
    }
    
    // User canceled the operation.
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    // Turn the network activity indicator on and off again.
    func didRequestAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    
    func didUpdateAutocompletePredictions(_ viewController: GMSAutocompleteViewController) {
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
}

//MARK: GMSMapViewDelegate Methods

//extension RideViewController: GMSMapViewDelegate {
//    func mapView(_ mapView: GMSMapView, markerInfoWindow marker: GMSMarker) -> UIView? {
//        infoWindow = Bundle.main.loadNibNamed(
//            Constants.mapInfoWindowNibName, owner: self, options: nil)![0] as? MapIconView
//        infoWindow?.nameLabel.text = marker.title ?? " "
//        infoWindow?.durationLabel.text = distanceMatrix?.durationText ?? " - "
//        return infoWindow
//    }
//}
