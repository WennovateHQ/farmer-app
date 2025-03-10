# FreshFarmily Farmer App

A Flutter mobile application for farmers to manage their products, inventory, and handle orders from consumers.

## Features

- Manage farm profile and product catalog
- Update product availability and pricing in real-time
- Track inventory and harvest schedules
- Receive and process customer orders
- Coordinate with delivery drivers
- View sales analytics and reports
- Manage promotional offers and discounts
- Schedule product availability based on harvest cycles

## Getting Started

### Prerequisites

- Flutter SDK (2.10.0 or higher)
- Dart SDK (2.16.0 or higher)
- Android Studio / VS Code
- Android SDK (for Android) / Xcode (for iOS)

### Installation

1. Clone this repository
2. Navigate to the project directory
3. Install dependencies:
```bash
flutter pub get
```
4. Run the app:
```bash
flutter run
```

## Architecture

This app follows a layered architecture:

- **Presentation Layer**: UI components and screens
- **Business Logic Layer**: Services, state management, and business rules
- **Data Layer**: API clients, repositories, and local storage
- **Shared Library**: Reusable components shared across multiple FreshFarmily apps

## Dependencies

- **State Management**: Flutter Bloc/Provider
- **Networking**: Dio for API calls
- **Local Storage**: Shared Preferences, SQLite
- **Authentication**: JWT authentication with role-based permissions
- **Real-time Updates**: WebSockets for order notifications
- **Charts & Analytics**: FL Chart for sales visualization

## Related Repositories

- [FreshFarmily Backend](https://github.com/freshfarmily/backend)
- [FreshFarmily Consumer App](https://github.com/freshfarmily/consumer-app)
- [FreshFarmily Driver App](https://github.com/freshfarmily/driver-app)
- [FreshFarmily Shared Library](https://github.com/freshfarmily/shared-library)
