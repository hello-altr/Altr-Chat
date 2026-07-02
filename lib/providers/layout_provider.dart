// Packages
import 'package:flutter_riverpod/legacy.dart';

// Enums
import 'package:chat/enums/layout_mode.dart';

// Global provider to watch active layout constraints anywhere in your atomic UI layer
final layoutProvider = StateProvider<LayoutMode>((ref) => LayoutMode.mobile);
