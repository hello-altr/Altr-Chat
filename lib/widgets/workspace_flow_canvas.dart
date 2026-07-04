// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';
import 'dart:math';

// Widgets
import 'package:chat/widgets/segmented_progress_bar.dart';

// Providers
import 'package:chat/providers/auth_provider.dart';

// Services
import 'package:chat/services/device_service.dart';

// Enums & Values
import 'package:chat/enums/onboarding_enums.dart';
import 'package:chat/exclusions.dart';

class WorkspaceFlowCanvas extends ConsumerStatefulWidget {
  final WorkspaceFlowContext contextType;
  final VoidCallback? onCompleted;

  const WorkspaceFlowCanvas({
    super.key,
    required this.contextType,
    this.onCompleted,
  });

  @override
  ConsumerState<WorkspaceFlowCanvas> createState() => _WorkspaceFlowCanvasState();
}

class _WorkspaceFlowCanvasState extends ConsumerState<WorkspaceFlowCanvas> {
  WorkspaceNavigationState _activeState = WorkspaceNavigationState.choiceHub;

  // Form State / Field Controllers for Wizard
  final _joinFormKey = GlobalKey<FormState>();
  final _joinTokenController = TextEditingController();
  bool _isJoining = false;

  // Wizard Slide State
  final _wizardPageController = PageController();
  int _pageViewIndex = 0;
  final _nameController = TextEditingController();
  String _selectedEmoji = '🏢';
  final List<String> _selectedModules = ['Altr Chats'];
  final List<String> _selectedChannels = ['#general', '#announcements'];
  String _selectedVisibility = 'Private';
  bool _isLaunching = false;

  final List<String> _availableEmojis = [
    '🏢', '🚀', '💡', '🎨', '🎮', '📚', '🎵', '⚽', '⚙️', '🛡️', '🩺', '🌍'
  ];

  final List<String> _availableModules = [
    'Altr Chats',
    'Altr LMS',
    'Altr Hub',
  ];

  final List<String> _availableChannels = [
    '#general',
    '#announcements',
    '#random',
  ];

  @override
  void dispose() {
    _joinTokenController.dispose();
    _wizardPageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _navigateTo(WorkspaceNavigationState state) {
    setState(() {
      _activeState = state;
    });
  }

  // --- JOIN WORKSPACE LOGIC ---
  Future<void> _submitJoinToken() async {
    if (!_joinFormKey.currentState!.validate()) return;
    setState(() {
      _isJoining = true;
    });

    final token = _joinTokenController.text.trim();
    final user = ref.read(authStateProvider).value;

    try {
      if (user == null) throw Exception("User is unauthenticated.");

      final workspaceDoc = await FirebaseFirestore.instance.collection('workspaces').doc(token).get();

      if (!workspaceDoc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Workspace not found. Check the invitation token."),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        return;
      }

      final deviceId = await DeviceService.getDeviceId();
      final batch = FirebaseFirestore.instance.batch();

      final workspaceRef = FirebaseFirestore.instance.collection('workspaces').doc(token);
      batch.update(workspaceRef, {
        'members': FieldValue.arrayUnion([user.uid]),
      });

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userRef, {
        'current_workspaces.$deviceId': token,
        'active_workspaces': FieldValue.arrayUnion([token]),
        'workspace_onboarding_completed': true,
      });

      await batch.commit();
      ref.invalidate(userProfileProvider);

      if (widget.onCompleted != null) {
        widget.onCompleted!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to join workspace: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
    }
  }

  // --- CREATE WORKSPACE LOGIC ---
  Future<void> _launchWorkspace() async {
    setState(() {
      _isLaunching = true;
    });

    final user = ref.read(authStateProvider).value;
    final name = _nameController.text.trim();

    try {
      if (user == null) throw Exception("User is unauthenticated.");
      if (name.isEmpty) throw Exception("Workspace name is empty.");

      final deviceId = await DeviceService.getDeviceId();
      
      // Generate 6 character uppercase alphanumeric workspace code
      final rnd = Random();
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      final workspaceId = String.fromCharCodes(Iterable.generate(
          6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
      
      final batch = FirebaseFirestore.instance.batch();

      final workspaceRef = FirebaseFirestore.instance.collection('workspaces').doc(workspaceId);
      batch.set(workspaceRef, {
        'id': workspaceId,
        'name': name,
        'logo': _selectedEmoji,
        'modules': _selectedModules,
        'visibility': _selectedVisibility.toLowerCase(),
        'members': [user.uid],
        'created_by': user.uid,
        'created_at': FieldValue.serverTimestamp(),
      });

      for (final channelName in _selectedChannels) {
        final channelRef = FirebaseFirestore.instance.collection('chat').doc();
        batch.set(channelRef, {
          'workspace_id': workspaceId,
          'name': channelName.replaceAll('#', ''),
          'created_at': FieldValue.serverTimestamp(),
        });
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      batch.update(userRef, {
        'current_workspaces.$deviceId': workspaceId,
        'active_workspaces': FieldValue.arrayUnion([workspaceId]),
        'workspace_onboarding_completed': true,
      });

      await batch.commit();
      ref.invalidate(userProfileProvider);

      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            final theme = Theme.of(dialogContext);
            return AlertDialog(
              title: const Text('Workspace Created!'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Your workspace has been successfully created. '
                    'Share this invitation code with your team to let them join:',
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withAlpha(100),
                        ),
                      ),
                      child: SelectableText(
                        workspaceId,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                          letterSpacing: 4.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    if (widget.onCompleted != null) {
                      widget.onCompleted!();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Go to Workspace'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to launch workspace: $e"),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  // Helper to verify domain constraints for discovers
  bool _isDomainExcluded() {
    final user = ref.read(authStateProvider).value;
    final email = user?.email ?? '';
    if (email.isEmpty || !email.contains('@')) return false;
    final domain = email.split('@').last.toLowerCase();
    return excludedWorkspaceDomains.contains(domain);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    switch (_activeState) {
      case WorkspaceNavigationState.choiceHub:
        return _buildChoiceHub(theme);
      case WorkspaceNavigationState.joinView:
        return _buildJoinView(theme);
      case WorkspaceNavigationState.createWizard:
        return _buildCreateWizard(theme);
    }
  }

  // --- 1. CHOICE HUB ---
  Widget _buildChoiceHub(ThemeData theme) {
    final showBack = widget.contextType == WorkspaceFlowContext.settingsHub;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workspace Options',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: showBack
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            : null,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Altr Chat',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  foreground: Paint()
                    ..shader = LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.secondary,
                      ],
                    ).createShader(const Rect.fromLTWH(0.0, 0.0, 300.0, 70.0)),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Select how you would like to proceed with your workspace setup.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Card 1: Join Workspace
              _buildChoiceCard(
                icon: Icons.group_add_outlined,
                title: 'Join a Workspace',
                subtitle: 'Enter an invitation code to join an existing workspace team.',
                onTap: () => _navigateTo(WorkspaceNavigationState.joinView),
                theme: theme,
              ),
              const SizedBox(height: 20),

              // Card 2: Create Workspace
              _buildChoiceCard(
                icon: Icons.create_new_folder_outlined,
                title: 'Create a Workspace',
                subtitle: 'Set up a brand new organization hub and invite your members.',
                onTap: () {
                  // Reset wizard states
                  setState(() {
                    _pageViewIndex = 0;
                    _nameController.clear();
                    _selectedEmoji = '🏢';
                    _selectedModules.clear();
                    _selectedModules.add('Altr Chats');
                    _selectedChannels.clear();
                    _selectedChannels.addAll(['#general', '#announcements']);
                    _selectedVisibility = _isDomainExcluded() ? 'Private' : 'Discoverable';
                  });
                  _navigateTo(WorkspaceNavigationState.createWizard);
                },
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      color: theme.colorScheme.surfaceContainerHigh,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 2. JOIN VIEW ---
  Widget _buildJoinView(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Join Workspace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateTo(WorkspaceNavigationState.choiceHub),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _joinFormKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Invitation Code',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the alphanumeric invitation code sent by your organization administrator.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _joinTokenController,
                decoration: const InputDecoration(
                  labelText: 'Invitation Token',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.vpn_key_outlined),
                ),
                validator: (val) =>
                    val == null || val.trim().isEmpty ? 'Enter a valid workspace code' : null,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isJoining ? null : _submitJoinToken,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Join Workspace'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- 3. CREATE WIZARD ---
  Widget _buildCreateWizard(ThemeData theme) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Create Workspace',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_pageViewIndex == 0) {
              _navigateTo(WorkspaceNavigationState.choiceHub);
            } else {
              _wizardPageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            }
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          // Step progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: SegmentedOnboardingProgressBar(
              totalSteps: 6,
              currentStepIndex: _pageViewIndex,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: PageView(
              controller: _wizardPageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (idx) {
                setState(() {
                  _pageViewIndex = idx;
                });
              },
              children: [
                _buildStepName(theme),
                _buildStepLogo(theme),
                _buildStepModules(theme),
                _buildStepChannels(theme),
                _buildStepVisibility(theme),
                _buildStepSummary(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Wizard Slide 1: Workspace Name
  Widget _buildStepName(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Name your workspace',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a clear name for your organization. You can edit this later in settings.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Workspace Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business_outlined),
            ),
          ),
          const SizedBox(height: 32),
          _buildNextButton(() {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a workspace name')),
              );
              return;
            }
            _wizardPageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }, theme),
        ],
      ),
    );
  }

  // Wizard Slide 2: Logo Mark (Emojis Aspect Ratio Grid Selector)
  Widget _buildStepLogo(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select a Logo Emoji',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose an emoji that represents your workspace to display in sidebars.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: _availableEmojis.length,
              itemBuilder: (context, idx) {
                final emoji = _availableEmojis[idx];
                final isSelected = emoji == _selectedEmoji;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outlineVariant.withAlpha(80),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 32),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildNextButton(() {
            _wizardPageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }, theme),
        ],
      ),
    );
  }

  // Wizard Slide 3: Feature Modules
  Widget _buildStepModules(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Initialize Feature Modules',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select which default tools you want to make available immediately.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              itemCount: _availableModules.length,
              itemBuilder: (context, idx) {
                final module = _availableModules[idx];
                final isSelected = _selectedModules.contains(module);
                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  color: isSelected
                      ? theme.colorScheme.primaryContainer.withAlpha(50)
                      : theme.colorScheme.surfaceContainerLow,
                  margin: const EdgeInsets.only(bottom: 12),
                  child: CheckboxListTile(
                    value: isSelected,
                    onChanged: (val) {
                      setState(() {
                        if (val == true) {
                          _selectedModules.add(module);
                        } else {
                          // Prevent clearing Altr Chats since it is the core module
                          if (module != 'Altr Chats') {
                            _selectedModules.remove(module);
                          }
                        }
                      });
                    },
                    title: Text(
                      module,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      module == 'Altr Chats'
                          ? 'Real-time collaborative channels & DMs'
                          : module == 'Altr LMS'
                              ? 'Interactive learning materials & courses'
                              : 'Unified dashboard widgets & portals',
                      style: theme.textTheme.bodySmall,
                    ),
                    secondary: Icon(
                      module == 'Altr Chats'
                          ? Icons.chat_bubble_outline
                          : module == 'Altr LMS'
                              ? Icons.school_outlined
                              : Icons.widgets_outlined,
                      color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    activeColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),
          ),
          _buildNextButton(() {
            _wizardPageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }, theme),
        ],
      ),
    );
  }

  // Wizard Slide 4: Default Channels Bootstrapping
  Widget _buildStepChannels(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bootstrap Channels',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Select which channel filters to initialize in this new workspace.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _availableChannels.map((channel) {
                final isSelected = _selectedChannels.contains(channel);
                return FilterChip(
                  label: Text(
                    channel,
                    style: TextStyle(
                      color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  selected: isSelected,
                  onSelected: (val) {
                    setState(() {
                      if (val) {
                        _selectedChannels.add(channel);
                      } else {
                        // Keep at least one channel
                        if (_selectedChannels.length > 1) {
                          _selectedChannels.remove(channel);
                        }
                      }
                    });
                  },
                  selectedColor: theme.colorScheme.primary,
                  checkmarkColor: theme.colorScheme.onPrimary,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withAlpha(80),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                );
              }).toList(),
            ),
          ),
          _buildNextButton(() {
            _wizardPageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }, theme),
        ],
      ),
    );
  }

  // Wizard Slide 5: Visibility Rules (Private vs Discoverable)
  Widget _buildStepVisibility(ThemeData theme) {
    final isExcluded = _isDomainExcluded();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Visibility Rules',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose whether this workspace is open to discovery or hidden from public registries.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                // Private Card (Always available)
                _buildVisibilityCard(
                  title: 'Private Only',
                  description: 'Workspace is hidden. Members can only join by a direct alphanumeric token.',
                  isSelected: _selectedVisibility == 'Private',
                  onTap: () {
                    setState(() {
                      _selectedVisibility = 'Private';
                    });
                  },
                  theme: theme,
                ),
                const SizedBox(height: 16),

                // Discoverable Card
                _buildVisibilityCard(
                  title: 'Discoverable',
                  description: 'Workspace can be searched and joined by users sharing your verified domain.',
                  isSelected: _selectedVisibility == 'Discoverable',
                  onTap: isExcluded
                      ? null
                      : () {
                          setState(() {
                            _selectedVisibility = 'Discoverable';
                          });
                        },
                  theme: theme,
                  disabled: isExcluded,
                ),

                if (isExcluded) ...[
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer.withAlpha(50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.error.withAlpha(100),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your authenticated email domain is restricted under domain constraints. Discoverable workspaces are locked out.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onErrorContainer,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          _buildNextButton(() {
            _wizardPageController.nextPage(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          }, theme),
        ],
      ),
    );
  }

  Widget _buildVisibilityCard({
    required String title,
    required String description,
    required bool isSelected,
    required VoidCallback? onTap,
    required ThemeData theme,
    bool disabled = false,
  }) {
    final opacity = disabled ? 0.45 : 1.0;
    return Opacity(
      opacity: opacity,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withAlpha(80),
            width: isSelected ? 2 : 1,
          ),
        ),
        color: isSelected
            ? theme.colorScheme.primaryContainer.withAlpha(50)
            : theme.colorScheme.surfaceContainerHigh,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Icon(
                  title == 'Private Only' ? Icons.lock_outline : Icons.public_outlined,
                  size: 28,
                  color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Wizard Slide 6: Summary Dashboard
  Widget _buildStepSummary(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Details',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Verify your configuration parameters below before launching the workspace.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withAlpha(80),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryRow('Name', _nameController.text.trim(), theme),
                    const Divider(height: 24),
                    _buildSummaryRow('Logo', _selectedEmoji, theme),
                    const Divider(height: 24),
                    _buildSummaryRow('Modules', _selectedModules.join(', '), theme),
                    const Divider(height: 24),
                    _buildSummaryRow('Channels', _selectedChannels.join(', '), theme),
                    const Divider(height: 24),
                    _buildSummaryRow('Visibility', _selectedVisibility, theme),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLaunching ? null : _launchWorkspace,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLaunching
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Launch Workspace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton(VoidCallback onPressed, ThemeData theme) {
    return Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        icon: const Text('Next'),
        label: const Icon(Icons.arrow_forward, size: 16),
      ),
    );
  }
}

void openAddWorkspaceFlow(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final isMobile = width < 840;

  if (isMobile) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: WorkspaceFlowCanvas(
            contextType: WorkspaceFlowContext.settingsHub,
          ),
        ),
      ),
    );
  } else {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (context) {
        final theme = Theme.of(context);
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 680,
                maxHeight: 600,
              ),
              child: Card(
                elevation: 12,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                color: theme.colorScheme.surfaceContainer,
                child: WorkspaceFlowCanvas(
                  contextType: WorkspaceFlowContext.settingsHub,
                  onCompleted: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
