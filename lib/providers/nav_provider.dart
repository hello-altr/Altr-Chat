// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hugeicons_pro/hugeicons.dart';
import 'package:material_ui/material_ui.dart';

// Your existing state index container tracker
final navIndexProvider = StateProvider<int>((ref) => 1);

// Standardized schema model container for navigation components
class AeroNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const AeroNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// Global immutable list data configuration - Single Source of Truth
final aeroNavItemsProvider = Provider<List<AeroNavItem>>((ref) {
  return const [
    AeroNavItem(
      icon: HugeIconsStroke.chat01,
      activeIcon: HugeIconsSolid.chat01,
      label: 'DMS',
    ),
    AeroNavItem(
      icon: HugeIconsStroke.hashtag,
      activeIcon: HugeIconsSolid.hashtag,
      label: 'Channels',
    ),
    AeroNavItem(
      icon: HugeIconsStroke.megaphone01,
      activeIcon: HugeIconsSolid.megaphone01,
      label: 'Updates',
    ),
    AeroNavItem(
      icon: HugeIconsStroke.userCircle02,
      activeIcon: HugeIconsSolid.userCircle02,
      label: 'Profile',
    ),
  ];
});