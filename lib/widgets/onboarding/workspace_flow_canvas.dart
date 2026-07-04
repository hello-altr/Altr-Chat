// Packages
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_ui/material_ui.dart';

// Steps Pages
import 'steps/workspace_visibility_step.dart';
import 'steps/workspace_channels_step.dart';
import 'steps/workspace_branding_step.dart';
import 'steps/workspace_summary_step.dart';
import 'steps/workspace_modules_step.dart';
import 'steps/workspace_name_step.dart';

// Widgets
import 'package:chat/widgets/segmented_progress_bar.dart';

// Providers
import 'package:chat/providers/auth_provider.dart';

// Services
import 'package:chat/services/device_service.dart';

// Enums & Values
import 'package:chat/enums/onboarding_enums.dart';

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
      // Clear controllers when backing out or shifting states to ensure clean forms
      if (state == WorkspaceNavigationState.choiceHub) {
        _joinTokenController.clear();
        _nameController.clear();
        _pageViewIndex = 0;
        _selectedEmoji = '🏢';
        _selectedModules.clear();
        _selectedModules.add('Altr Chats');
        _selectedChannels.clear();
        _selectedChannels.addAll(['#general', '#announcements']);
        _selectedVisibility = 'Private';
        // Reset PageView page index back to 0
        if (_wizardPageController.hasClients) {
          _wizardPageController.jumpToPage(0);
        }
      }
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
              // Join Card
              _buildChoiceCard(
                title: 'Join a Workspace',
                description: 'Enter an invitation code from your administrator to join an existing workspace.',
                icon: Icons.group_add_outlined,
                onTap: () => _navigateTo(WorkspaceNavigationState.joinView),
                theme: theme,
              ),
              const SizedBox(height: 20),
              // Create Card
              _buildChoiceCard(
                title: 'Create a Workspace',
                description: 'Kickstart a brand new workspace instance for you and your team.',
                icon: Icons.add_business_outlined,
                onTap: () => _navigateTo(WorkspaceNavigationState.createWizard),
                theme: theme,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(80),
        ),
      ),
      color: theme.colorScheme.surfaceContainerLow,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
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
                  size: 32,
                  color: theme.colorScheme.onPrimaryContainer,
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
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
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
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: Colors.transparent,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _joinFormKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.vpn_key_outlined,
                  size: 64,
                ),
                const SizedBox(height: 24),
                Text(
                  'Enter Invitation Token',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'To join an existing workspace, enter the token provided by your team lead.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
                WorkspaceNameStep(
                  nameController: _nameController,
                  onNext: () {
                    _wizardPageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                WorkspaceBrandingStep(
                  selectedEmoji: _selectedEmoji,
                  onEmojiSelected: (emoji) {
                    setState(() {
                      _selectedEmoji = emoji;
                    });
                  },
                  onNext: () {
                    _wizardPageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                WorkspaceModulesStep(
                  selectedModules: _selectedModules,
                  onModulesChanged: (modules) {
                    setState(() {
                      _selectedModules.clear();
                      _selectedModules.addAll(modules);
                    });
                  },
                  onNext: () {
                    _wizardPageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                WorkspaceChannelsStep(
                  selectedChannels: _selectedChannels,
                  onChannelsChanged: (channels) {
                    setState(() {
                      _selectedChannels.clear();
                      _selectedChannels.addAll(channels);
                    });
                  },
                  onNext: () {
                    _wizardPageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                WorkspaceVisibilityStep(
                  selectedVisibility: _selectedVisibility,
                  onVisibilityChanged: (visibility) {
                    setState(() {
                      _selectedVisibility = visibility;
                    });
                  },
                  onNext: () {
                    _wizardPageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                ),
                WorkspaceSummaryStep(
                  name: _nameController.text,
                  logo: _selectedEmoji,
                  modules: _selectedModules,
                  channels: _selectedChannels,
                  visibility: _selectedVisibility,
                  onCompleted: widget.onCompleted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
