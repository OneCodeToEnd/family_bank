/// Agent 工具定义
class AgentTool {
  final String name;
  final String description;
  final Map<String, dynamic> parameters;
  final Future<String> Function(Map<String, dynamic>) execute;

  AgentTool({
    required this.name,
    required this.description,
    required this.parameters,
    required this.execute,
  });
}

/// 将工具列表转换为 OpenAI function calling 格式
List<Map<String, dynamic>> toolsToOpenAIFormat(List<AgentTool> tools) {
  return tools.map((tool) {
    return {
      'type': 'function',
      'function': {
        'name': tool.name,
        'description': tool.description,
        'parameters': tool.parameters,
      },
    };
  }).toList();
}
