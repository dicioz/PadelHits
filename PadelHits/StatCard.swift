//
//  StatCard.swift
//  PadelHits
//
//  Created by Cristian Di Cillo on 31/03/26.
//
import SwiftUI

struct StatCard: View {
    var titolo: String
    var valore: Float = 0
    var body: some View {
        VStack (){
            Text(titolo)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            
            Text(valore, format: .number)
                .font(.system(size: 24))
                .fontWeight(.bold)
                .multilineTextAlignment(.leading)
        }
        .frame(width: 90, height: 90)
        .background(Color.gray.opacity(0.15))
        .cornerRadius(12)
    }
}
