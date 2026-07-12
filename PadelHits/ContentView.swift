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
    @Query var storicoSessioniDB: [SessionePadel]
    // Questa variabile calcola le ore totali automaticamente
    var oreGiocateTotali: Float {
        // Raccogliamo tutti i secondi dalle sessioni nello storico
        let secondiComplessivi = storicoSessioniDB.reduce(0.0) { $0 + $1.secondiTotali } //reduce somma i valori all'intenro dell'array velocemente
        // Trasformiamo in ore (3600 secondi = 1 ora) e restituiamo un Float
        return Float(secondiComplessivi / 3600.0)
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
                StatCard(titolo: "Sessioni", valore: Float(storicoSessioniDB.count))
                Spacer()
                StatCard(titolo: "Colpi tot.", valore: Float(manager.colpiTotali))
                Spacer()
                StatCard(titolo: "Ore giocate", valore: oreGiocateTotali)
            }
            .padding(.horizontal)
            .padding(.vertical)
            
            ScrollView {
                VStack (spacing: 20) {
                    if (storicoSessioniDB.isEmpty) {
                        Text("Nessuna sessione ancora registrata")
                    } else {
                        ForEach(storicoSessioniDB) { sessione in
                            SessionCard(
                                titolo: "Session Padel", dataOra: sessione.orario, durata: sessione.durata, colpiDritto: sessione.dritto, colpiRovescio: sessione.rovescio
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
        
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
