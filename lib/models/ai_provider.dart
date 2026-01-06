/// AI 分类服务提供商枚举
enum AIProvider {
  deepseek('DeepSeek'),
  qwen('通义千问');

  const AIProvider(this.displayName);
  final String displayName;
}
