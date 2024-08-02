import Foundation

public protocol GenericConfig: Codable {}

public protocol ConfigLoader {
    associatedtype ConfigType: GenericConfig
    func loadConfig() async -> ConfigType?
}

public class AnyConfigLoader<T: GenericConfig>: ConfigLoader {
    private let _loadConfig: () async -> T?
    
    public init<Loader: ConfigLoader>(_ loader: Loader) where Loader.ConfigType == T {
        _loadConfig = loader.loadConfig
    }
    
    public func loadConfig() async -> T? {
        await _loadConfig()
    }
}

public struct ConfigReturnDto<ConfigType: GenericConfig>: Codable {
    public let data: ConfigReturnData<ConfigType>
}

public struct ConfigReturnData<ConfigType: GenericConfig>: Codable {
    public let config: ConfigType
}

public protocol ConfigCacheStrategy {
    func shouldLoadNewConfig(lastLoadedDate: Date?) -> Bool
}

public class ConfigService<T: GenericConfig> {
    private var remoteLoader: AnyConfigLoader<T>
    private var localLoader: AnyConfigLoader<T>
    private var cacheStrategy: ConfigCacheStrategy

    private var config: T?
    private var lastLoadedConfig: Date?

    public init<RemoteLoader: ConfigLoader, LocalLoader: ConfigLoader>(
        remoteLoader: RemoteLoader,
        localLoader: LocalLoader,
        cacheStrategy: ConfigCacheStrategy
    ) where RemoteLoader.ConfigType == T, LocalLoader.ConfigType == T {
        self.remoteLoader = AnyConfigLoader(remoteLoader)
        self.localLoader = AnyConfigLoader(localLoader)
        self.cacheStrategy = cacheStrategy
    }

    public func getConfig() async -> T? {
        if let lastLoadedConfig,
           !cacheStrategy.shouldLoadNewConfig(lastLoadedDate: lastLoadedConfig),
           let config
        {
            return config
        }

        if let remoteConfig = await remoteLoader.loadConfig() {
            lastLoadedConfig = Date()
            config = remoteConfig
            return remoteConfig
        }

        if let localConfig = await localLoader.loadConfig() {
            lastLoadedConfig = Date()
            config = localConfig
            return localConfig
        }

        return config
    }

    public static func resetForTesting<RemoteLoader: ConfigLoader, LocalLoader: ConfigLoader>(
        remoteLoader: RemoteLoader,
        localLoader: LocalLoader,
        cacheStrategy: ConfigCacheStrategy
    ) where RemoteLoader.ConfigType == T, LocalLoader.ConfigType == T {
    }
}

public class TimeBasedCacheStrategy: ConfigCacheStrategy {
    let cacheTimeInSeconds: Double

    public init(cacheTimeInSeconds: Double = 300) {
        self.cacheTimeInSeconds = cacheTimeInSeconds
    }

    public func shouldLoadNewConfig(lastLoadedDate: Date?) -> Bool {
        guard let lastLoadedDate = lastLoadedDate else { return true }
        return Date().timeIntervalSince(lastLoadedDate) > cacheTimeInSeconds
    }
}

public class RemoteConfigLoader<ConfigType: GenericConfig>: ConfigLoader {
    private let configApiUrl: String
    private let configApiToken: String
    private let endpoint: String

    public init(configApiUrl: String, configApiToken: String, endpoint: String) {
        self.configApiUrl = configApiUrl
        self.configApiToken = configApiToken
        self.endpoint = endpoint
    }

    public func loadConfig() async -> ConfigType? {
        guard let url = URL(string: "\(configApiUrl)/\(endpoint)") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(configApiToken)", forHTTPHeaderField: "Authorization")

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            if let response = response as? HTTPURLResponse, response.statusCode == 200 {
                let configReturn = try JSONDecoder().decode(ConfigReturnDto<ConfigType>.self, from: data)
                return configReturn.data.config
            } else {
                print("Error: Unexpected response")
                return nil
            }
        } catch {
            print("Error loading remote config: \(error.localizedDescription)")
            return nil
        }
    }
}

public class LocalConfigLoader<ConfigType: GenericConfig>: ConfigLoader {
    private let filename: String

    public init(filename: String) {
        self.filename = filename
    }

    public func loadConfig() async -> ConfigType? {
        return loadJSON(filename: filename)
    }

    private func loadJSON<DecodableType: Codable>(filename: String) -> DecodableType? {
        guard let path = Bundle.main.path(forResource: filename, ofType: "json") else {
            print("JSON file not found")
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path))
            let result = try JSONDecoder().decode(DecodableType.self, from: data)
            return result
        } catch {
            print("Error decoding JSON: \(error)")
            return nil
        }
    }
}
