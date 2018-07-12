//
//  rideViewController.swift
//  Assignment
//
//  Created by Christi John on 08/07/18.
//  Copyright © 2018 Chris Inc. All rights reserved.
//

import UIKit
import InteractiveSideMenu
import GooglePlaces
import CoreLocation
import GoogleMaps
import Alamofire
import Speech

enum SpeechStatus {
    case ready
    case recognizing
    case unavailable
}

class RideViewController: UIViewController, SideMenuItemContent {
    
    @IBOutlet weak var pickupLocationField: UITextField!
    @IBOutlet weak var dropOffLocationField: UITextField!
    @IBOutlet weak var dropOffView: UIView!
    @IBOutlet weak var mapHolderView: UIView!
    @IBOutlet weak var singleTripButton: UIButton!
    @IBOutlet weak var returnTripButton: UIButton!
    
    @IBOutlet weak var alignXCentresOfSingleTripAndSelection: NSLayoutConstraint!
    @IBOutlet weak var alignXCentresOfReturnTripAndSelection: NSLayoutConstraint!
    @IBOutlet weak var tripModesHolder: UIView!
    @IBOutlet weak var tripModeSelectionImage: UIImageView!
    
    internal var placesClient: GMSPlacesClient!
    internal var mapView : GMSMapView!
    internal var origin : CLLocationCoordinate2D?
    internal var destination: CLLocationCoordinate2D?
    internal var distanceMatrix: DistanceMatrix?
    internal var infoWindow: MapIconView?
    internal var sourceMarker: GMSMarker?
    internal var destinationMarker: GMSMarker?
    internal var activeTextField: UITextField!
    
    private let locationManger = CLLocationManager()
    private var currentAuthorizationStatus = CLAuthorizationStatus.notDetermined
    private var resultsViewController: GMSAutocompleteResultsViewController?
    private var searchController: UISearchController?
    private var resultView: UITextView?
    private var tripMode = TripMode.singleTrip
    
    private var status = SpeechStatus.ready
    private let audioEngine = AVAudioEngine()
    private let speechRecognizer: SFSpeechRecognizer? = SFSpeechRecognizer()
    private let request = SFSpeechAudioBufferRecognitionRequest()
    private var recognitionTask: SFSpeechRecognitionTask?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        doInitialSetup()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if mapView == nil {
            addMapView()
        }
    }
    
    //MARK : Private methods
    private func doInitialSetup() {
        tripModesHolder.addShadow(radius: 0.4, opacity: 0.1)
        updateTripMode()
        
        placesClient = GMSPlacesClient.shared()
        requestLocationAccessAuthorization()
        checkAndRequestSpeechAuthorization()
        
    }
    
    private func requestLocationAccessAuthorization() {
        locationManger.delegate     = self
        currentAuthorizationStatus  = CLLocationManager .authorizationStatus()
        
        //For Google Places to work, we need to request access to use location services.
        if (currentAuthorizationStatus == .notDetermined) {
            locationManger.requestWhenInUseAuthorization()
        } else if (currentAuthorizationStatus  == .authorizedWhenInUse) {
            updateCurrentPlace()
        }
        
    }
    
    private func checkAndRequestSpeechAuthorization() {
        
        switch SFSpeechRecognizer.authorizationStatus() {
        case .notDetermined:
            requestSpeechRecognitionPermission()
        case .authorized:
            self.status = .ready
        case .denied, .restricted:
            self.status = .unavailable
        }
    }
    
    /// Asks permission to the user to access their speech data.
    func requestSpeechRecognitionPermission() {
        SFSpeechRecognizer.requestAuthorization { status in
            OperationQueue.main.addOperation {
                switch status {
                case .authorized:
                    self.status = .ready
                default:
                    self.status = .unavailable
                }
            }
        }
    }
    
    /// updates trip modes UI.
    /// text color and selection image will be updated based on current selection.
    /// Default trip mode is SingleTrip
    private func updateTripMode() {
        let selectedColor = UIColor.white
        let normalColor = UIColor.tripModeTextColor
        
        if tripMode == .singleTrip {
            singleTripButton.setTitleColor(selectedColor, for: .normal)
            returnTripButton.setTitleColor(normalColor, for: .normal)
            self.alignXCentresOfSingleTripAndSelection.priority = UILayoutPriority(rawValue: 999)
            self.alignXCentresOfReturnTripAndSelection.priority = UILayoutPriority(rawValue: 750)
        } else {
            returnTripButton.setTitleColor(selectedColor, for: .normal)
            singleTripButton.setTitleColor(normalColor, for: .normal)
            self.alignXCentresOfSingleTripAndSelection.priority = UILayoutPriority(rawValue: 750)
            self.alignXCentresOfReturnTripAndSelection.priority = UILayoutPriority(rawValue: 999)
        }
        
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
    }
    
    /// Once pickup and dropoff locations are selected, calcualte the duration between them
    /// Using Google's distance matrix API
    /// On getting response, destination marker's icon view updates with the duration
    internal func calculateDistanceBetweenTwoLocations() {
        distanceMatrix = nil
        
        guard let origin = origin,
            let destination = destination,
            let requestUrl = URL(string: Constants.distanceMatrixAPI) else {
                return
        }
        
        let params = [ "origins": "\(origin.latitude),\(origin.longitude)",
            "destinations": "\(destination.latitude),\(destination.longitude)",
            "key": Constants.googlePlacesAPIKey]
        
        APIManager.getReuest(requestUrl: requestUrl,
                             method: .get,
                             params: params)
        { (finished, result) in
            
            self.distanceMatrix = DistanceMatrix(response: result as! [String : AnyObject])
            if let duration = self.distanceMatrix?.durationText {
                print("Duration: \(duration)")
                DispatchQueue.main.async {
                    //                    self.destinationMarker?.tracksInfoWindowChanges = true
                    //                    self.infoWindow?.updateDurationLabel(duration: duration)
                    let iconView = self.destinationMarker?.iconView as! MapIconView
                    iconView.updateDurationLabel(duration: duration)
                }
            }
        }
    }
    
    
    private func recognizeLocation() {
        switch status {
        case .ready:
            startRecording()
            status = .recognizing
            
        case .recognizing:
            cancelRecording()
            status = .ready
            
            if let searchKey = activeTextField.text,
                searchKey.count > 0{
                showAutoCompletionView()
            }
            
        default:
            break
        }
    }
    
    /// Start streaming the microphone data to the speech recognizer to recognize it live.
    func startRecording() {
        activeTextField.text = ""
        
        // Setup audio engine and speech recognizer
        //        guard let node = audioEngine.inputNode else { return }
        let node = audioEngine.inputNode
        let recordingFormat = node.outputFormat(forBus: 0)
        node.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.request.append(buffer)
        }
        
        // Prepare and start recording
        audioEngine.prepare()
        do {
            try audioEngine.start()
            self.status = .recognizing
        } catch {
            return print(error)
        }
        
        // Analyze the speech
        recognitionTask = speechRecognizer?.recognitionTask(with: request, resultHandler: { result, error in
            if let result = result {
                self.activeTextField.text = result.bestTranscription.formattedString
                
            } else if let error = error {
                print(error)
            }
        })
    }
    
    /// Stops and cancels the speech recognition.
    func cancelRecording() {
        audioEngine.stop()
        let node = audioEngine.inputNode
        node.removeTap(onBus: 0)
        
        recognitionTask?.cancel()
    }
    
    //MARK: Action methods
    @IBAction func didTapMenu(_ sender: Any) {
        showSideMenu()
    }
    
    @IBAction func didTapSingleTrip(_ sender: Any) {
        tripMode = .singleTrip
        updateTripMode()
    }
    
    @IBAction func didTapReturnTrip(_ sender: Any) {
        tripMode = .returnTrip
        updateTripMode()
    }
    
    @IBAction func startRecognisingSource(_ sender: UIButton) {
        if #available(iOS 11.0, *) {
            sender.tintColor = (sender.tintColor == UIColor(named: "microPhoneColor")) ? UIColor(named: "selectionColor") : UIColor(named: "microPhoneColor")
        } else {
            // Fallback on earlier versions
            sender.tintColor = (sender.tintColor == UIColor.microphoneColor) ? UIColor.selectionColor : UIColor.microphoneColor
            
        }
        activeTextField = pickupLocationField
        recognizeLocation()
    }
    
    @IBAction func startRecognisingDestination(_ sender: UIButton) {
        if #available(iOS 11.0, *) {
            sender.tintColor = (sender.tintColor == UIColor(named: "microPhoneColor")) ? UIColor(named: "selectionColor") : UIColor(named: "microPhoneColor")
        } else {
            sender.tintColor = (sender.tintColor == UIColor.microphoneColor) ? UIColor.selectionColor : UIColor.microphoneColor
        }
        activeTextField = dropOffLocationField
        recognizeLocation()
    }
    
}

extension RideViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        showAutoCompletionView()
        activeTextField = textField
        return false
    }
}

extension RideViewController: CLLocationManagerDelegate {
    
    //MARK: CLLocationManagerDelegate methods
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if (CLLocationManager .authorizationStatus() == .authorizedWhenInUse && currentAuthorizationStatus != .authorizedWhenInUse) {
            currentAuthorizationStatus = .authorizedWhenInUse
            updateCurrentPlace()
        }
    }
}

