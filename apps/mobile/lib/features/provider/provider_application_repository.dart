import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/service_options.dart';
import 'provider_application_models.dart';

abstract interface class ProviderApplicationRepository {
  Future<ProviderApplication?> load();
  Future<ProviderApplication> submit(ProviderApplicationDraft draft);
  Future<ProviderApplication> updateProfile({
    required String displayName,
    required String bio,
    required String phone,
    required String whatsapp,
    required List<ServiceAreaOption> areas,
    required List<String> workPhotoPaths,
  });
  Future<ProviderApplication> submitCategoryChanges(
      List<ServiceCategoryOption> categories);
  Future<ProviderApplication> setAvailability(bool isAvailable);
}

class FakeProviderApplicationRepository
    implements ProviderApplicationRepository {
  FakeProviderApplicationRepository({
    ProviderApplicationStatus initialStatus =
        ProviderApplicationStatus.approved,
    String initialDisplayName = 'Ahmad Plumbing',
    double initialRating = 4.9,
    int initialCompletedJobs = 86,
  }) : _application = ProviderApplication.demo(
          status: initialStatus,
          displayName: initialDisplayName,
          rating: initialRating,
          completedJobs: initialCompletedJobs,
        );
  ProviderApplication _application;

  @override
  Future<ProviderApplication?> load() async =>
      _application.status == ProviderApplicationStatus.notApplied
          ? null
          : _application;

  @override
  Future<ProviderApplication> submit(ProviderApplicationDraft draft) async {
    final error = draft.validate();
    if (error != null) throw StateError(error);
    final now = DateTime.now();
    final selections = [
      for (final category in draft.categories)
        ProviderCategorySelection(
          category: category,
          status: ProviderCategoryStatus.pending,
          submittedAt: now,
        ),
    ];
    _application = ProviderApplication(
      status: ProviderApplicationStatus.pending,
      displayName: draft.displayName.trim(),
      bio: draft.bio.trim(),
      categories: List.unmodifiable(draft.categories),
      areas: List.unmodifiable(draft.areas),
      icFrontPath: draft.icFrontPath,
      icBackPath: draft.icBackPath,
      selfiePath: draft.selfiePath,
      ssmPath: draft.ssmPath,
      certificatePaths: List.unmodifiable(draft.certificatePaths),
      workPhotoPaths: List.unmodifiable(draft.workPhotoPaths),
      adminNote: null,
      submittedAt: now,
      isAvailable: false,
      categorySelections: List.unmodifiable(selections),
      rating: 0,
      completedJobs: 0,
    );
    return _application;
  }

  @override
  Future<ProviderApplication> updateProfile({
    required String displayName,
    required String bio,
    required String phone,
    required String whatsapp,
    required List<ServiceAreaOption> areas,
    required List<String> workPhotoPaths,
  }) async {
    if (displayName.trim().length < 2) {
      throw StateError('Add a business or display name.');
    }
    if (bio.trim().length < 10) {
      throw StateError('Tell customers a little more about your work.');
    }
    if (areas.isEmpty) throw StateError('Choose at least one service area.');
    if (workPhotoPaths.length > 6) {
      throw StateError('Choose no more than 6 work photos.');
    }
    _application = _copy(
      displayName: displayName.trim(),
      bio: bio.trim(),
      phone: phone.trim(),
      whatsapp: whatsapp.trim(),
      areas: List.unmodifiable(areas),
      workPhotoPaths: List.unmodifiable(workPhotoPaths),
    );
    return _application;
  }

  @override
  Future<ProviderApplication> submitCategoryChanges(
      List<ServiceCategoryOption> categories) async {
    if (categories.isEmpty || categories.length > 6) {
      throw StateError('Choose between 1 and 6 service categories.');
    }
    if (_application.status != ProviderApplicationStatus.approved) {
      throw StateError(
          'Only an approved provider can update service categories.');
    }
    final existing = {
      for (final item in _application.categorySelections)
        item.category.id: item,
    };
    final now = DateTime.now();
    final selections = [
      for (final category in categories)
        () {
          final previous = existing[category.id];
          if (previous == null) {
            return ProviderCategorySelection(
                category: category,
                status: ProviderCategoryStatus.pending,
                submittedAt: now);
          }
          if (previous.status == ProviderCategoryStatus.rejected) {
            return ProviderCategorySelection(
                category: category,
                status: ProviderCategoryStatus.pending,
                submittedAt: now);
          }
          return previous;
        }(),
    ];
    _application = _copy(
      categories: List.unmodifiable(categories),
      categorySelections: List.unmodifiable(selections),
    );
    return _application;
  }

  @override
  Future<ProviderApplication> setAvailability(bool isAvailable) async {
    if (isAvailable &&
        _application.status != ProviderApplicationStatus.approved) {
      throw StateError('Only an approved provider can receive new jobs.');
    }
    _application = _copy(isAvailable: isAvailable);
    return _application;
  }

  ProviderApplication _copy({
    String? displayName,
    String? bio,
    String? phone,
    String? whatsapp,
    List<ServiceCategoryOption>? categories,
    List<ServiceAreaOption>? areas,
    List<String>? workPhotoPaths,
    List<ProviderCategorySelection>? categorySelections,
    bool? isAvailable,
  }) =>
      ProviderApplication(
        status: _application.status,
        displayName: displayName ?? _application.displayName,
        bio: bio ?? _application.bio,
        categories: categories ?? _application.categories,
        areas: areas ?? _application.areas,
        icFrontPath: _application.icFrontPath,
        icBackPath: _application.icBackPath,
        selfiePath: _application.selfiePath,
        ssmPath: _application.ssmPath,
        certificatePaths: _application.certificatePaths,
        workPhotoPaths: workPhotoPaths ?? _application.workPhotoPaths,
        adminNote: _application.adminNote,
        submittedAt: _application.submittedAt,
        isAvailable: isAvailable ?? _application.isAvailable,
        phone: phone ?? _application.phone,
        whatsapp: whatsapp ?? _application.whatsapp,
        categorySelections:
            categorySelections ?? _application.categorySelections,
        rating: _application.rating,
        completedJobs: _application.completedJobs,
        avatarPath: _application.avatarPath,
      );
}

class SupabaseProviderApplicationRepository
    implements ProviderApplicationRepository {
  SupabaseProviderApplicationRepository(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  @override
  Future<ProviderApplication?> load() async {
    final providerRow = await client
        .from('provider_profiles')
        .select(
            'user_id,display_name,bio,verification_status,is_available,rating_average,completed_jobs')
        .eq('user_id', userId)
        .maybeSingle();
    final verificationRows = await client
        .from('provider_verifications')
        .select(
            'ic_front_path,ic_back_path,selfie_path,ssm_path,certificate_paths,status,admin_note,submitted_at')
        .eq('provider_id', userId)
        .order('submitted_at', ascending: false)
        .limit(1);
    if (providerRow == null && (verificationRows as List).isEmpty) return null;

    final profileRow = await client
        .from('profiles')
        .select('display_name,full_name,phone,whatsapp,avatar_path')
        .eq('id', userId)
        .maybeSingle();
    final categoryRows = await client
        .from('provider_categories')
        .select(
            'category_id,status,submitted_at,reviewed_at,admin_note,service_categories(name_en)')
        .eq('provider_id', userId);
    final areaRows = await client
        .from('provider_areas')
        .select('area_id,areas(area_name)')
        .eq('provider_id', userId);
    final workPhotoRows = await client
        .from('provider_work_photos')
        .select('storage_path,sort_order')
        .eq('provider_id', userId)
        .order('sort_order');

    final verificationMaps =
        (verificationRows as List).whereType<Map<String, dynamic>>().toList();
    final verification = verificationMaps.isEmpty
        ? const <String, dynamic>{}
        : verificationMaps.first;
    final categoryMaps =
        (categoryRows as List).whereType<Map<String, dynamic>>().toList();
    final selections = [
      for (final row in categoryMaps)
        ProviderCategorySelection(
          category: _categoryOption(row['category_id'] as String),
          status: providerCategoryStatusFromValue(row['status'] as String?),
          submittedAt: DateTime.tryParse(row['submitted_at'] as String? ?? ''),
          reviewedAt: DateTime.tryParse(row['reviewed_at'] as String? ?? ''),
          adminNote: row['admin_note'] as String?,
        ),
    ];
    final categoryIds = categoryMaps
        .map((row) => row['category_id'])
        .whereType<String>()
        .toList();
    final areaIds = _ids(areaRows, 'area_id');
    return ProviderApplication(
      status: providerApplicationStatusFromValue(
          (verification['status'] as String?) ??
              providerRow?['verification_status'] as String?),
      displayName: (providerRow?['display_name'] as String?) ??
          (profileRow?['display_name'] as String?) ??
          (profileRow?['full_name'] as String?) ??
          'Provider',
      bio: providerRow?['bio'] as String? ?? '',
      categories: [for (final id in categoryIds) _categoryOption(id)],
      areas: [for (final id in areaIds) _areaOption(id)],
      icFrontPath: verification['ic_front_path'] as String?,
      icBackPath: verification['ic_back_path'] as String?,
      selfiePath: verification['selfie_path'] as String?,
      ssmPath: verification['ssm_path'] as String?,
      certificatePaths: _stringList(verification['certificate_paths']),
      workPhotoPaths: _workPhotoPaths(workPhotoRows),
      adminNote: verification['admin_note'] as String?,
      submittedAt:
          DateTime.tryParse(verification['submitted_at'] as String? ?? ''),
      isAvailable: providerRow?['is_available'] as bool? ?? false,
      phone: profileRow?['phone'] as String? ?? '',
      whatsapp: profileRow?['whatsapp'] as String? ?? '',
      categorySelections: List.unmodifiable(selections),
      rating: (providerRow?['rating_average'] as num?)?.toDouble() ?? 0,
      completedJobs: (providerRow?['completed_jobs'] as num?)?.toInt() ?? 0,
      avatarPath: profileRow?['avatar_path'] as String?,
    );
  }

  @override
  Future<ProviderApplication> submit(ProviderApplicationDraft draft) async {
    final validationError = draft.validate();
    if (validationError != null) throw StateError(validationError);
    final uploadedVerificationPaths = <String>[];
    final uploadedPortfolioPaths = <String>[];
    try {
      final icFront = await _upload(draft.icFrontPath, 'verification',
          'ic-front', uploadedVerificationPaths);
      final icBack = await _upload(draft.icBackPath, 'verification', 'ic-back',
          uploadedVerificationPaths);
      final selfie = await _upload(draft.selfiePath, 'verification', 'selfie',
          uploadedVerificationPaths);
      final ssm = await _upload(
          draft.ssmPath, 'verification', 'ssm', uploadedVerificationPaths);
      final certificates = <String>[];
      for (var index = 0; index < draft.certificatePaths.length; index++) {
        final path = await _upload(draft.certificatePaths[index],
            'certificates', 'certificate-$index', uploadedVerificationPaths);
        if (path != null) certificates.add(path);
      }
      final workPhotos = <String>[];
      for (var index = 0; index < draft.workPhotoPaths.length; index++) {
        final path = await _upload(draft.workPhotoPaths[index], 'work',
            'work-$index', uploadedPortfolioPaths,
            bucket: 'provider-portfolio');
        if (path != null) workPhotos.add(path);
      }
      await client.rpc('submit_provider_application', params: {
        'p_display_name': draft.displayName.trim(),
        'p_bio': draft.bio.trim(),
        'p_category_ids': draft.categoryIds,
        'p_area_ids': draft.areaIds,
        'p_ic_front_path': icFront,
        'p_ic_back_path': icBack,
        'p_selfie_path': selfie,
        'p_ssm_path': ssm,
        'p_certificate_paths': jsonEncode(certificates),
        'p_work_photo_paths': workPhotos,
      });
      return await load() ??
          ProviderApplication.demo(status: ProviderApplicationStatus.pending);
    } catch (error) {
      await _cleanup(uploadedVerificationPaths, 'provider-verifications');
      await _cleanup(uploadedPortfolioPaths, 'provider-portfolio');
      rethrow;
    }
  }

  @override
  Future<ProviderApplication> updateProfile({
    required String displayName,
    required String bio,
    required String phone,
    required String whatsapp,
    required List<ServiceAreaOption> areas,
    required List<String> workPhotoPaths,
  }) async {
    if (displayName.trim().length < 2) {
      throw StateError('Add a business or display name.');
    }
    if (bio.trim().length < 10) {
      throw StateError('Tell customers a little more about your work.');
    }
    if (areas.isEmpty) throw StateError('Choose at least one service area.');
    if (workPhotoPaths.length > 6) {
      throw StateError('Choose no more than 6 work photos.');
    }
    final uploaded = <String>[];
    try {
      final paths = <String>[];
      for (var index = 0; index < workPhotoPaths.length; index++) {
        final selected = workPhotoPaths[index];
        if (File(selected).existsSync()) {
          final uploadedPath = await _upload(
              selected, 'work', 'work-$index', uploaded,
              bucket: 'provider-portfolio');
          if (uploadedPath != null) paths.add(uploadedPath);
        } else {
          paths.add(selected);
        }
      }
      await client.rpc('update_provider_profile', params: {
        'p_display_name': displayName.trim(),
        'p_bio': bio.trim(),
        'p_phone': phone.trim().isEmpty ? null : phone.trim(),
        'p_whatsapp': whatsapp.trim().isEmpty ? null : whatsapp.trim(),
        'p_area_ids': [for (final area in areas) area.id],
        'p_work_photo_paths': paths,
      });
      return await load() ?? (throw StateError('Provider profile not found.'));
    } catch (error) {
      await _cleanup(uploaded, 'provider-portfolio');
      rethrow;
    }
  }

  @override
  Future<ProviderApplication> submitCategoryChanges(
      List<ServiceCategoryOption> categories) async {
    if (categories.isEmpty || categories.length > 6) {
      throw StateError('Choose between 1 and 6 service categories.');
    }
    await client.rpc('submit_provider_category_changes', params: {
      'p_category_ids': [for (final category in categories) category.id],
    });
    return await load() ?? (throw StateError('Provider profile not found.'));
  }

  @override
  Future<ProviderApplication> setAvailability(bool isAvailable) async {
    await client.rpc('set_provider_availability', params: {
      'p_is_available': isAvailable,
    });
    return await load() ?? (throw StateError('Provider profile not found.'));
  }

  Future<void> _cleanup(List<String> paths, String bucket) async {
    if (paths.isEmpty) return;
    try {
      if (bucket == 'provider-verifications') {
        await client.storage.from('provider-verifications').remove(paths);
      } else {
        await client.storage.from('provider-portfolio').remove(paths);
      }
    } catch (_) {
      // Preserve the original error; a later admin cleanup can remove blobs.
    }
  }

  Future<String?> _upload(String? localPath, String folder, String label,
      List<String> uploadedPaths,
      {String bucket = 'provider-verifications'}) async {
    if (localPath == null || localPath.trim().isEmpty) return null;
    final file = File(localPath);
    if (!file.existsSync()) {
      throw StateError('A selected file is no longer available.');
    }
    final extension = _extension(localPath);
    final storagePath =
        '$userId/$folder/${DateTime.now().microsecondsSinceEpoch}_$label.$extension';
    await client.storage.from(bucket).upload(storagePath, file,
        fileOptions: const FileOptions(upsert: false));
    uploadedPaths.add(storagePath);
    return storagePath;
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return 'jpg';
    final extension = path
        .substring(dot + 1)
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
    return extension.isEmpty ? 'jpg' : extension;
  }

  static List<String> _ids(dynamic rows, String key) => (rows as List)
      .whereType<Map<String, dynamic>>()
      .map((row) => row[key])
      .whereType<String>()
      .toList();

  static List<String> _stringList(dynamic value) =>
      value is List ? value.whereType<String>().toList() : const [];

  static List<String> _workPhotoPaths(dynamic rows) => (rows as List)
      .whereType<Map<String, dynamic>>()
      .map((row) => row['storage_path'])
      .whereType<String>()
      .toList();

  static ServiceCategoryOption _categoryOption(String id) =>
      serviceCategoryOptions.firstWhere((item) => item.id == id,
          orElse: () => ServiceCategoryOption(id: id, label: 'Service'));

  static ServiceAreaOption _areaOption(String id) =>
      serviceAreaOptions.firstWhere((item) => item.id == id,
          orElse: () => ServiceAreaOption(id: id, label: 'Area'));
}
