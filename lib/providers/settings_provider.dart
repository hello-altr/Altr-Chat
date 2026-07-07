// Packages
import 'package:flutter_riverpod/legacy.dart';

enum SettingsPanelType { none, profile, appearance, workspaceInfo, usersAndGroups }

final activeSettingsPanelProvider = StateProvider<SettingsPanelType>((ref) => SettingsPanelType.none);
