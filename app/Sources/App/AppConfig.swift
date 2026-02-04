import Foundation

struct AppConfig: Codable {
    let splitRatio: Double
    let diffView: DiffViewMode

    static let `default` = AppConfig(splitRatio: 0.3, diffView: .unified)
    static let shared: AppConfig = AppConfig.load()

    private static func load() -> AppConfig {
        guard let url = Bundle.main.url(forResource: "Config", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return .default
        }
        return config
    }
}
