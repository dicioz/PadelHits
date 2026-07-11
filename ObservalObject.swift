//
//  ObservalObject.swift
//  PadelHits
//
//  Created by Di Cillo, Cristian on 11/07/2026.
//


import Foundation
import WatchConnectivity
import Combine
import WatchConnectivity
import CoreML

class ConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = ConnectivityManager()
    
    // Questa variabile conterrà la sessione ricevuta e notificherà SwiftUI
    @Published var ultimaSessioneRicevuta: [String: Any]?
    @Published var conteggioColpi: [String: Int] = [:]
    @Published var colpiTotali: Int = 0
    @Published var storicoSessioni: [SessionePadel] = []
    // Questa variabile calcola le ore totali automaticamente
    var oreGiocateTotali: Float {
        // Raccogliamo tutti i secondi dalle sessioni nello storico
        let secondiComplessivi = storicoSessioni.reduce(0.0) { $0 + $1.secondiTotali } //reduce somma i valori all'intenro dell'array velocemente
        // Trasformiamo in ore (3600 secondi = 1 ora) e restituiamo un Float
        return Float(secondiComplessivi / 3600.0)
    }
    
    override init() {
        super.init()
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    // MARK: - Helper Core ML
        // Questa funzione trasforma i nostri normali array in quelli richiesti dall'IA
        private func creaMultiArray(da array: [Double]) -> MLMultiArray? {
            guard let multiArray = try? MLMultiArray(shape: [100], dataType: .double) else { return nil }
            for (indice, valore) in array.enumerated() {
                multiArray[indice] = NSNumber(value: valore)
            }
            return multiArray
        }
    
    // MARK: - Ricezione Dati su iPhone
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        // I dati arrivano in background. Dobbiamo aggiornare la UI sul thread principale (Main Thread)
        DispatchQueue.main.async {
            self.ultimaSessioneRicevuta = userInfo
            print("Nuovi dati ricevuti e pubblicati per SwiftUI: \(userInfo)")
        }
    }
    
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
            print("Un nuovo file CSV è arrivato dal Watch!")
            
            let urlTemporaneo = file.fileURL
            
            guard let dirIphone = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Impossibile trovare la cartella Documents su iPhone")
                return
            }
            
            let nomeFile = urlTemporaneo.lastPathComponent
            let urlDestinazione = dirIphone.appendingPathComponent(nomeFile)
            
            do {
                try FileManager.default.moveItem(at: urlTemporaneo, to: urlDestinazione)
                print("File salvato con successo su iPhone in: \(urlDestinazione.path)")
                
                var statoMemoria = try? MLMultiArray(shape: [400], dataType: .double)
                var bloccoAx = [Double](); var bloccoAy = [Double](); var bloccoAz = [Double]()
                var bloccoGx = [Double](); var bloccoGy = [Double](); var bloccoGz = [Double]()
                
                let modello = try PadelhitsModel(configuration: MLModelConfiguration())
                let contenutoCompleto = try String(contentsOf: urlDestinazione, encoding: .utf8)
                let righe = contenutoCompleto.components(separatedBy: "\n")
                
                // Estrazione dell'orario dal nome del file
                let soloNumeri = nomeFile.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
                var orarioFormattato = "Orario sconosciuto"
                var durataFormattata = "-"
                var oreGiocate: Float = 0
                var durataInSecondi: Double = 0.0
                if let timestampFine = Double(soloNumeri) {
                    let data = Date(timeIntervalSince1970: timestampFine)
                    let formatter = DateFormatter()
                    formatter.dateFormat = "dd/MM/yy HH:mm"
                    orarioFormattato = formatter.string(from: data)
                    if let timestampInizio = file.metadata?["inizioSessione"] as? Double {
                        // Calcoliamo la differenza in secondi e la trasformiamo in minuti
                        let secondiTrascorsi = timestampFine - timestampInizio
                        let minutiTrascorsi = Int(secondiTrascorsi / 60)
                        durataInSecondi = secondiTrascorsi
                        // Se è durata meno di un minuto, mostriamo i secondi per precisione
                        if minutiTrascorsi == 0 {
                            durataFormattata = "\(Int(secondiTrascorsi)) sec"
                        } else {
                            durataFormattata = "\(minutiTrascorsi) min"
                        }
                    }
                }
                
                // Contatori locali allineati alla tua SessionCard
                var drittoLocali = 0
                var rovescioLocali = 0
                var totaliLocali = 0
                
                for i in 1..<righe.count {
                    let rigaCorrente = righe[i]
                    if rigaCorrente.isEmpty { continue }
                    
                    let colonne = rigaCorrente.split(separator: ",")
                    if colonne.count >= 7 {
                        bloccoAx.append(Double(colonne[1]) ?? 0.0)
                        bloccoAy.append(Double(colonne[2]) ?? 0.0)
                        bloccoAz.append(Double(colonne[3]) ?? 0.0)
                        bloccoGx.append(Double(colonne[4]) ?? 0.0)
                        bloccoGy.append(Double(colonne[5]) ?? 0.0)
                        bloccoGz.append(Double(colonne[6]) ?? 0.0)
                    }
                    
                    if bloccoAx.count == 100 {
                        guard let mlAx = creaMultiArray(da: bloccoAx), let mlAy = creaMultiArray(da: bloccoAy),
                              let mlAz = creaMultiArray(da: bloccoAz), let mlGx = creaMultiArray(da: bloccoGx),
                              let mlGy = creaMultiArray(da: bloccoGy), let mlGz = creaMultiArray(da: bloccoGz) else {
                            continue
                        }
                        
                        let predizione = try modello.prediction(ax: mlAx, ay: mlAy, az: mlAz, gx: mlGx, gy: mlGy, gz: mlGz, stateIn: statoMemoria!)
                        statoMemoria = predizione.stateOut
                        let colpoRilevato = predizione.label
                        
                        print("🎾 PREDIZIONE IA: \(colpoRilevato)")
                        
                        if colpoRilevato == "Dritto" { drittoLocali += 1 }
                        else if colpoRilevato == "Rovescio" { rovescioLocali += 1 }
                        totaliLocali += 1
                        
                        DispatchQueue.main.async {
                            self.conteggioColpi[colpoRilevato, default: 0] += 1
                            self.colpiTotali += 1
                        }
                        
                        bloccoAx.removeAll(); bloccoAy.removeAll(); bloccoAz.removeAll()
                        bloccoGx.removeAll(); bloccoGy.removeAll(); bloccoGz.removeAll()
                    }
                }
                
                // Salvataggio nello storico usando il modello dati
                DispatchQueue.main.async {
                    let nuovaSessione = SessionePadel(
                        orario: orarioFormattato,
                        colpiTotali: totaliLocali,
                        dritto: drittoLocali,
                        rovescio: rovescioLocali,
                        durata: durataFormattata,
                        secondiTotali: durataInSecondi
                    )
                    self.storicoSessioni.insert(nuovaSessione, at: 0)
                }
                
            } catch {
                print("Errore durante lo spostamento o l'elaborazione del file: \(error.localizedDescription)")
            }
        }
    
    // Metodo per svuotare i dati una volta letti o salvati, se necessario
    func resettaSessione() {
        self.ultimaSessioneRicevuta = nil
    }
    
    
    // MARK: - Delegati Obbligatori
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif
}

// MARK: - Funzione a parte

struct SessionePadel: Identifiable {
    let id = UUID()
    let orario: String
    let colpiTotali: Int
    let dritto: Int
    let rovescio: Int
    let durata: String
    let secondiTotali: Double
}
