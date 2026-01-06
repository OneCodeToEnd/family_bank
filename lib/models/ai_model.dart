/// AI 模型信息
class AIModel {
  final String id; // 模型ID
  final String name; // 显示名称
  final String? description; // 描述
  final double? inputPrice; // 输入价格（每千tokens）
  final double? outputPrice; // 输出价格（每千tokens）

  const AIModel({
    required this.id,
    required this.name,
    this.description,
    this.inputPrice,
    this.outputPrice,
  });

  factory AIModel.fromJson(Map<String, dynamic> json) {
    return AIModel(
      id: json['id'] as String,
      name: json['name'] as String? ?? json['id'] as String,
      description: json['description'] as String?,
      inputPrice: (json['input_price'] as num?)?.toDouble(),
      outputPrice: (json['output_price'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'input_price': inputPrice,
      'output_price': outputPrice,
    };
  }

  @override
  String toString() {
    return 'AIModel(id: $id, name: $name)';
  }
}
