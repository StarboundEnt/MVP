import '../models/complexity_profile.dart';

/// Build a compassionate follow-up line that reminds the user about a saved step.
/// Returns null when the step text does not have enough content to be helpful.
String? buildImplementationIntention({
  required String rawStepText,
  required ComplexityLevel profile,
  String? userName,
}) {
  var text = rawStepText.trim();
  if (text.isEmpty) return null;

  text = text
      .replaceAll('**', '')
      .replaceAll(RegExp(r'^\d+[\.:)\s]*'), '')
      .replaceAll(RegExp(r'^Step\s*\d+[:.)\s-]*', caseSensitive: false), '')
      .replaceAll(RegExp(r'^•\s*'), '')
      .trim();

  if (text.isEmpty) return null;

  if (text.length > 160) {
    text = '${text.substring(0, 157)}...';
  }

  final rawName = (userName ?? '').trim();
  final friendlyName =
      rawName.isNotEmpty && rawName.toLowerCase() != 'explorer'
          ? '${rawName.split(' ').first}, '
          : '';

  String prefix;
  switch (profile) {
    case ComplexityLevel.stable:
      prefix = '${friendlyName}when this pops up again, lean on';
      break;
    case ComplexityLevel.trying:
      prefix = '${friendlyName}if things wobble later, come back to';
      break;
    case ComplexityLevel.overloaded:
      prefix = '${friendlyName}if the day feels heavy again, give yourself this option:';
      break;
    case ComplexityLevel.survival:
      prefix =
          '${friendlyName}if everything is overwhelming later, the smallest next step is';
      break;
  }

  final needsPeriod =
      !(text.endsWith('.') || text.endsWith('!') || text.endsWith('?'));
  final ending = needsPeriod ? '$text.' : text;

  return '$prefix $ending';
}
