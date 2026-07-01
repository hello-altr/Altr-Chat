import 'package:flutter_riverpod/legacy.dart';

// StateProvider to store message drafts, keyed by chat ID (e.g. channel name or DM name)
final messageDraftProvider = StateProvider.family<String, String>((ref, chatId) => '');

// StateProvider to track whether the ProfileCardInspector is active in the desktop Settings panel
final isProfileActiveInSettingsDesktopProvider = StateProvider<bool>((ref) => false);
