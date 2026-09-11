import SwiftUI

struct SessionCard: View {
    var titolo: String
    var dataOra: String
    var durata: String
    var colpiDritto: Int
    var colpiRovescio: Int
    // var colpiVibora: Int
    
    // calcola il colpo con il valore massimo per proporzionare le barre
    //private var maxColpi: Int {
      //  max(colpiDritto, colpiRovescio)
    //}
    
    var body: some View {
        VStack (spacing: 24) {
            HStack (alignment: .top) {
                VStack (alignment: .leading) {
                    Text(titolo)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                    Text(dataOra)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }
                Spacer()
                
                Text(durata)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Capsule())
            }
            VStack (spacing: 16){
                StatRow(etichetta: "Dritto", valore: colpiDritto, massimo: 100, colore: .blue)
                StatRow(etichetta: "Rovescio", valore: colpiRovescio, massimo: 100, colore: .green)
                //StatRow(etichetta: "Vibora", valore: colpiVibora, massimo: maxColpi, colore: .orange)
            }
        }
        .padding(20)
        .background(Color(UIColor.darkGray).opacity(0.8))
        .cornerRadius(20)
    }
}
