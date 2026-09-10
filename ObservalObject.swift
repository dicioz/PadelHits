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
import SwiftData

// aspetta i file dal watch in background, legge il csv e poi prepara i dati per la rete neurale, inferenza e prepara oggetto per il db
class ConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = ConnectivityManager() // garantisce una unica istanza condivida in tutt l'a'pp
    
    // Questa variabile conterrà la sessione ricevuta e notificherà SwiftUI
    @Published var ultimaSessioneRicevuta: [String: Any]?
    @Published var conteggioColpi: [String: Int] = [:]
    @Published var colpiTotali: Int = 0
    // @Published var storicoSessioni: [SessionePadel] = []
    @Published var sessioneDaSalvare: SessionePadel? = nil

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

    // avviata quando l'iphone ha scaricato il file dal watch
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
                let contenutoCompleto = try String(contentsOf: urlDestinazione, encoding: .utf8) // se file grande meglio usare InputStream
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
                    // estratto dai metadata associato al trasferimento
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

                // riempie blocchi per ogni asse (x, y...)
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
                    // quando lunghezza blocchi è 100 (2 sec a 50hz), array sono converitti in array nativi per coreml e si invoca il modelllo
                    if bloccoAx.count == 100 {
                        guard let mlAx = creaMultiArray(da: bloccoAx), let mlAy = creaMultiArray(da: bloccoAy),
                              let mlAz = creaMultiArray(da: bloccoAz), let mlGx = creaMultiArray(da: bloccoGx),
                              let mlGy = creaMultiArray(da: bloccoGy), let mlGz = creaMultiArray(da: bloccoGz) else {
                            continue
                        }
                        // utilizzo LSTM (long short term memory)
                        let predizione = try modello.prediction(ax: mlAx, ay: mlAy, az: mlAz, gx: mlGx, gy: mlGy, gz: mlGz, stateIn: statoMemoria!)
                        // stateout per avere una idea di quello che stava succedendo nella finestra attuale
                        statoMemoria = predizione.stateOut
                        let colpoRilevato = predizione.label
                        
                        //print("🎾 PREDIZIONE IA: \(colpoRilevato)")
                        let colpoPulito = colpoRilevato.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        if colpoRilevato == "dritto" { drittoLocali += 1 }
                        else if colpoRilevato == "rovescio" { rovescioLocali += 1 }
                        totaliLocali += 1
                        
                        DispatchQueue.main.async {
                            self.conteggioColpi[colpoRilevato, default: 0] += 1
                            self.colpiTotali += 1
                        }
                        // svuoto blocchi, in quanto non necessari per lstm
                        bloccoAx.removeAll(); bloccoAy.removeAll(); bloccoAz.removeAll()
                        bloccoGx.removeAll(); bloccoGy.removeAll(); bloccoGz.removeAll()
                    }
                }
                
                // Salvataggio nello storico usando il modello dati, si usa il thread principale in quanto le varibaili published possono essere modificate solo da quel thread
                DispatchQueue.main.async {
                    let nuovaSessione = SessionePadel(
                        orario: orarioFormattato,
                        colpiTotali: totaliLocali,
                        dritto: drittoLocali,
                        rovescio: rovescioLocali,
                        durata: durataFormattata,
                        secondiTotali: durataInSecondi
                    )
                    self.sessioneDaSalvare = nuovaSessione
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


/*struct SessionePadel: Identifiable {
    let id = UUID()
    let orario: String
    let colpiTotali: Int
    let dritto: Int
    let rovescio: Int
    let durata: String
    let secondiTotali: Double
}*/

@Model
class SessionePadel {
    // l'id lo genera automaticamente swiftdata
    var orario: String
    var colpiTotali: Int
    var dritto: Int
    var rovescio: Int
    var durata: String
    var secondiTotali: Double
    
    init(orario: String, colpiTotali: Int, dritto: Int, rovescio: Int, durata: String, secondiTotali: Double) {
        self.orario = orario
        self.colpiTotali = colpiTotali
        self.dritto = dritto
        self.rovescio = rovescio
        self.durata = durata
        self.secondiTotali = secondiTotali
    }
}


