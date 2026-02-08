# GT7 Companion

A Flutter application that displays real-time telemetry data from Gran Turismo 7 (GT7).

## Features

- Real-time display of GT7 telemetry data including:
  - Track information (time, laps, position)
  - Car data (throttle, RPM, speed, brake, gear, boost)
  - Engine data (temperature, pressure)
  - Tire data (temperature, speed, slip ratio)
  - Positioning and rotation data
- UDP communication with GT7 game
- Salsa20 decryption for secure data transmission
- Heartbeat mechanism to maintain connection with GT7
- Dealerships (legendary & used car marketplace cards)
- GT Auto (coming soon)
- Responsive UI layout for all screen sizes
- Cross-platform support (iOS, Android, macOS, Windows, Linux)

## Dev Requirements

- Flutter SDK
- Gran Turismo 7 game with telemetry enabled
- Same network connection between device running the app and PlayStation

## Setup

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd gt7_telemetry_flutter
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Connect your device or start an emulator

4. Run the application:
   ```bash
   flutter run
   ```

## Usage

1. Launch the GT7 game on your PlayStation
2. Enable telemetry in GT7 settings (if available)
3. Note your PlayStation's IP address
4. Launch the Flutter app
5. Enter your PlayStation's IP address in the input field
6. Tap "Connect" to start receiving telemetry data

## Configuration

The app will attempt to connect to GT7 on the default ports:
- Receive Port: 33740
- Send Port: 33739 (for heartbeat)

## Troubleshooting

- Ensure both devices are on the same network
- Check that the IP address is correct
- Verify that GT7 telemetry is enabled
- Make sure firewall settings allow UDP traffic on ports 33739 and 33740
- The application will automatically send heartbeat packets to maintain connection with GT7

## Architecture

The application follows a clean architecture pattern:

- `lib/services/` - Contains the UDP communication and telemetry services
- `lib/models/` - Contains the telemetry data model
- `lib/widgets/` - Contains the UI components
- `lib/utils/` - Contains utility functions (crypto, etc.)

## Technical Details

- Uses dart:io for UDP communication instead of external packages for better cross-platform compatibility
- Implements Salsa20 decryption algorithm for secure telemetry data
- Uses Provider for state management
- Responsive UI with scrolling for different screen sizes

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the ... uh will be here soon.