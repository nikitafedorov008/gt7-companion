import 'dart:typed_data';
import 'dart:convert';
import 'package:pointycastle/export.dart';

class CryptoUtils {
  static const String _keyString = 'Simulator Interface Packet GT7 ver 0.0';
  static final Uint8List _key = utf8.encode(_keyString).sublist(0, 32);

  static Uint8List? decryptSalsa20(Uint8List encryptedData) {
    try {
      print('Starting decryption, data length: ${encryptedData.length}');

      // Extract IV from the data (located at offset 0x40 to 0x44)
      if (encryptedData.length < 0x44) {
        print('Data too short for IV extraction: ${encryptedData.length}');
        return null;
      }

      // Get the seed IV (4 bytes at 0x40)
      final oiv = Uint8List.fromList(encryptedData.skip(0x40).take(4).toList());
      final iv1 = _bytesToInt(oiv, 0);
      print('Extracted IV1: 0x${iv1.toRadixString(16)}');

      // Calculate IV2: Notice DEADBEAF, not DEADBEEF
      final iv2 = iv1 ^ 0xDEADBEAF;
      print('Calculated IV2: 0x${iv2.toRadixString(16)}');

      // Create the full 8-byte IV
      final ivBytes = Uint8List(8);
      ivBytes.setRange(0, 4, _intToBytes(iv2, 4));
      ivBytes.setRange(4, 8, _intToBytes(iv1, 4));

      // Create Salsa20 cipher
      final cipher = Salsa20Engine();
      final keyParam = KeyParameter(_key);
      final params = ParametersWithIV(keyParam, ivBytes);

      cipher.init(false, params); // false for decryption

      // Decrypt the data
      final decrypted = cipher.process(encryptedData);
      print('Decrypted data length: ${decrypted.length}');

      // Verify the magic number at the beginning (0x47375330)
      if (decrypted.length < 4) {
        print('Decrypted data too short for magic check: ${decrypted.length}');
        return null;
      }

      final magic = _bytesToInt(
        Uint8List.fromList(decrypted.take(4).toList()),
        0,
      );
      print('Magic number: 0x${magic.toRadixString(16)}, expected: 0x47375330');

      if (magic != 0x47375330) {
        print('Invalid magic number, returning null');
        return null; // Invalid packet
      }

      print('Decryption successful, returning data');
      return decrypted;
    } catch (e) {
      print('Decryption error: $e');
      return null;
    }
  }

  static int _bytesToInt(Uint8List bytes, int offset) {
    if (offset + 4 > bytes.length) {
      throw ArgumentError('Not enough bytes for integer conversion');
    }
    return (bytes[offset] & 0xFF) |
        ((bytes[offset + 1] & 0xFF) << 8) |
        ((bytes[offset + 2] & 0xFF) << 16) |
        ((bytes[offset + 3] & 0xFF) << 24);
  }

  static Uint8List _intToBytes(int value, int length) {
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = (value >> (i * 8)) & 0xFF;
    }
    return bytes;
  }
}
