// Packages
import 'package:flutter_riverpod/legacy.dart';

// StateProvider to store message drafts, keyed by chat ID (e.g. channel name or DM name)
final messageDraftProvider = StateProvider.family<String, String>((ref, chatId) => '');

// StateProvider to track whether the ProfileCardInspector is active under the Settings tab scope
final isProfileExpandedProvider = StateProvider<bool>((ref) => false);

// Search Query Providers
final channelSearchQueryProvider = StateProvider<String>((ref) => '');
final dmSearchQueryProvider = StateProvider<String>((ref) => '');
