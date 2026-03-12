import 'package:flutter/material.dart';

// ─── Canonical Client Tag Definitions ─────────────────────────────────────────
// Single source of truth used by:
//   • health_profile_onboarding (client picks tags during Step 6)
//   • admin_diet_plan_creator   (admin plan setup + Gemini AI uses tags)
//   • client_management_system  (admin views client tags)
//
// Firestore field: clients/{uid}.tags  →  List<String>  (tag names)
// ─────────────────────────────────────────────────────────────────────────────

class ClientTag {
  final String name;
  final Color color;
  final String emoji;
  final String category;

  const ClientTag({
    required this.name,
    required this.color,
    required this.emoji,
    required this.category,
  });
}

const String kTagCatDiet    = 'Diet Type';
const String kTagCatGoal    = 'Goal';
const String kTagCatMedical = 'Medical';
const String kTagCatSpecial = 'Special Diet';

const List<ClientTag> kClientTags = [
  // Diet Type
  ClientTag(name: 'Veg',          color: Color(0xFF388E3C), emoji: '🥦', category: kTagCatDiet),
  ClientTag(name: 'Non-Veg',      color: Color(0xFFD32F2F), emoji: '🍗', category: kTagCatDiet),
  ClientTag(name: 'Egg',          color: Color(0xFFF57C00), emoji: '🥚', category: kTagCatDiet),
  ClientTag(name: 'Vegan',        color: Color(0xFF2E7D32), emoji: '🌱', category: kTagCatDiet),
  // Goal
  ClientTag(name: 'Weight Loss',  color: Color(0xFFE53935), emoji: '⚖️',  category: kTagCatGoal),
  ClientTag(name: 'Weight Gain',  color: Color(0xFF37474F), emoji: '💪',  category: kTagCatGoal),
  ClientTag(name: 'High Protein', color: Color(0xFF1565C0), emoji: '🥩',  category: kTagCatGoal),
  ClientTag(name: 'Maintenance',  color: Color(0xFF00838F), emoji: '🎯',  category: kTagCatGoal),
  // Medical
  ClientTag(name: 'Diabetes',     color: Color(0xFF7B1FA2), emoji: '🩸',  category: kTagCatMedical),
  ClientTag(name: 'High BP',      color: Color(0xFFC62828), emoji: '❤️',  category: kTagCatMedical),
  ClientTag(name: 'Heart Healthy',color: Color(0xFFAD1457), emoji: '🫀',  category: kTagCatMedical),
  ClientTag(name: 'Thyroid',      color: Color(0xFF4527A0), emoji: '🦋',  category: kTagCatMedical),
  ClientTag(name: 'PCOD/PCOS',    color: Color(0xFF880E4F), emoji: '🌸',  category: kTagCatMedical),
  ClientTag(name: 'Cholesterol',  color: Color(0xFFBF360C), emoji: '🔴',  category: kTagCatMedical),
  // Special Diet
  ClientTag(name: 'Gluten Free',  color: Color(0xFF558B2F), emoji: '🌾',  category: kTagCatSpecial),
  ClientTag(name: 'Dairy Free',   color: Color(0xFF0277BD), emoji: '🥛',  category: kTagCatSpecial),
  ClientTag(name: 'Low Carb',     color: Color(0xFF2E7D32), emoji: '🥗',  category: kTagCatSpecial),
  ClientTag(name: 'Keto',         color: Color(0xFF4E342E), emoji: '🥑',  category: kTagCatSpecial),
  ClientTag(name: 'High Fibre',   color: Color(0xFF33691E), emoji: '🌿',  category: kTagCatSpecial),
];

final Map<String, ClientTag> kClientTagMap = {
  for (final t in kClientTags) t.name: t,
};

Map<String, List<ClientTag>> get kClientTagsByCategory {
  final map = <String, List<ClientTag>>{};
  for (final t in kClientTags) {
    map.putIfAbsent(t.category, () => []).add(t);
  }
  return map;
}

/// Returns the Color for a given tag name. Falls back to grey if unknown.
Color tagColor(String tagName) {
  return kClientTagMap[tagName]?.color ?? const Color(0xFF9E9E9E);
}

/// Auto-suggest tags from onboarding answers.
/// The client can still freely add/remove any tag.
List<String> deriveTags({
  required String goal,
  required List<String> dietaryRestrictions,
  required List<String> medicalConditions,
}) {
  final tags = <String>{};

  switch (goal) {
    case 'weight_loss':   tags.add('Weight Loss'); break;
    case 'muscle_gain':   tags.addAll(['Weight Gain', 'High Protein']); break;
    case 'maintenance':
    case 'general_health': tags.add('Maintenance'); break;
  }

  for (final r in dietaryRestrictions) {
    switch (r) {
      case 'vegetarian': tags.add('Veg'); break;
      case 'vegan':      tags.addAll(['Vegan', 'Veg']); break;
      case 'gluten_free': tags.add('Gluten Free'); break;
      case 'dairy_free': tags.add('Dairy Free'); break;
      case 'keto':       tags.addAll(['Keto', 'Low Carb']); break;
      case 'paleo':      tags.add('High Protein'); break;
    }
  }

  for (final c in medicalConditions) {
    switch (c) {
      case 'diabetes':     tags.add('Diabetes'); break;
      case 'hypertension': tags.add('High BP'); break;
      case 'heart_disease': tags.add('Heart Healthy'); break;
      case 'thyroid':      tags.add('Thyroid'); break;
      case 'pcos':         tags.add('PCOD/PCOS'); break;
      case 'cholesterol':  tags.addAll(['Cholesterol', 'Heart Healthy']); break;
    }
  }

  return tags.toList();
}
