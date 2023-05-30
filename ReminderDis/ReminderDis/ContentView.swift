//
//  ContentView.swift
//  ReminderDis
//
//  Created by gaoxiaoxing on 5/30/23.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Item.timestamp, ascending: true)],
        animation: .default)
    private var items: FetchedResults<Item>

    let locationManager = CLLocationManager()

    var body: some View {
        Text("Current speed: \(locationManager.location?.speed ?? 0) meters per second")
            .padding()
            .onAppear {
                locationManager.delegate = self
                locationManager.requestWhenInUseAuthorization()
                locationManager.startUpdatingLocation()
            }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}