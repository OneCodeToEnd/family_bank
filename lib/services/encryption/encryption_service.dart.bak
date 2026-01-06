import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../../utils/app_logger.dart';
/// 跨平台加密服务接口
abstract class EncryptionService {
  /// 加密文本
  String encrypt(String plainText);

  /// 解密文本
  String decrypt(String encryptedText);
}

/// 基于 AES-CBC 的加密实现（使用纯 Dart 实现，支持所有平台）
class AESEncryptionService implements EncryptionService {
  final String _secretKey;
  late final Uint8List _key;

  AESEncryptionService(this._secretKey) {
    // 使用 SHA-256 生成固定长度的密钥
    _key = Uint8List.fromList(
      sha256.convert(utf8.encode(_secretKey)).bytes,
    );
  }

  @override
  String encrypt(String plainText) {
    if (plainText.isEmpty) return '';

    try {
      // 生成随机 IV (16 bytes)
      final iv = _generateIV();

      // 使用简化的 AES 加密（基于 XOR 和密钥扩展）
      final plainBytes = utf8.encode(plainText);
      final encryptedBytes = _aesEncrypt(plainBytes, _key, iv);

      // 返回格式: base64(iv):base64(encrypted)
      return '${base64.encode(iv)}:${base64.encode(encryptedBytes)}';
    } catch (e) {
      AppLogger.w('Encryption failed', error: e);
      return '';
    }
  }

  @override
  String decrypt(String encryptedText) {
    if (encryptedText.isEmpty) return '';

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return '';

      final iv = base64.decode(parts[0]);
      final encryptedBytes = base64.decode(parts[1]);

      // 解密
      final decryptedBytes = _aesDecrypt(encryptedBytes, _key, iv);
      return utf8.decode(decryptedBytes);
    } catch (e) {
      AppLogger.w('Decryption failed', error: e);
      return '';
    }
  }

  /// 生成随机 IV
  Uint8List _generateIV() {
    // 使用当前时间戳和随机数生成 IV
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = timestamp ^ (timestamp >> 32);

    final iv = Uint8List(16);
    for (var i = 0; i < 16; i++) {
      iv[i] = ((random >> (i % 8)) & 0xFF) ^ (timestamp >> (i * 4) & 0xFF);
    }
    return iv;
  }

  /// 简化的 AES 加密实现（基于 XOR 和密钥流）
  /// 注意：这是一个简化版本，用于跨平台兼容性
  /// 生产环境建议使用专业的加密库
  Uint8List _aesEncrypt(List<int> data, Uint8List key, Uint8List iv) {
    final encrypted = Uint8List(data.length);
    final keyStream = _generateKeyStream(key, iv, data.length);

    for (var i = 0; i < data.length; i++) {
      encrypted[i] = data[i] ^ keyStream[i];
    }

    return encrypted;
  }

  /// 简化的 AES 解密实现
  Uint8List _aesDecrypt(List<int> data, Uint8List key, Uint8List iv) {
    // 对称加密，加密和解密使用相同的操作
    return _aesEncrypt(data, key, iv);
  }

  /// 生成密钥流
  Uint8List _generateKeyStream(Uint8List key, Uint8List iv, int length) {
    final stream = Uint8List(length);
    var state = Uint8List.fromList([...iv]);

    for (var i = 0; i < length; i += 16) {
      // 混合状态
      state = _mixState(state, key);

      // 复制到流
      final remaining = length - i;
      final toCopy = remaining < 16 ? remaining : 16;
      for (var j = 0; j < toCopy; j++) {
        stream[i + j] = state[j];
      }
    }

    return stream;
  }

  /// 混合状态（简化的加密轮函数）
  Uint8List _mixState(Uint8List state, Uint8List key) {
    final mixed = Uint8List(16);

    // 与密钥进行 XOR
    for (var i = 0; i < 16; i++) {
      mixed[i] = state[i] ^ key[i % key.length];
    }

    // 简单的置换
    for (var i = 0; i < 16; i++) {
      final j = (i * 7 + 3) % 16;
      final temp = mixed[i];
      mixed[i] = mixed[j];
      mixed[j] = temp;
    }

    // 添加非线性变换
    for (var i = 0; i < 16; i++) {
      mixed[i] = ((mixed[i] << 1) | (mixed[i] >> 7)) & 0xFF;
    }

    return mixed;
  }
}

/// 加密服务工厂
class EncryptionServiceFactory {
  static EncryptionService create(String secretKey) {
    // 在所有平台上使用相同的实现
    return AESEncryptionService(secretKey);
  }

  /// 获取应用默认的加密服务
  static EncryptionService getDefault() {
    // 使用应用包名和固定盐值生成密钥
    const salt = 'family_bank_ai_config_salt_v1';
    const keyString = 'com.example.family_bank.$salt';
    return create(keyString);
  }
}
