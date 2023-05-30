import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var speed: CLLocationSpeed = 0.0
    var warningDistance: Double = 0.0
    
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        speed = location.speed
        
        if speed > 120 {
            warningDistance = 7.0
        } else if speed < 30 {
            warningDistance = 2.0
        } else {
            warningDistance = (speed - 30) / (120 - 30) * (7 - 2) + 2
        }
        
        distanceLabel.text = String(format: "%.1f meters", warningDistance)
        distanceLabel.textColor = UIColor.white
        distanceLabel.font = UIFont.systemFont(ofSize: 24.0, weight: .bold)
        distanceLabel.backgroundColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.5)
        distanceLabel.textAlignment = .center
        distanceLabel.layer.cornerRadius = 10.0
        distanceLabel.layer.borderWidth = 2.0
        distanceLabel.layer.borderColor = UIColor.white.cgColor
    }
}