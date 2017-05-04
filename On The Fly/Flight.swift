//
//  Flight.swift
//  On The Fly
//
//  Created by Scott Higgins on 2/8/17.
//  Copyright © 2017 ScottieH. All rights reserved.
//

import Foundation
import Firebase

struct Flight {
    
    var plane: String
    var departAirport: String
    var arriveAirport: String
    var date: String
    var time: String
    var startFuel: Double
    var flightDuration: Int
    var fuelFlow: Double
    var passengers: [String:[String:Any]]?
    var frontBaggageWeight: Int
    var aftBaggageWeight: Int
    var taxiFuelBurn: Int
    let userid: String
    let fireRef: FIRDatabaseReference?
    
    init(plane: String, dptArpt: String, arvArpt: String, date: String, time: String, uid: String,
         startFuel: Double, flightDuration: Int, fuelFlow: Double, passengers: [String:[String:Any]],
         frontBagWeight: Int, aftBagWeight: Int, taxiBurn: Int) {
        self.plane = plane
        self.departAirport = dptArpt
        self.arriveAirport = arvArpt
        self.date = date
        self.time = time
        self.startFuel = startFuel
        self.flightDuration = flightDuration
        self.fuelFlow = fuelFlow
        self.passengers = passengers
        self.frontBaggageWeight = frontBagWeight
        self.aftBaggageWeight = aftBagWeight
        self.taxiFuelBurn = taxiBurn
        self.userid = uid
        self.fireRef = nil
    }
    
    init(snapshot: FIRDataSnapshot) {
        let snapshotValue = snapshot.value as! [String: Any]
        self.plane = snapshotValue["plane"] as! String
        self.departAirport = snapshotValue["departAirport"] as! String
        self.arriveAirport = snapshotValue["arriveAirport"] as! String
        self.date = snapshotValue["date"] as! String
        self.time = snapshotValue["time"] as! String
        self.startFuel = snapshotValue["startFuel"] as! Double
        self.flightDuration = snapshotValue["flightDuration"] as! Int
        self.fuelFlow = snapshotValue["fuelFlow"] as! Double
        self.passengers = snapshotValue["passengers"] as? [String:[String:Any]]
        self.frontBaggageWeight = snapshotValue["frontBaggageWeight"] as! Int
        self.aftBaggageWeight = snapshotValue["aftBaggageWeight"] as! Int
        self.taxiFuelBurn = snapshotValue["taxiFuelBurn"] as! Int
        self.userid = snapshotValue["userid"] as! String
        self.fireRef = snapshot.ref
    }
    
    func toAnyObject() -> Any {
        return [
            "plane": plane,
            "departAirport": departAirport,
            "arriveAirport": arriveAirport,
            "date": date,
            "time": time,
            "startFuel": startFuel,
            "flightDuration": flightDuration,
            "fuelFlow": fuelFlow,
            "passengers": passengers ?? [:],
            "frontBaggageWeight": frontBaggageWeight,
            "aftBaggageWeight": aftBaggageWeight,
            "taxiFuelBurn": taxiFuelBurn,
            "userid": userid
        ]
    }
    
    func isRampWeightOkay(plane: Plane) -> Bool {
        return (calcZeroFuelWeight(plane: plane) + startFuel * 6.0) < Double(plane.maxRampWeight)
    }
    
    func isTakeoffWeightOkay(plane: Plane) -> Bool {
        return calcTakeoffWeight(plane: plane) < Double(plane.maxTakeoffWeight)
    }
    
    func calcZeroFuelWeight(plane: Plane) -> Double {
        var weight = Double(plane.emptyWeight)
        if self.passengers != nil {
            for (_, dict) in self.passengers! {
                weight += (dict["weight"] as! Double)
            }
        }
        weight += Double(frontBaggageWeight)
        weight += Double(aftBaggageWeight)
        return weight
    }
    
    func calcTakeoffWeight(plane: Plane) -> Double {
        return (calcZeroFuelWeight(plane: plane) + startFuel * 6.0 - Double(taxiFuelBurn) * 6.0)
    }
    
    func calcLandingWeight(plane: Plane) -> Double {
        return (calcTakeoffWeight(plane: plane) - Double(fuelFlow * Double(flightDuration) / 10.0))
    }
    
    func calcTakeoffCenterOfGravity(plane: Plane) -> Double {
        let weight = calcTakeoffWeight(plane: plane)
        var moment = 0.0
        
        moment += Double(plane.emptyWeight) * plane.emptyWeightArm
        
        for i in 0...(plane.numSeats - 1) {
            let row = i / 2
            if row == 0 {
                moment += weightForSeatIndex(index: i) * plane.pilotSeatsArm
            } else {
                moment += weightForSeatIndex(index: i) * plane.rowArms[row - 1]
            }
        }
        
        moment += (startFuel - Double(taxiFuelBurn)) * 6.0 * plane.fuelArm
        
        moment += Double(frontBaggageWeight) * plane.frontBaggageArm
        
        moment += Double(aftBaggageWeight) * plane.aftBaggageArm
        
//        print("moment: ", moment)
//        print("weight: ", weight)
        
        return moment / weight
    }
    
    func calcLandingCenterOfGravity(plane: Plane) -> Double {
        let weight = calcLandingWeight(plane: plane)
        var moment = 0.0
        
        moment += Double(plane.emptyWeight) * plane.emptyWeightArm
        
        for i in 0...(plane.numSeats - 1) {
            let row = i / 2
            if row == 0 {
                moment += weightForSeatIndex(index: i) * plane.pilotSeatsArm
            } else {
                moment += weightForSeatIndex(index: i) * plane.rowArms[row - 1]
            }
        }
        
        moment += (startFuel - Double(taxiFuelBurn)) * 6.0 * plane.fuelArm
        
        moment += Double(frontBaggageWeight) * plane.frontBaggageArm
        
        moment += Double(aftBaggageWeight) * plane.aftBaggageArm
        
        moment -= (Double(flightDuration) * fuelFlow / 10.0) * plane.fuelArm
        
        return moment / weight
    }
    
    func calcTotalPaxWeight() -> Double {
        var totalWeight: Double = 0.0
        for each in self.passengers!.values {
            totalWeight += each["weight"] as! Double
        }
        return totalWeight
    }
    
    func calcTakeoffLimits(plane: Plane) -> [Double] {
        var takeoffLimits: [Double] = []
        let envData = plane.centerOfGravityEnvelope
        let takeoffWeight = self.calcTakeoffWeight(plane: plane)
        let a = CGPoint(x: 0.0, y: takeoffWeight)
        let b = CGPoint(x: 30000.0, y: takeoffWeight)
        for i in 0...envData.count {
            if i + 1 < envData.count {
                let curPoint = envData[i]
                let nextPoint = envData[i+1]
                let c = CGPoint(x: curPoint["x"]!, y: curPoint["y"]!)
                let d = CGPoint(x: nextPoint["x"]!, y: nextPoint["y"]!)
                let intersection = getIntersectionOfLines(line1: (a: a, b: b), line2: (a: c, b: d))
                if intersection != CGPoint.zero {
                    takeoffLimits.append(Double(intersection.x).roundTo(places: 1))
                }
            }
        }
        print(takeoffLimits)
        return(takeoffLimits)
    }
    
    func calcLandingLimits(plane: Plane) -> [Double] {
        var landingLimits: [Double] = []
        let envData = plane.centerOfGravityEnvelope
        let landingWeight = self.calcLandingWeight(plane: plane)
        let a = CGPoint(x: 0.0, y: landingWeight)
        let b = CGPoint(x: 30000.0, y: landingWeight)
        for i in 0...envData.count {
            if i + 1 < envData.count {
                let curPoint = envData[i]
                let nextPoint = envData[i+1]
                let c = CGPoint(x: curPoint["x"]!, y: curPoint["y"]!)
                let d = CGPoint(x: nextPoint["x"]!, y: nextPoint["y"]!)
                let intersection = getIntersectionOfLines(line1: (a: a, b: b), line2: (a: c, b: d))
                if intersection != CGPoint.zero {
                    landingLimits.append(Double(intersection.x).roundTo(places: 1))
                }
            }
        }
        print(landingLimits)
        return(landingLimits)
    }
    
    func getFlightItenerary() -> String {
        return "\(self.departAirport) to \(self.arriveAirport) on \(self.date)"
    }
    
    func weightForSeatIndex(index: Int) -> Double {
        let key = "seat\(index + 1)"
        var weightToReturn = 0.0
        if let weightDict = passengers?[key] {
            weightToReturn = (weightDict["weight"] as! Double)
        }
        return weightToReturn
    }
    
    func updateFrontBaggageWeight() {
        let update = ["frontBaggageWeight": frontBaggageWeight]
        fireRef?.updateChildValues(update)
    }
    
    func updateAftBaggageWeight() {
        let update = ["aftBaggageWeight": aftBaggageWeight]
        fireRef?.updateChildValues(update)
    }
    
    func updateDateAndTime() {
        let updates = ["date": date,
                      "time": time]
        fireRef?.updateChildValues(updates)
    }
    
    func updateAirports() {
        let updates = ["departAirport": departAirport,
                       "arriveAirport": arriveAirport]
        fireRef?.updateChildValues(updates)
    }
    
    func updateFlightParameters() {
        let updates = ["startFuel": startFuel,
                       "flightDuration": flightDuration,
                       "fuelFlow": fuelFlow,
                       "taxiFuelBurn": taxiFuelBurn] as [String : Any]
        fireRef?.updateChildValues(updates)
    }
    
    func calcArrivalTime() -> String {
        let dateformatter = DateFormatter()
        dateformatter.timeStyle = .short
        let departureTime = dateformatter.date(from: self.time)
        let time2 = departureTime!.addingTimeInterval(Double(self.flightDuration) * 60.0)
        return dateformatter.string(from: time2)
    }
    
    func checkValidFlight(plane: Plane) throws {
        // Simple check for the weight of the plane
        if calcTakeoffWeight(plane: plane) > Double(plane.maxTakeoffWeight) {
            throw FlightErrors.tooHeavyOnRamp
        }
        
        // Is there any fuel?
        if startFuel == 0.0 {
            throw FlightErrors.noStartingFuel
        }
        
        // Is there enough fuel?
        if (Double(flightDuration)/60.0 * fuelFlow + Double(taxiFuelBurn)) > startFuel {
            throw FlightErrors.insufficientFuel
        }
        
        // Check if the 2 CoG points are within the acceptable limits
        let p = UIBezierPath()
        var polygon: [CGPoint] = []
        for each in plane.centerOfGravityEnvelope {
            polygon.append(CGPoint(x: each["x"]!, y: each["y"]!))
        }
        
        p.move(to: polygon.first!)
        for index in 1...polygon.count - 1 {
            p.addLine(to: polygon[index])
        }
        
        p.close()
        
        let takeoffCogPoint = CGPoint(x: calcTakeoffCenterOfGravity(plane: plane), y: calcTakeoffWeight(plane: plane))
        let landingCogPoint = CGPoint(x: calcLandingCenterOfGravity(plane: plane), y: calcLandingWeight(plane: plane))
        
        if !p.contains(takeoffCogPoint) && !p.contains(landingCogPoint) {
            throw FlightErrors.invalidCenterOfGravity
        } else if !p.contains(takeoffCogPoint){
            throw FlightErrors.invalidTakeoffCog
        } else if !p.contains(landingCogPoint) {
            throw FlightErrors.invalidLandingCog
        }
    }
    
}

extension Flight {
    func getIntersectionOfLines(line1: (a: CGPoint, b: CGPoint), line2: (a: CGPoint, b: CGPoint)) -> CGPoint {
        let distance = (line1.b.x - line1.a.x) * (line2.b.y - line2.a.y) - (line1.b.y - line1.a.y) * (line2.b.x - line2.a.x)
        if distance == 0 {
            print("error, parallel lines")
            return CGPoint.zero
        }
        
        let u = ((line2.a.x - line1.a.x) * (line2.b.y - line2.a.y) - (line2.a.y - line1.a.y) * (line2.b.x - line2.a.x)) / distance
        let v = ((line2.a.x - line1.a.x) * (line1.b.y - line1.a.y) - (line2.a.y - line1.a.y) * (line1.b.x - line1.a.x)) / distance
        
        if (u < 0.0 || u > 1.0) {
            print("error, intersection not inside line1")
            return CGPoint.zero
        }
        if (v < 0.0 || v > 1.0) {
            print("error, intersection not inside line2")
            return CGPoint.zero
        }
        
        return CGPoint(x: (line1.a.x + u * (line1.b.x - line1.a.x)), y: (line1.a.y + u * (line1.b.y - line1.a.y)))
    }
}
