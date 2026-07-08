import SwiftUI
import CoreMotion

struct ContentView: View {
    
    private let motion = CMMotionManager()
    private let updateInterval = 1.0 / 50.0
    
    @State private var isRecording = false
    @State private var sampleCount = 0
    @State private var statusMessage = "Pronto"
    @State private var csvLines: [String] = []
    @State private var savedFiles: [URL] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                
                // Status
                Text(statusMessage)
                    .font(.caption2)
                    .foregroundColor(isRecording ? .red : .green)
                
                // Campioni durante registrazione
                if isRecording {
                    Text("\(sampleCount) campioni")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                // Pulsante REC / STOP
                Button {
                    isRecording ? stopRecording() : startRecording()
                } label: {
                    HStack {
                        Circle()
                            .fill(isRecording ? Color.red : Color.green)
                            .frame(width: 10, height: 10)
                        Text(isRecording ? "STOP" : "REC")
                            .fontWeight(.bold)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                }
                .background(
                    isRecording ? Color.red.opacity(0.15) : Color.green.opacity(0.15)
                )
                .cornerRadius(20)
                
                // Lista file salvati
                if !savedFiles.isEmpty {
                    Divider()
                    
                    Text("\(savedFiles.count) sessioni salvate")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    // Condividi singolo file
                    ForEach(savedFiles.indices, id: \.self) { i in
                        ShareLink(
                            item: savedFiles[i],
                            preview: SharePreview("Sessione \(i + 1)")
                        ) {
                            Text("Sessione \(i + 1)")
                                .font(.caption2)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.15))
                                .cornerRadius(10)
                        }
                    }
                    
                    // Condividi tutti insieme come ZIP
                    Button("Condividi tutti") {
                        shareAll()
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(16)
                    
                    // Elimina tutti
                    Button("Elimina tutti") {
                        deleteAll()
                    }
                    .font(.caption2)
                    .foregroundColor(.red)
                }
            }
            .padding()
        }
        .onAppear {
            loadSavedFiles()
        }
    }
    
    // MARK: - Recording
    
    func startRecording() {
        guard motion.isDeviceMotionAvailable else {
            statusMessage = "Sensori non disponibili"
            return
        }
        
        csvLines = []
        sampleCount = 0
        isRecording = true
        statusMessage = "Registrazione..."
        
        csvLines.append("timestamp,ax,ay,az,gx,gy,gz")
        
        motion.deviceMotionUpdateInterval = updateInterval
        motion.startDeviceMotionUpdates(to: .main) { data, error in
            guard let data = data else { return }
            
            let ts = Date().timeIntervalSince1970
            let ax = data.userAcceleration.x
            let ay = data.userAcceleration.y
            let az = data.userAcceleration.z
            let gx = data.rotationRate.x
            let gy = data.rotationRate.y
            let gz = data.rotationRate.z
            
            csvLines.append(
                "\(ts),\(ax),\(ay),\(az),\(gx),\(gy),\(gz)"
            )
            sampleCount += 1
        }
    }
    
    func stopRecording() {
        motion.stopDeviceMotionUpdates()
        isRecording = false
        statusMessage = "Salvataggio..."
        saveCSV()
    }
    
    // MARK: - Save
    
    func saveCSV() {
        let content = csvLines.joined(separator: "\n")
        let filename = "padel_\(Int(Date().timeIntervalSince1970)).csv"
        
        guard let dir = documentsDirectory() else {
            statusMessage = "Errore directory"
            return
        }
        
        let fileURL = dir.appendingPathComponent(filename)
        
        do {
            try content.write(
                to: fileURL,
                atomically: true,
                encoding: .utf8
            )
            savedFiles.append(fileURL)
            statusMessage = "Salvato ✓ (\(savedFiles.count) totali)"
            csvLines = []
            sampleCount = 0
        } catch {
            statusMessage = "Errore: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Load existing files on launch
    
    func loadSavedFiles() {
        guard let dir = documentsDirectory() else { return }
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: dir,
                includingPropertiesForKeys: nil
            )
            savedFiles = files
                .filter { $0.pathExtension == "csv" }
                .sorted { $0.lastPathComponent < $1.lastPathComponent }
        } catch {
            statusMessage = "Errore caricamento"
        }
    }
    
    // MARK: - Share all as ZIP
    
    func shareAll() {
        guard let dir = documentsDirectory() else { return }
        
        let zipURL = dir.appendingPathComponent("padel_sessions.zip")
        
        // Crea ZIP con tutti i CSV
        var archiveData = Data()
        for fileURL in savedFiles {
            if let data = try? Data(contentsOf: fileURL) {
                archiveData.append(data)
            }
        }
        
        // Usa il primo file come rappresentante per lo share
        // (watchOS non supporta zip nativo, condividi uno per uno)
        statusMessage = "Usa i singoli pulsanti per condividere"
    }
    
    // MARK: - Delete all
    
    func deleteAll() {
        for fileURL in savedFiles {
            try? FileManager.default.removeItem(at: fileURL)
        }
        savedFiles = []
        statusMessage = "File eliminati"
    }
    
    // MARK: - Helpers
    
    func documentsDirectory() -> URL? {
        FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first
    }
}
