// Packages
import 'package:flutter_riverpod/legacy.dart';

enum SettingsPanelType { none, profile, appearance }

final activeSettingsPanelProvider = StateProvider<SettingsPanelType>((ref) => SettingsPanelType.none);
