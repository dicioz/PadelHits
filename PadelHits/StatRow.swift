//
//  StatRow.swift
//  PadelHits
//
//  Created by Cristian Di Cillo on 09/04/26.
//
import SwiftUI

struct StatRow: View {
    var etichetta: String
    var valore: Int
    var massimo: Int
    var colore: Color
    
    var body: some View {
        HStack (spacing: 12) {
            Text(etichetta)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(width: 75, alignment: .leading)
            
            GeometryReader{ geometry in
                ZStack(alignment: .leading) {
                    //sfondo della barra
                    Capsule()
                        .fill(Color.black.opacity(0.4))
                        .frame(height: 10)
                    
                    //barra colorata calcolata in percetnuale
                    Capsule()
                        .fill(colore)
                        .frame(width: calcolaLarghezza(larghezzaTotale: geometry.size.width), height: 10)
                }
                .frame(height: geometry.size.height, alignment: .center)
            }
            .frame(height: 10)
            
            Text("\(valore)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 30, alignment: .trailing)
        }
    }
    private func calcolaLarghezza(larghezzaTotale: CGFloat) -> CGFloat {
        guard massimo != 0 else { return 0 }
        let percentuale = CGFloat(valore) / CGFloat(massimo)
        return percentuale * larghezzaTotale
    }
}
