//
//  WorkoutSessionManager.swift
//  PadelHits Watch App
//
//  Gestisce una HKWorkoutSession al solo scopo di ottenere "extended runtime":
//  finché la sessione di allenamento è attiva, watchOS tiene l'app in esecuzione
//  anche a schermo spento / Always-On Display, quindi CMMotionManager continua a
//  consegnare i campioni. Non registra dati sanitari nel database Salute: serve
//  solo a mantenere vivi i sensori durante la registrazione.
//

import Foundation
import HealthKit

class WorkoutSessionManager: NSObject, HKWorkoutSessionDelegate {
    static let shared = WorkoutSessionManager()

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?

    // Chiede il permesso HealthKit una sola volta. Va invocata all'avvio dell'app
    // così che il prompt appaia prima della prima registrazione.
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        // Non condividiamo/leggiamo dati specifici: bastano i permessi minimi per
        // poter avviare una workout session.
        let typesToShare: Set = [HKObjectType.workoutType()]
        healthStore.requestAuthorization(toShare: typesToShare, read: []) { success, error in
            if let error = error {
                print("Autorizzazione HealthKit fallita: \(error.localizedDescription)")
            }
        }
    }

    // Avvia la workout session per ottenere l'extended runtime.
    func start() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        guard session == nil else { return }

        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .tennis // il padel non ha un tipo dedicato: tennis è il più vicino
        configuration.locationType = .outdoor

        do {
            let newSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            newSession.delegate = self
            session = newSession
            newSession.startActivity(with: Date())
        } catch {
            print("Impossibile avviare la HKWorkoutSession: \(error.localizedDescription)")
        }
    }

    // Termina la workout session quando la registrazione si ferma.
    func stop() {
        guard let session = session else { return }
        session.end()
        self.session = nil
    }

    // MARK: - HKWorkoutSessionDelegate (metodi obbligatori)

    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {}

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("HKWorkoutSession errore: \(error.localizedDescription)")
    }
}
