import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_key.dart';
import 'gemini_prompt.dart';

class GeminiApi {

  static const String _activeModel = 'gemini-3.6-flash';

  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1beta/models/$_activeModel:generateContent';

  static int _currentKeyIndex = 0;

  static String get _activeKey {
    if (ApiKey.geminiApiKeys.isEmpty) {
      throw Exception("No API keys found in api_key.dart");
    }
    return ApiKey.geminiApiKeys[_currentKeyIndex % ApiKey.geminiApiKeys.length];
  }

  static void _rotateToNextKey() {
    _currentKeyIndex = (_currentKeyIndex + 1) % ApiKey.geminiApiKeys.length;
    debugPrint("🔄 Switched to Gemini API Key Index: $_currentKeyIndex");
  }

  /// টেক্সট থেকে ভ্যালিড JSON ব্লক এক্সট্র্যাক্ট করার নিরাপদ মেথড
  static String _extractJson(String rawText) {
    final cleaned = rawText.trim();
    if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
      return cleaned;
    }
    final match = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    if (match != null) {
      return match.group(0)!;
    }
    return cleaned;
  }

  // ============================================================
  // 1. MEAL ANALYSIS (Vision + Smart Key Rotation)
  // ============================================================
  static Future<String> analyzeMeal({
    required String base64Image,
    required String targetMeal,
    String mimeType = 'image/jpeg',
  }) async {
    final prompt = GeminiPrompt.mealAnalysisPrompt(targetMeal: targetMeal);

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {'mime_type': mimeType, 'data': base64Image},
            },
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.2,
        'responseMimeType': 'application/json',
      },
    });

    final uri = Uri.parse(_endpoint);
    final int totalKeys = ApiKey.geminiApiKeys.length;
    String lastError = "All Gemini API keys reached quota limits.";

    for (int attempt = 0; attempt < totalKeys; attempt++) {
      final keyToUse = _activeKey;

      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': keyToUse,
              },
              body: requestBody,
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates.first['content']?['parts'] as List?;
            for (final part in parts ?? []) {
              if (part is Map && part['text'] != null) {
                final text = part['text'].toString().trim();
                if (text.isNotEmpty) {
                  return _extractJson(text);
                }
              }
            }
          }
        }

        // 429 = Rate Limit/Quota Reached, 403 = Key permission issue
        if (response.statusCode == 429 || response.statusCode == 403) {
          debugPrint(
            "⚠️ Key [$_currentKeyIndex] exhausted (${response.statusCode}). Auto-rotating to next key...",
          );
          _rotateToNextKey();
          continue;
        }

        lastError = "Status ${response.statusCode}: ${response.body}";
        debugPrint("❌ Key [$_currentKeyIndex] returned error: $lastError");
        _rotateToNextKey();
      } on TimeoutException {
        debugPrint(
          "⏱️ Timeout on key [$_currentKeyIndex]. Rotating to next key...",
        );
        _rotateToNextKey();
      } catch (e) {
        lastError = e.toString();
        debugPrint("❌ Exception on key [$_currentKeyIndex]: $e");
        _rotateToNextKey();
      }
    }

    throw Exception(lastError);
  }

  // ============================================================
  // 2. NUTRIGO AI CHAT (Text & Vision + Smart Key Rotation)
  // ============================================================
  static Future<String> chatWithNutrigoAi({
    required String prompt,
    String? base64Image,
    String mimeType = 'image/jpeg',
  }) async {
    final List<Map<String, dynamic>> parts = [
      {'text': prompt},
    ];

    if (base64Image != null && base64Image.isNotEmpty) {
      parts.add({
        'inline_data': {'mime_type': mimeType, 'data': base64Image},
      });
    }

    final requestBody = jsonEncode({
      'contents': [
        {'parts': parts},
      ],
      'generationConfig': {'temperature': 0.4},
    });

    final uri = Uri.parse(_endpoint);
    final int totalKeys = ApiKey.geminiApiKeys.length;

    for (int attempt = 0; attempt < totalKeys; attempt++) {
      final keyToUse = _activeKey;

      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': keyToUse,
              },
              body: requestBody,
            )
            .timeout(const Duration(seconds: 35));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final resParts = candidates.first['content']?['parts'] as List?;
            for (final part in resParts ?? []) {
              if (part is Map && part['text'] != null) {
                final text = part['text'].toString().trim();
                if (text.isNotEmpty) {
                  return text
                      .replaceAll(RegExp(r'#{1,6}\s*'), '')
                      .replaceAll('**', '')
                      .replaceAll('*', '•')
                      .trim();
                }
              }
            }
          }
        }

        if (response.statusCode == 429 || response.statusCode == 403) {
          debugPrint("⚠️ Chat key [$_currentKeyIndex] exhausted. Rotating...");
          _rotateToNextKey();
          continue;
        }

        _rotateToNextKey();
      } catch (e) {
        _rotateToNextKey();
      }
    }

    return "All AI servers are currently busy with high requests. Please wait a minute and try again.";
  }
}
