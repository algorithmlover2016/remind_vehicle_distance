//
//  ContentView.swift
//  RemindDis
//
//  Created by gaoxiaoxing on 5/31/23.
//

import SwiftUI
import CoreLocation
import MapKit

class LocationManager: NSObject, ObservableObject {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var locationServicesEnabled = CLLocationManager.locationServicesEnabled()

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
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .denied {
            print("User denied location permission")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        let newSpeed = location.speed * 3.6
        var distance: Double
        var message: String
        if newSpeed >= LocationManager.maxSpeed {
            distance = LocationManager.maxDis * LocationManager.length
        } else if newSpeed <= LocationManager.minSpeed {
            distance = LocationManager.minDis * LocationManager.length
        } else {
            distance = ((newSpeed - LocationManager.minSpeed) * LocationManager.ratio + LocationManager.minDis) * LocationManager.length
        }
        message = "Please keep a distance of \(String(format: "%.2f", distance)) meters."

        let alertController = UIAlertController(title: "Warning", message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(okAction)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let viewController = windowScene.windows.first?.rootViewController {
            viewController.present(alertController, animated: true, completion: nil)
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

struct ContentView: View {
    @ObservedObject var locationManager = LocationManager()
    @State private var speed: CLLocationSpeed = 0.0
    @State private var message = "Init values"
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

            MapView(locationManager: locationManager, speed: $speed, message: $message)
                .frame(height: 300)
                .cornerRadius(10)

            Text("Current Speed: \(speed, specifier: "%.2f") Km/h")
                .font(.headline)
                .foregroundColor(.blue)
                .padding()
                .background(Color.yellow)
                .cornerRadius(10)

            Text("Display: \(message)")
                .font(.headline)
                .foregroundColor(.red)
                .padding()
                .background(Color.yellow)
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
    @Binding var speed: CLLocationSpeed
    @Binding var message: String
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

        // Update speed
        speed = location.speed * 3.6 // Convert m/s to km/h
        print("Message: \(message)\nSpeed: \(speed)")
        // Display warning message according to the speed
        if speed > Double(120) {
            let distance = 7 * length
            message = "Please keep a distance of \(distance) meters."
        } else if speed < Double(30) {
            let distance = 2 * length
            message = "Please keep a distance of \(distance) meters."
        } else {
            let distance = (speed - 30) * 0.1 * length
            message = "Please keep a distance of \(distance) meters."
        }
        let distance = 2 * length
        message = "Please keep a distance of \(distance) meters."
        print("Message: \(message)")
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
            guard let annotation = annotation as? CustomAnnotation else { return nil }
            let identifier = "custom_pin"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CustomAnnotationView
            if annotationView == nil {
                annotationView = CustomAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true

                // Add custom image to the callout accessory view
                let imageView = UIImageView(image: annotation.detailImage)
                imageView.contentMode = .scaleAspectFit
                annotationView?.leftCalloutAccessoryView = imageView

                let button = UIButton(type: .detailDisclosure)
                annotationView?.rightCalloutAccessoryView = button
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
    }
    init(locationManager: LocationManager, speed: Binding<CLLocationSpeed>, message: Binding<String> ) {
        self.locationManager = locationManager
        self._speed = speed
        self._message = message
    }

}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
