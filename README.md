# StackKite

Manage your local development services — Homebrew services, PHP, Node.js, MySQL, PostgreSQL, Redis, MongoDB, Nginx, and Composer — from a single native macOS app.

## Features

- Start, stop, restart, and monitor the status of Homebrew-managed services
- Per-service detail views with version and installation info
- Install and manage PHP toolbox (PHP, Node.js, Composer)
- Native SwiftUI interface

## Requirements

- macOS 13 or later
- [Homebrew](https://brew.sh)

## Build

Open `StackKite.xcodeproj` in Xcode and run, or:

```sh
xcodebuild -project StackKite.xcodeproj -scheme StackKite build
```

## Architecture

- `App/` – Application entry point, AppDelegate, and root content view
- `Core/` – Domain layer: models, services, Homebrew & shell integration, install manager
- `Features/` – Feature views (Dashboard, MongoDB, MySQL, Nginx, NodeJS, PHP, PostgreSQL, Redis, Install)
- `Shared/` – Shared UI components (sidebar, rows, status badges)
- `Resources/` – Assets

## License

See the [LICENSE](LICENSE) file.