//
//  ContentView.swift
//  ISS-Finder-App
//
//  Created by Ali Almatrafi on 23/12/2022.
//

import SwiftUI
import MapKit
import Combine

struct ContentView: View {
    @ObservedObject var locationPublisher = LocationPublisher()
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 16)
                    .foregroundColor(Color.clear)
                    .symbolVariant(.circle.fill)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.blue, .blue.opacity(0.3))
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial))
                    .frame(height: 60)
                    .overlay {
                        Text("موقع محطة الفضاء الدولية ")
                            .font(.title.weight(.semibold))
                    }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .zIndex(2)
            
            Spacer()
            MapView(locationPublisher: locationPublisher)
                .environment(\.colorScheme, .light)
                .background(Color.white)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct MapView: UIViewRepresentable {
    @ObservedObject var locationPublisher: LocationPublisher
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator // set the delegate to the Coordinator
        let annotation = MKPointAnnotation()
        annotation.coordinate = locationPublisher.coordinate
        mapView.addAnnotation(annotation)
        
        let polyline = MKPolyline(coordinates: &locationPublisher.coordinates, count: locationPublisher.coordinates.count)
        mapView.addOverlay(polyline)
        
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        for annotation in uiView.annotations {
            uiView.removeAnnotation(annotation)
        }
        let annotation = MKPointAnnotation()
        annotation.coordinate = locationPublisher.coordinate
        uiView.addAnnotation(annotation)
        uiView.setCenter(annotation.coordinate, animated: true)
        uiView.removeOverlays(uiView.overlays)
        let polyline = MKPolyline(coordinates: &locationPublisher.coordinates, count: locationPublisher.coordinates.count)
        uiView.addOverlay(polyline)
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapView
        
        init(_ parent: MapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .red
            renderer.lineWidth = 2
            return renderer
        }
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .red // change the stroke color to red
        renderer.lineWidth = 2
        return renderer
    }
}

class LocationPublisher: ObservableObject {
    @Published var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D()
    @Published var coordinates: [CLLocationCoordinate2D] = []
    
    private var cancellable: AnyCancellable?
    private var timer: Timer?
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            self.cancellable = self.fetchLocation()
        }
    }
    
    func fetchLocation() -> AnyCancellable {
        let url = URL(string: "http://api.open-notify.org/iss-now.json")!
        return URLSession.shared.dataTaskPublisher(for: url)
            .map { $0.data }
            .decode(type: ISSResponse.self, decoder: JSONDecoder())
            .map { $0.iss_position }
            .sink(receiveCompletion: { _ in }, receiveValue: { position in
                self.coordinate = CLLocationCoordinate2D(latitude: Double(position.latitude)!, longitude: Double(position.longitude)!)
                self.coordinates.append(self.coordinate)
            })
    }
}

struct ISSResponse: Codable {
    let timestamp: Int
    let message: String
    let iss_position: ISSPosition
    
    struct ISSPosition: Codable {
        let longitude: String
        let latitude: String
    }
}
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
