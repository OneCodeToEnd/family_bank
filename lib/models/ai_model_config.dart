class AIModelConfig {
  final String id;
  final String name;
  final String provider;
  final String modelName;
  final String encryptedApiKey;
  final String? baseUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  AIModelConfig({
    required this.id,
    required this.name,
    required this.provider,
    required this.modelName,
    required this.encryptedApiKey,
    this.baseUrl,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'provider': provider,
      'model_name': modelName,
      'encrypted_api_key': encryptedApiKey,
      'base_url': baseUrl,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory AIModelConfig.fromMap(Map<String, dynamic> map) {
    return AIModelConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      provider: map['provider'] as String,
      modelName: map['model_name'] as String,
      encryptedApiKey: map['encrypted_api_key'] as String,
      baseUrl: map['base_url'] as String?,
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  AIModelConfig copyWith({
    String? id,
    String? name,
    String? provider,
    String? modelName,
    String? encryptedApiKey,
    String? baseUrl,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AIModelConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      provider: provider ?? this.provider,
      modelName: modelName ?? this.modelName,
      encryptedApiKey: encryptedApiKey ?? this.encryptedApiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
