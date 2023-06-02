//
//  ContentView.swift
//  RemindDis
//
//  Created by gaoxiaoxing on 5/31/23.
//

import SwiftUI
import CoreLocation
import MapKit

class LocationManager: NSObject, CLLocationManagerDelegate, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var locationServicesEnabled = CLLocationManager.locationServicesEnabled()
    @Published var message: String = "No message" // set an initial value for the message
    @Published var speed: Double = 0.0 // add a new @Published property for speed



    static let length = 7.0 // Example length value
    static let maxSpeed = 120.0 // Maximum speed for 7 * length
    static let maxDis = 7.0
    static let minSpeed = 30.0 // Minimum speed for 2 * length
    static let minDis = 2.0
    static var ratio: Double {
        return (LocationManager.maxDis - LocationManager.minDis) / (LocationManager.maxSpeed - LocationManager.minSpeed) * LocationManager.length
    }

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func calculateDistance(speed: Double) -> Double {
        var distance: Double

        if speed > LocationManager.maxSpeed {
            distance = LocationManager.maxDis * LocationManager.length
        } else if speed < LocationManager.minSpeed {
            distance = LocationManager.minDis * LocationManager.length
        } else {
            let ratio = (LocationManager.maxDis * LocationManager.length - LocationManager.minDis * LocationManager.length) / (LocationManager.maxSpeed - LocationManager.minSpeed)
            distance = ((speed - LocationManager.minSpeed) * ratio + LocationManager.minDis) * LocationManager.length
        }

        return distance
    }
     func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .denied {
            print("User denied location permission")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("Got location and update speed")
        guard let location = locations.last else { return }

        speed = location.speed * 3.6
        if (speed < 0) {
            message = "You are not moving"
            speed = 0
        } else {
            let formattedSpeed = String(format: "%.2f", speed) // format the speed to two decimal places
            print("Speed in locationManager is \(formattedSpeed) km/h")
            showAlert(speed: speed)
        }

    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error getting location: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        locationServicesEnabled = CLLocationManager.locationServicesEnabled()
        if locationServicesEnabled {
            // Location services are enabled
            print("User Location services are enabled")
        } else {
            // Location services are disabled
            print("User Location services are disabled")
        }
    }
}

extension LocationManager {
    func showAlert(speed: Double) {
        let distance = calculateDistance(speed: speed)
        message = "Please keep a distance of \(String(format: "%.2f", distance)) meters when speed is \(String(format: "%.2f", speed)) Km/h."
        let alertController = UIAlertController(title: "Alert", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
        }
    }
}


class TimeManager: ObservableObject {
    @Published var currentTime = Date()

    private var timer: Timer?

    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.currentTime = Date()
        }
    }

    deinit {
        timer?.invalidate()
    }
}

struct ContentView: View {
    @StateObject var locationManager = LocationManager()
    @State private var speed: Double = 0.0
    @State private var message: String = "Init values"
    @StateObject private var timeManager = TimeManager()
    let length: Double = 8 // Define the length in meters


    var body: some View {
        VStack {
            HStack {
                Image(systemName: "tornado")
                    .imageScale(.large)
                    .foregroundColor(.accentColor)
                    .font(.system(size: 48))
                Text("Hello, world!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.blue)
            }
            .padding()
            .background(Color.yellow)
            .cornerRadius(10)

            Text("Current time: \(timeManager.currentTime, formatter: dateFormatter)")
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .background(Color.yellow)
                .cornerRadius(10)

            Text("Current Speed: \(locationManager.speed, specifier: "%.2f") Km/h")
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .background(Color.yellow)
                .cornerRadius(10)


            Text("Notice: \(locationManager.message)")
                .font(.headline)
                .foregroundColor(.red)
                .padding()
                .background(Color.yellow)
                .cornerRadius(10)

            MapView(locationManager: locationManager)
                .edgesIgnoringSafeArea(.all)
                .frame(height: 300)
                .cornerRadius(10)

        }
        .onAppear {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        .onDisappear {
            locationManager.stopUpdatingLocation()
        }
    }

    init() {
        UINavigationBar.appearance().backgroundColor = .systemBlue
    }
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss z"
        return formatter
    }
}
class CustomAnnotationView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        didSet {
            guard let annotation = annotation as? CustomAnnotation else { return }
            glyphImage = annotation.image
        }
    }
}

class CustomAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var image: UIImage?
    var detailImage: UIImage?

    init(coordinate: CLLocationCoordinate2D, title: String?, subtitle: String?, image: UIImage?, detailImage: UIImage?) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.image = image
        self.detailImage = detailImage
    }
}

struct MapView: UIViewRepresentable {
    @ObservedObject var locationManager: LocationManager
    let length: Double = 10 // Define the length in meters

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        guard let location = locationManager.location else { return }
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
        uiView.setRegion(region, animated: true)

        // Add custom pin annotation to the map view
        let annotation = CustomAnnotation(coordinate: location.coordinate, title: "Current Location", subtitle: nil, image: UIImage(named: "custom_pin"), detailImage: UIImage(named: "custom_detail"))
        uiView.addAnnotation(annotation)

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                let annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: "userLocation")
                annotationView.image = UIImage(systemName: "location.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
                return annotationView
            } else if let customAnnotation = annotation as? CustomAnnotation {
                // Create a custom annotation view for the custom annotation
                let annotationView = CustomAnnotationView(annotation: customAnnotation, reuseIdentifier: "CustomAnnotation")
                annotationView.canShowCallout = true

                // Add custom image to the callout accessory view
                let imageView = UIImageView(image: customAnnotation.detailImage)
                imageView.contentMode = .scaleAspectFit
                imageView.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
                annotationView.detailCalloutAccessoryView = imageView

                let button = UIButton(type: .detailDisclosure)
                annotationView.rightCalloutAccessoryView = button

                // Set the image to a red pin
                annotationView.image = UIImage(systemName: "mappin.circle.fill")?.withTintColor(.red, renderingMode: .alwaysOriginal)
                return annotationView
            } else {
                return nil
            }
        }
    }
    init(locationManager: LocationManager) {
        self.locationManager = locationManager
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
