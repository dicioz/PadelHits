//
//  ContentView.swift
//  PadelHits
//
//  Created by Cristian Di Cillo on 26/03/26.
//

import SwiftUI
struct ContentView: View {
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
                StatCard(titolo: "Sessioni", valore: 0)
                Spacer()
                StatCard(titolo: "Colpi tot.", valore: 312)
                Spacer()
                StatCard(titolo: "Ore giocate", valore: 3.2)
            }
            .padding(.horizontal)
            .padding(.vertical)
            
            ScrollView {
                VStack (spacing: 20) {
                    SessionCard(
                        titolo: "Sessione 1",
                        dataOra: "Oggi 9.30",
                        durata: "40 min",
                        colpiDritto: 54,
                        colpiRovescio: 30,
                        colpiVibora: 20
                    )
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
