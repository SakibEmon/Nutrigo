import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'api_key.dart';
import 'gemini_prompt.dart';

class GeminiApi {
  // অফিসিয়াল একটিভ মডেল এন্ডপয়েন্ট
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:generateContent';

  // ============================================================
  // 1. MEAL ANALYSIS (40s Timeout + Auto Retry Logic)
  // ============================================================
  static Future<String> analyzeMeal({
    required String base64Image,
    required String targetMeal,
    String mimeType = 'image/jpeg',
  }) async {
    final uri = Uri.parse('$_endpoint?key=${ApiKey.geminiApiKey}');

    final requestBody = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': GeminiPrompt.mealAnalysisPrompt(targetMeal: targetMeal)},
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

    // নেটওয়ার্ক ল্যাগ হলে ব্যাকগ্রাউন্ডে সর্বোচ্চ ২ বার ট্রাই করবে
    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': ApiKey.geminiApiKey,
              },
              body: requestBody,
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode != 200) {
          debugPrint(
            "Gemini Error (Attempt $attempt, Status ${response.statusCode}): ${response.body}",
          );
          if (attempt == 2) {
            throw Exception(
              'Server Error: ${response.statusCode}\n${response.body}',
            );
          }
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          if (attempt == 2) throw Exception('Gemini returned no result.');
          continue;
        }

        final firstCandidate = candidates.first;
        final content = firstCandidate['content'];
        final parts = content['parts'] as List?;

        String? text;
        for (final part in parts ?? []) {
          if (part is Map && part['text'] != null) {
            text = part['text'].toString().trim();
            break;
          }
        }

        if (text != null && text.isNotEmpty) {
          return text;
        }
      } on TimeoutException {
        debugPrint("⚠️ Attempt $attempt timed out.");
        if (attempt == 2) {
          throw Exception('Connection timed out. Please check your network.');
        }
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        debugPrint("⚠️ Attempt $attempt failed: $e");
        if (attempt == 2) rethrow;
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    throw Exception('Failed to analyze image. Please try again.');
  }

  // ============================================================
  // 2. NUTRIGO AI CHAT (40s Timeout + Auto Retry Logic)
  // ============================================================
  static Future<String> chatWithNutrigoAi({
    required String prompt,
    String? base64Image,
    String mimeType = 'image/jpeg',
  }) async {
    final uri = Uri.parse('$_endpoint?key=${ApiKey.geminiApiKey}');

    final parts = <Map<String, dynamic>>[
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

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final response = await http
            .post(
              uri,
              headers: {
                'Content-Type': 'application/json',
                'x-goog-api-key': ApiKey.geminiApiKey,
              },
              body: requestBody,
            )
            .timeout(const Duration(seconds: 40));

        if (response.statusCode != 200) {
          debugPrint(
            "Chat Error (Attempt $attempt, Status ${response.statusCode}): ${response.body}",
          );
          if (attempt == 2) {
            return "API Error (${response.statusCode}). Please try again.";
          }
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }

        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          if (attempt == 2) return "No response received.";
          continue;
        }

        final firstCandidate = candidates.first;
        final responseParts = firstCandidate['content']['parts'] as List?;

        String? text;
        for (final part in responseParts ?? []) {
          if (part is Map && part['text'] != null) {
            text = part['text'].toString().trim();
            break;
          }
        }

        if (text != null && text.isNotEmpty) {
          return text
              .replaceAll(RegExp(r'#{1,6}\s*'), '')
              .replaceAll('**', '')
              .replaceAll('*', '•')
              .trim();
        }
      } on TimeoutException {
        if (attempt == 2) {
          return "Request timed out. Please check your internet connection.";
        }
        await Future.delayed(const Duration(seconds: 1));
      } catch (e) {
        if (attempt == 2) return "Connection error: $e";
        await Future.delayed(const Duration(seconds: 1));
      }
    }

    return "Something went wrong. Please try again.";
  }
}
