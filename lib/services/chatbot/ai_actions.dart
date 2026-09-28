/// Action buttons in assistant replies.
///
/// The model may end a reply with up to 3 tags of the exact form
/// `[[open:<kind>:<id>]]`, where kind is fandom, event, product, post,
/// creator, category or screen (for screen, the id is one of
/// [kAssistantScreens]). The app strips every tag from the visible text and
/// shows the valid ones as buttons. A tag is dropped when its kind is
/// unknown, its screen name isn't allowed, or its id isn't in the content
/// snapshot the model was given, so a made-up id never becomes a button.
library;

const Map<String, String> kAssistantScreens = {
  'resources': 'Open Resources',
  'events_map': 'Open Events (Map)',
  'events_calendar': 'Open Events (Calendar)',
  'my_agenda': 'Open My Agenda',
  'cart': 'View cart',
  'wishlist': 'View wishlist',
  'glossary': 'Open Glossary',
  'beginner_hub': 'Open Beginner Fan Hub',
  'profile': 'Open Profile',
  'following': 'Open Following',
  'contact': 'Contact Us',
  'about': 'About Us',
};

const Set<String> kAssistantActionKinds = {
  'fandom',
  'event',
  'product',
  'post',
  'creator',
  'category',
  'screen',
};

const int kMaxAssistantActions = 3;

class AssistantAction {
  final String kind;
  final String id;
  final String label;
  const AssistantAction(this.kind, this.id, this.label);

  @override
  bool operator ==(Object other) => other is AssistantAction && other.kind == kind && other.id == id;
  @override
  int get hashCode => Object.hash(kind, id);
  @override
  String toString() => '$kind:$id';
}

final RegExp _tag = RegExp(r'\[\[\s*open\s*:\s*([a-z_]+)\s*:\s*([^\]\s]+?)\s*\]\]');

/// Removes every complete action tag, and a trailing incomplete one ("[[op…"
/// while a reply is still streaming in), then tidies the whitespace left.
String stripActionTags(String text) {
  var out = text.replaceAll(_tag, '');
  final open = out.lastIndexOf('[[');
  if (open >= 0 && !out.substring(open).contains(']]')) out = out.substring(0, open);
  return out.replaceAll(RegExp(r'[ \t]+\n'), '\n').replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

/// The valid actions in [text], in order, without duplicates, at most
/// [kMaxAssistantActions]. [labelFor] returns the button label for an id of
/// a kind, or null when the id doesn't exist (the tag is then dropped).
List<AssistantAction> parseActionTags(
  String text,
  String? Function(String kind, String id) labelFor,
) {
  final out = <AssistantAction>[];
  for (final m in _tag.allMatches(text)) {
    final kind = m.group(1)!;
    final id = m.group(2)!;
    if (!kAssistantActionKinds.contains(kind)) continue;
    final label = kind == 'screen' ? kAssistantScreens[id] : labelFor(kind, id);
    if (label == null) continue;
    final action = AssistantAction(kind, id, label);
    if (!out.contains(action)) out.add(action);
    if (out.length == kMaxAssistantActions) break;
  }
  return out;
}
