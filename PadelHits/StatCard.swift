//
//  StatCard.swift
//  PadelHits
//
//  Created by Cristian Di Cillo on 31/03/26.
//
import SwiftUI

struct StatCard: View {
    var titolo: String
    var valore: Int = 0
    // Se presente, viene mostrato al posto del valore numerico (es. "1h 23m")
    var valoreTesto: String? = nil
    var body: some View {
        VStack (){
            Text(titolo)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)

            // Il valore testuale ha priorità sulla visualizzazione numerica
            if let valoreTesto {
                Text(valoreTesto)
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
            } else {
                Text(valore, format: .number)
                    .font(.system(size: 24))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(width: 90, height: 90)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}
