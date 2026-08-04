class AuthUser {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String email;
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
        : provider is List && provider.isNotEmpty && provider.first is Map<String, dynamic>
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
      providerVerificationStatus: (providerMap['verification_status'] as String?) ?? 'not_applied',
    );
  }
}

class AuthOperation {
  const AuthOperation({this.user, this.error, this.needsEmailConfirmation = false});

  final AuthUser? user;
  final String? error;
  final bool needsEmailConfirmation;

  bool get succeeded => user != null && error == null;
}
