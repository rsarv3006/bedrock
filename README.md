# Bedrock

## Reasons

I got tired of copying and pasting some of these services and functionality between my app projects. This library constitutes the bulk of the code that is reusable and might be reused in other and future projects.

## Usage

This project is built using dependency injection. Most dependencies have sensible defaults but the door is open to gettin' a little crazy with it.

This is how I implemented the networking service in BasketBuddy. I could also have made a separate init that doesn't need these dependencies passed in. The world is your oyster.
```swift
public extension Networking {
    static let shared = Networking(urlProvider: BasketBuddyUrlProvider(), dynamicTokenProvider: DynamicTokenProvider(configTokenProvider: ConfigTokenProvider(), userTokenProvider: UserTokenProvider()))
}
```

This is how I built the Config Service. Again, just my choice in the matter.
```swift
public extension ConfigService where T == Config {
    convenience init() {
        self.init(
            remoteLoader: RemoteConfigLoader(),
            localLoader: LocalConfigLoader(),
            cacheStrategy: TimeBasedCacheStrategy()
        )
    }
    
    static let shared = ConfigService.init()
}
```