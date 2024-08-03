import Foundation

public struct JsonHelpers {
    public static let decoder = JSONDecoder()
    
    public static func loadJSON<T: Codable>(filename: String) -> T? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "json") else {
            print("JSON file not found")
            return nil
        }
        
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let result = try JsonHelpers.decoder.decode(T.self, from: data)
            return result
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
}
