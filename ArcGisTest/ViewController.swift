//
//  ViewController.swift
//  ArcGisTest
//
//  Created by Josh Lay on 6/01/2016.
//  Copyright © 2016 Agworld. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UIViewController, AGSMapViewLayerDelegate, AGSMapViewTouchDelegate, AGSLayerCalloutDelegate, LocationObserverDelegate {
    @IBOutlet weak var mapView: AGSMapView!
    @IBOutlet weak var totalAreaLabel: UILabel!

    private let graphicsLayerIdentifier = "Graphics Layer"
    private let sketchLayerIdentifier = "Sketch Layer"
    private var locationObserver: LocationObserver?
    private var isSketching: Bool = false
    private var drawingPolygons: [AGSGeometry] = [AGSGeometry]()

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let tiledURL = NSURL(string: "http://services.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer") else {
            return
        }

        mapView.layerDelegate = self
        mapView.touchDelegate = self

        let serviceLayer = AGSTiledMapServiceLayer(URL: tiledURL)
        serviceLayer.renderNativeResolution = true
        mapView.addMapLayer(serviceLayer, withName: "Basemap Tiled Layer")

        let graphicsLayer = AGSGraphicsLayer.graphicsLayer() as! AGSGraphicsLayer
        graphicsLayer.calloutDelegate = self

        let sketchLayer = AGSSketchGraphicsLayer.graphicsLayer() as! AGSSketchGraphicsLayer
        mapView.addMapLayer(sketchLayer, withName: sketchLayerIdentifier)

        let myMarkerSymbol = AGSSimpleMarkerSymbol.simpleMarkerSymbolWithColor(UIColor.greenColor()) as! AGSSimpleMarkerSymbol
        graphicsLayer.renderer = AGSSimpleRenderer(symbol: myMarkerSymbol)
        mapView.addMapLayer(graphicsLayer, withName: graphicsLayerIdentifier)
        populateGraphicsLayer(graphicsLayer)
    }

    private func populateGraphicsLayer(layer: AGSGraphicsLayer) {
        let baseLat = -31.9413524
        let baseLng = 115.8394953

        let envelope: AGSMutableEnvelope = AGSMutableEnvelope(spatialReference: AGSSpatialReference.webMercatorSpatialReference())
        let names = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten"]
        for i in 0...9 {
            let lat = baseLat + Double(Double(i) / 100.0)
            let lng = baseLng

            let myMarkerPoint = AGSPoint(location: CLLocation(latitude: lat, longitude: lng))

            let ge = AGSGeometryEngine.defaultGeometryEngine()
            let reprojectedPoint = ge.projectGeometry(myMarkerPoint, toSpatialReference: AGSSpatialReference.webMercatorSpatialReference())

            let attributes = [
                "name": names[i],
                "id": NSNumber(integer: i)
            ]
            let myGraphic = AGSGraphic(geometry: reprojectedPoint, symbol: nil, attributes: attributes)

            layer.addGraphic(myGraphic)

            envelope.unionWithEnvelope(reprojectedPoint.envelope)
        }

        mapView.zoomToEnvelope(envelope, animated: true)
    }

    @IBAction func onGetMyLocation() {
        mapView.locationDisplay.startDataSource()
    }

    @IBAction func onStartSketching(sender: UIButton) {
        isSketching = !isSketching

        if let sketchLayer = mapView.mapLayerForName(sketchLayerIdentifier) as? AGSSketchGraphicsLayer {
            if isSketching {
                sender.setTitle("Stop Sketching", forState: .Normal)

                let polygon = AGSMutablePolygon(spatialReference: mapView.spatialReference)
                sketchLayer.geometry = polygon
                mapView.touchDelegate = sketchLayer
            } else {
                sender.setTitle("Start Sketching", forState: .Normal)
                mapView.touchDelegate = self

                if let sketchPolygon = sketchLayer.geometry where sketchPolygon.isValid() {
                    let simplePoly = AGSGeometryEngine.defaultGeometryEngine().simplifyGeometry(sketchPolygon)
                    let fillSymbol = AGSSimpleFillSymbol(color: UIColor.redColor(), outlineColor: UIColor.blackColor())
                    let graphic = AGSGraphic(geometry: simplePoly, symbol: fillSymbol, attributes: nil)

                    if let graphicsLayer = mapView.mapLayerForName(graphicsLayerIdentifier) as? AGSGraphicsLayer {
                        graphicsLayer.addGraphic(graphic)

                        drawingPolygons.append(simplePoly)
                    }

                    sketchLayer.clear()
                }
            }
        }
    }

    @IBAction func onUnionPolygon() {
        let unionedPolygon = AGSGeometryEngine.defaultGeometryEngine().unionGeometries(drawingPolygons)

        drawingPolygons.removeAll()
        if let graphicsLayer = mapView.mapLayerForName(graphicsLayerIdentifier) as? AGSGraphicsLayer {
            if let graphics = graphicsLayer.graphics as? [AGSGraphic] {
                for graphic in graphics {
                    if graphic.geometry is AGSPolygon {
                        graphicsLayer.removeGraphic(graphic)
                    }
                }
            }

            let area = AGSGeometryEngine.defaultGeometryEngine().shapePreservingAreaOfGeometry(unionedPolygon, inUnit: .Hectares)
            totalAreaLabel.text = String(format: "AREA: %.2f ha", area)

            let fillSymbol = AGSSimpleFillSymbol(color: UIColor.redColor(), outlineColor: UIColor.blackColor())
            let graphic = AGSGraphic(geometry: unionedPolygon, symbol: fillSymbol, attributes: nil)
            graphicsLayer.addGraphic(graphic)
        }
    }

    @IBAction func onDiffPolygon() {
        if let first = drawingPolygons.first as AGSGeometry?, let second = drawingPolygons.last as AGSGeometry? where drawingPolygons.count == 2 {
            if AGSGeometryEngine.defaultGeometryEngine().geometry(second, withinGeometry: first) {
                let diffedPolygon = AGSGeometryEngine.defaultGeometryEngine().differenceOfGeometry(first, andGeometry: second)

                drawingPolygons.removeAll()
                if let graphicsLayer = mapView.mapLayerForName(graphicsLayerIdentifier) as? AGSGraphicsLayer {
                    if let graphics = graphicsLayer.graphics as? [AGSGraphic] {
                        for graphic in graphics {
                            if graphic.geometry is AGSPolygon {
                                graphicsLayer.removeGraphic(graphic)
                            }
                        }
                    }

                    let area = AGSGeometryEngine.defaultGeometryEngine().shapePreservingAreaOfGeometry(diffedPolygon, inUnit: .Hectares)
                    totalAreaLabel.text = String(format: "AREA: %.2f ha", area)

                    let fillSymbol = AGSSimpleFillSymbol(color: UIColor.redColor(), outlineColor: UIColor.blackColor())
                    let graphic = AGSGraphic(geometry: diffedPolygon, symbol: fillSymbol, attributes: nil)
                    graphicsLayer.addGraphic(graphic)
                }
            }
        }
    }

    //MARK: AGSMapViewTouchDelegate
    func mapView(mapView: AGSMapView!, didClickAtPoint screen: CGPoint, mapPoint mappoint: AGSPoint!, features: [NSObject : AnyObject]!) {
        guard let graphicLayerFeatures = features[graphicsLayerIdentifier] as? [AGSFeature] where features.keys.count > 0 else {
            return
        }

        for feature in graphicLayerFeatures {
            if feature.geometry is AGSPoint {
                if let id = feature.attributeForKey("id") as? NSNumber {
                    NSLog("Tapped Point: %@", id)
                }
            } else if feature.geometry is AGSPolygon {

            }
        }
    }

    //MARK: AGSCalloutDelegate
    func callout(callout: AGSCallout!, willShowForFeature feature: AGSFeature!, layer: AGSLayer!, mapPoint: AGSPoint!) -> Bool {
        if feature.geometry is AGSPoint {
            mapView.callout.title = feature.attributeAsStringForKey("name")
            mapView.callout.detail = feature.attributeAsStringForKey("id")

            return true
        }

        return false
    }

    //MARK: AGSMapViewLayerDelegate
    func mapViewDidLoad(mapView: AGSMapView!) {
        locationObserver = LocationObserver(observableLocationDisplay: mapView.locationDisplay)
        locationObserver?.delegate = self
    }

    //MARK: LocationObserverDelegate
    func locationWasUpdated(observer: LocationObserver) {
        NSLog("Location updated: %@", mapView.locationDisplay.mapLocation())

        mapView.zoomToEnvelope(mapView.locationDisplay.mapLocation().envelope, animated: true)
        locationObserver?.stopObserving()
    }
}

protocol LocationObserverDelegate: class {
    func locationWasUpdated(observer: LocationObserver)
}

class LocationObserver: NSObject {
    let observable: AGSLocationDisplay
    weak var delegate: LocationObserverDelegate?

    deinit {
        observable.removeObserver(self, forKeyPath: "location")
    }

    init(observableLocationDisplay: AGSLocationDisplay) {
        observable = observableLocationDisplay

        super.init()

        observable.addObserver(self, forKeyPath: "location", options: .New, context: nil)
    }

    func stopObserving() {
        observable.removeObserver(self, forKeyPath: "location")
    }

    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "location" {
            delegate?.locationWasUpdated(self)
        }
    }
}

