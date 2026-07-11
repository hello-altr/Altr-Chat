// Packages
import 'package:flutter_riverpod/legacy.dart';

enum SettingsPanelType { none, profile, appearance, workspaceInfo, usersAndGroups }

final activeSettingsPanelProvider = StateProvider<SettingsPanelType>((ref) => SettingsPanelType.none);

final usersAndGroupsViewHistoryProvider = StateProvider<List<String>>((ref) => const []);

final usersAndGroupsPageIndexProvider = StateProvider<int>((ref) => 0);

final profileTargetUserIdProvider = StateProvider<String?>((ref) => null);
