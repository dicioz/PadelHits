//
//  ContentView.swift
//  PadelHits
//
//  Created by Cristian Di Cillo on 26/03/26.

import SwiftUI
import SwiftData
struct ContentView: View {
    @ObservedObject var manager = ConnectivityManager.shared
    @Environment(\.modelContext) private var context
    @Query var storicoSessioniDB: [SessionePadel] // ottengo tuttti i record si sessionPadel salvati, se db cambia, ui si aggiorna
    var colpiTotali: Int {
        storicoSessioniDB.reduce(0) { totaleParziale, sessione in
                totaleParziale + sessione.colpiTotali
        }
    }
    var tempoGiocatoFormattato: String {
        // Raccogliamo tutti i secondi dalle sessioni nello storico
        let secondiComplessivi = storicoSessioniDB.reduce(0.0) { $0 + $1.secondiTotali } //reduce somma i valori all'intenro dell'array velocemente
        // Convertiamo in interi (coerente con il resto del codice che usa Int())
        let secondiTotali = Int(secondiComplessivi)

        if secondiTotali >= 3600 {
            // Da 1 ora in su: mostriamo ore e minuti (es. "1h 23m")
            let ore = secondiTotali / 3600
            let minuti = (secondiTotali % 3600) / 60
            return "\(ore)h \(minuti)m"
        } else if secondiTotali >= 60 {
            // Da 1 minuto a meno di 1 ora: minuti e secondi (es. "23m 45s")
            let minuti = secondiTotali / 60
            let secondi = secondiTotali % 60
            return "\(minuti)m \(secondi)s"
        } else {
            // Meno di 1 minuto: solo secondi (es. "45s")
            return "\(secondiTotali)s"
        }
    }
    
    
    var body: some View {
        VStack (alignment: .leading, spacing: 4){
            VStack (alignment: .leading, spacing: 4){
                Text("Padel Ace")
                    .font(.title)
                    .padding(.horizontal, 16)
                    .fontWeight(.bold)
                Text("Le tue sessioni")
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .fontWeight(.medium)
            }
            
            HStack (alignment: .center, spacing: 15){
                StatCard(titolo: "Sessioni", valore: storicoSessioniDB.count)
                Spacer()
                StatCard(titolo: "Colpi tot.", valore: colpiTotali)
                Spacer()
                StatCard(titolo: "Minuti giocati", valoreTesto: tempoGiocatoFormattato)
            }
            .padding(.horizontal)
            .padding(.vertical)
            
            ScrollView {
                VStack (spacing: 20) {
                    if (storicoSessioniDB.isEmpty) {
                        Text("Nessuna sessione ancora registrata")
                    } else {
                        ForEach(storicoSessioniDB) { sessione in
                            // per evitare che l'app vada in crash se i colpi totali sono 0
                            let colpiTot = sessione.colpiTotali > 0 ? Double(sessione.colpiTotali) : 1.0

                            // Ora la divisione avviene tra due Double (es. 15.0 / 30.0 = 0.5)
                            let percDritti = Int((Double(sessione.dritto) / colpiTot) * 100)
                            let percRovesci = sessione.colpiTotali > 0 ? (100 - percDritti) : 0

                            SessionCard(
                                titolo: "Session Padel",
                                dataOra: sessione.orario,
                                durata: sessione.durata,
                                colpiDritto: percDritti,
                                colpiRovescio: percRovesci
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        // quando viene creato un nuovo oggetto sessionPadel questo viene aggiunto nel db
        .onChange(of: manager.sessioneDaSalvare) { vecchiaSessione, nuovaSessione in
            if let sessione = nuovaSessione {
                // salva nel db
                context.insert(sessione)
                
                // resetta la flag per avvisare quando c'è una nuova sessione
                manager.sessioneDaSalvare = nil
            }
        }
    }
}

#Preview {
    ContentView()
}
