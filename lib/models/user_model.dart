class AltrUser {
  final String userId;
  final String userName;
  final String displayName;
  final String photoUrl;
  final String emailId;
  final List<String> activeWorkspaces;
  final String currentWorkspace;
  final bool onboardingCompleted;
  final bool profileOnboardingCompleted;
  final bool workspaceOnboardingCompleted;

  AltrUser({
    required this.userId,
    required this.userName,
    required this.displayName,
    required this.photoUrl,
    required this.emailId,
    required this.activeWorkspaces,
    required this.currentWorkspace,
    required this.onboardingCompleted,
    required this.profileOnboardingCompleted,
    required this.workspaceOnboardingCompleted,
  });

  Map<String, dynamic> toMap() => {
    'user_id': userId,
    'user_name': userName,
    'display_name': displayName,
    'photo_url': photoUrl,
    'email_id': emailId,
    'active_workspaces': activeWorkspaces,
    'onboarding_completed': onboardingCompleted,
    'profile_onboarding_completed': profileOnboardingCompleted,
    'workspace_onboarding_completed': workspaceOnboardingCompleted,
  };

  factory AltrUser.fromMap(Map<String, dynamic> map, {required String currentWorkspace}) => AltrUser(
    userId: map['user_id'] ?? '',
    userName: map['user_name'] ?? '',
    displayName: map['display_name'] ?? '',
    photoUrl: map['photo_url'] ?? '',
    emailId: map['email_id'] ?? '',
    activeWorkspaces: List<String>.from(map['active_workspaces'] ?? []),
    currentWorkspace: currentWorkspace,
    onboardingCompleted: map['onboarding_completed'] ?? false,
    profileOnboardingCompleted: map['profile_onboarding_completed'] ?? map['onboarding_completed'] ?? false,
    workspaceOnboardingCompleted: map['workspace_onboarding_completed'] ?? false,
  );
}
