class AIModelConstants {
  // Provider constants
  static const String providerDeepSeek = 'deepseek';
  static const String providerQwen = 'qwen';
  static const String providerOpenAI = 'openai';
  static const String providerCustom = 'custom';

  // DeepSeek presets
  static const String deepSeekDefaultModel = 'deepseek-chat';
  static const String deepSeekDefaultBaseUrl = 'https://api.deepseek.com';

  // Qwen presets
  static const String qwenDefaultModel = 'qwen-turbo';
  static const String qwenDefaultBaseUrl =
      'https://dashscope.aliyuncs.com/compatible-mode/v1';

  // OpenAI presets
  static const String openAIDefaultModel = 'gpt-3.5-turbo';
  static const String openAIDefaultBaseUrl = 'https://api.openai.com/v1';

  // Provider display names
  static const Map<String, String> providerDisplayNames = {
    providerDeepSeek: 'DeepSeek',
    providerQwen: 'Qwen',
    providerOpenAI: 'OpenAI',
    providerCustom: 'Custom',
  };

  // Get provider display name
  static String getProviderDisplayName(String provider) {
    return providerDisplayNames[provider] ?? provider;
  }

  // Get default base URL
  static String? getDefaultBaseUrl(String provider) {
    switch (provider) {
      case providerDeepSeek:
        return deepSeekDefaultBaseUrl;
      case providerQwen:
        return qwenDefaultBaseUrl;
      case providerOpenAI:
        return openAIDefaultBaseUrl;
      default:
        return null;
    }
  }

  // Get default model name
  static String? getDefaultModelName(String provider) {
    switch (provider) {
      case providerDeepSeek:
        return deepSeekDefaultModel;
      case providerQwen:
        return qwenDefaultModel;
      case providerOpenAI:
        return openAIDefaultModel;
      default:
        return null;
    }
  }

  // Preset models list
  static const List<Map<String, String>> presetModels = [
    {
      'provider': providerDeepSeek,
      'name': 'DeepSeek Chat',
      'modelName': deepSeekDefaultModel,
    },
    {
      'provider': providerQwen,
      'name': 'Qwen Turbo',
      'modelName': qwenDefaultModel,
    },
    {
      'provider': providerOpenAI,
      'name': 'GPT-3.5 Turbo',
      'modelName': openAIDefaultModel,
    },
  ];
}
