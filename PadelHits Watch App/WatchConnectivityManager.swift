//
//  Untitled.swift
//  PadelHits
//
//  Created by Di Cillo, Cristian on 11/07/2026.
//

import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate {
    static let shared = WatchConnectivityManager()
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    // Funzione obbligatoria per conformarsi a WCSessionDelegate su watchOS
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        print("WCSession su Watch attivata con stato: \(activationState.rawValue)")
    }
}
