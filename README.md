# Alps iOS SDK

Native Swift SDK for integrating the Alps customer support widget into iOS applications.

## Installation

### Swift Package Manager

Add the Alps SDK to your project using Swift Package Manager:

```swift
// File > Add Packages
https://github.com/tryalps/alps-ios-sdk
```

Select version `1.0.0` or later.

## Quick Start

### 1. Configure the SDK

In your `App` struct or `AppDelegate`:

```swift
import AlpsSDK

@main
struct MyApp: App {
    init() {
        Alps.configure(widgetKey: "YOUR_WIDGET_KEY")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

The launcher button will automatically appear on screen.

### 2. Identify Users (Optional)

After a user logs in, identify them to link conversations:

```swift
Alps.identify(name: "John Doe", email: "john@example.com")
```

### 3. Show/Hide the Panel

Programmatically control the chat panel:

```swift
// Show the chat panel
Alps.show()

// Hide the chat panel
Alps.hide()

// Clear user identity and logout
Alps.logout()
```

## Features

- **Launcher Button**: Floating circular button in the bottom-right corner
- **Home Tab**: Workspace branding, welcome message, and available agents
- **Messages Tab**: Conversation history and thread view
- **Answers Tab**: Knowledge base search and article browsing
- **Real-time Updates**: Pusher-powered message delivery
- **Pre-chat Form**: Collect visitor name and email before first message
- **Responsive Design**: Full-screen sheet modal with bottom sheet presentation

## Configuration

All configuration is done through the `Alps.configure()` method:

```swift
Alps.configure(
    widgetKey: "your_widget_key",
    userName: "John Doe",           // Optional
    userEmail: "john@example.com"   // Optional
)
```

## API Reference

### Alps

Main entry point for the SDK.

#### Methods

- `configure(widgetKey:userName:userEmail:)` — Initialize the SDK
- `show()` — Display the chat panel
- `hide()` — Close the chat panel
- `identify(name:email:)` — Set visitor identity
- `logout()` — Clear identity and close panel

## Requirements

- iOS 15.0+
- Swift 5.9+
- Xcode 15.0+

## Dependencies

- [PusherSwift](https://github.com/pusher/pusher-websocket-swift) — Real-time messaging

## License

Proprietary — © 2026 Alps
