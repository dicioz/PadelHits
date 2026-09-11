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
    var minutiGiocatiTotali: Int {
        // Raccogliamo tutti i secondi dalle sessioni nello storico
        let secondiComplessivi = storicoSessioniDB.reduce(0.0) { $0 + $1.secondiTotali } //reduce somma i valori all'intenro dell'array velocemente
        // Trasformiamo in ore (3600 secondi = 1 ora) e restituiamo un Float
        return Int(secondiComplessivi / 60)
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
                StatCard(titolo: "Minuti giocati", valore: minutiGiocatiTotali)
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
