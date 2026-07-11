//
//  ContentView.swift
//  PadelHits
//
//  Created by Cristian Di Cillo on 26/03/26.

import SwiftUI
struct ContentView: View {
    @ObservedObject var manager = ConnectivityManager.shared
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
                StatCard(titolo: "Sessioni", valore: Float(manager.storicoSessioni.count))
                Spacer()
                StatCard(titolo: "Colpi tot.", valore: Float(manager.colpiTotali))
                Spacer()
                StatCard(titolo: "Ore giocate", valore: manager.oreGiocateTotali)
            }
            .padding(.horizontal)
            .padding(.vertical)
            
            ScrollView {
                VStack (spacing: 20) {
                    if (manager.storicoSessioni.isEmpty) {
                        Text("Nessuna sessione ancora registrata")
                    } else {
                        ForEach(manager.storicoSessioni) { sessione in
                            SessionCard(
                                titolo: "Session Padel", dataOra: sessione.orario, durata: String(sessione.durata) + " min", colpiDritto: sessione.dritto, colpiRovescio: sessione.rovescio
                            )
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

#Preview {
    ContentView()
}
