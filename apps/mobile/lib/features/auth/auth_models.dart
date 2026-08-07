class AuthUser {
  const AuthUser({required this.id, required this.email, this.phone});

  final String id;
  final String email;
  final String? phone;
}

class ProfileData {
  const ProfileData({
    required this.id,
    required this.fullName,
    required this.displayName,
    required this.phone,
    required this.whatsapp,
    required this.accountStatus,
    required this.isAdmin,
    required this.providerVerificationStatus,
  });

  final String id;
  final String? fullName;
  final String? displayName;
  final String? phone;
  final String? whatsapp;
  final String accountStatus;
  final bool isAdmin;
  final String providerVerificationStatus;

  bool get isSuspended => accountStatus == 'suspended';
  bool get isApprovedProvider => providerVerificationStatus == 'approved';

  factory ProfileData.fromMap(Map<String, dynamic> map, {String? id}) {
    final provider = map['provider_profiles'];
    final providerMap = provider is Map<String, dynamic>
        ? provider
        : provider is List &&
                provider.isNotEmpty &&
                provider.first is Map<String, dynamic>
            ? provider.first as Map<String, dynamic>
            : const <String, dynamic>{};
    return ProfileData(
      id: (map['id'] as String?) ?? id ?? '',
      fullName: map['full_name'] as String?,
      displayName: map['display_name'] as String?,
      phone: map['phone'] as String?,
      whatsapp: map['whatsapp'] as String?,
      accountStatus: (map['account_status'] as String?) ?? 'active',
      isAdmin: (map['is_admin'] as bool?) ?? false,
      providerVerificationStatus:
          (providerMap['verification_status'] as String?) ?? 'not_applied',
    );
  }
}

class AuthOperation {
  const AuthOperation(
      {this.user, this.error, this.needsEmailConfirmation = false});

  final AuthUser? user;
  final String? error;
  final bool needsEmailConfirmation;

  bool get succeeded => user != null && error == null;
}

/// Returns the display name that belongs to the currently authenticated user.
///
/// The profile returned by Supabase is the source of truth. The fallback is
/// only used while a newly-created profile is being hydrated (or by the local
/// demo adapter), and is derived from that same user's email/phone instead of
/// a hard-coded demo identity.
String authDisplayName(AuthUser? user, ProfileData? profile) {
  final profileName = profile?.displayName?.trim();
  if (profileName != null && profileName.isNotEmpty) return profileName;
  final fullName = profile?.fullName?.trim();
  if (fullName != null && fullName.isNotEmpty) return fullName;

  final email = user?.email.trim() ?? '';
  final localPart = email.isEmpty ? '' : email.split('@').first;
  final source = localPart.isNotEmpty ? localPart : (user?.phone ?? '');
  if (source.isEmpty) return 'Ofrivo member';
  final words = source
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), ' ')
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .map((word) =>
          '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}')
      .toList();
  return words.isEmpty ? 'Ofrivo member' : words.join(' ');
}
