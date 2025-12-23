import Foundation
import UIKit

extension ReaderDemoViewModel {
    func fetchToken() async {
        print("🚀 Starting fetchToken()")
        isConfiguring = true
        defer { isConfiguring = false }
        
        guard let url = URL(string: "https://apple-uat.mspayhub.com/token") else {
            addResult("❌ Invalid URL")
            return
        }
        print("🌐 URL valid: \(url.absoluteString)")

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
            
            if decoded.code == 0 {
                self.token = decoded.data.token
                print("✅ Token fetched: \(self.token ?? "nil")")
                addResult("✅ Token fetched successfully")
            } else {
                print("❌ API error message: \(decoded.msg)")
                addResult("❌ API error: \(decoded.msg)")
            }
        } catch {
            print("🔥 Exception: \(error.localizedDescription)")
            addResult("❌ Failed to fetch token: \(error.localizedDescription)")
        }
    }
    
    
    func shareLogs() {
        guard let fileURL = FileReaderLogger.logFileURL else { return }
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let root = scene.windows.first?.rootViewController {
            root.present(activityVC, animated: true)
        }
    }
}
