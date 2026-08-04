import 'dart:convert';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/service_options.dart';
import 'provider_application_models.dart';

abstract interface class ProviderApplicationRepository {
  Future<ProviderApplication?> load();
  Future<ProviderApplication> submit(ProviderApplicationDraft draft);
}

class FakeProviderApplicationRepository implements ProviderApplicationRepository {
  FakeProviderApplicationRepository({ProviderApplicationStatus initialStatus = ProviderApplicationStatus.approved}) : _application = ProviderApplication.demo(status: initialStatus);

  ProviderApplication _application;

  @override
  Future<ProviderApplication?> load() async => _application.status == ProviderApplicationStatus.notApplied ? null : _application;

  @override
  Future<ProviderApplication> submit(ProviderApplicationDraft draft) async {
    final error = draft.validate();
    if (error != null) throw StateError(error);
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
      submittedAt: DateTime.now(),
      isAvailable: false,
    );
    return _application;
  }
}

class SupabaseProviderApplicationRepository implements ProviderApplicationRepository {
  SupabaseProviderApplicationRepository(this.client, this.userId);

  final SupabaseClient client;
  final String userId;

  @override
  Future<ProviderApplication?> load() async {
    final providerRow = await client.from('provider_profiles').select('user_id,bio,verification_status,is_available').eq('user_id', userId).maybeSingle();
    final verificationRows = await client.from('provider_verifications').select('ic_front_path,ic_back_path,selfie_path,ssm_path,certificate_paths,status,admin_note,submitted_at').eq('provider_id', userId).order('submitted_at', ascending: false).limit(1);
    if (providerRow == null && (verificationRows as List).isEmpty) return null;

    final profileRow = await client.from('profiles').select('display_name,full_name').eq('id', userId).maybeSingle();
    final categoryRows = await client.from('provider_categories').select('category_id,service_categories(name_en)').eq('provider_id', userId);
    final areaRows = await client.from('provider_areas').select('area_id,areas(area_name)').eq('provider_id', userId);
    final workPhotoRows = await client.from('provider_work_photos').select('storage_path,sort_order').eq('provider_id', userId).order('sort_order');

    final verificationMaps = (verificationRows as List).whereType<Map<String, dynamic>>().toList();
    final verification = verificationMaps.isEmpty ? const <String, dynamic>{} : verificationMaps.first;
    final categoryIds = _ids(categoryRows, 'category_id');
    final areaIds = _ids(areaRows, 'area_id');
    return ProviderApplication(
      status: providerApplicationStatusFromValue((verification['status'] as String?) ?? providerRow?['verification_status'] as String?),
      displayName: (profileRow?['display_name'] as String?) ?? (profileRow?['full_name'] as String?) ?? 'Provider',
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
      submittedAt: DateTime.tryParse(verification['submitted_at'] as String? ?? ''),
      isAvailable: providerRow?['is_available'] as bool? ?? false,
    );
  }

  @override
  Future<ProviderApplication> submit(ProviderApplicationDraft draft) async {
    final validationError = draft.validate();
    if (validationError != null) throw StateError(validationError);
    final uploadedPaths = <String>[];
    try {
      final icFront = await _upload(draft.icFrontPath, 'verification', 'ic-front', uploadedPaths);
      final icBack = await _upload(draft.icBackPath, 'verification', 'ic-back', uploadedPaths);
      final selfie = await _upload(draft.selfiePath, 'verification', 'selfie', uploadedPaths);
      final ssm = await _upload(draft.ssmPath, 'verification', 'ssm', uploadedPaths);
      final certificates = <String>[];
      for (var index = 0; index < draft.certificatePaths.length; index++) {
        final path = await _upload(draft.certificatePaths[index], 'certificates', 'certificate-$index', uploadedPaths);
        if (path != null) certificates.add(path);
      }
      final workPhotos = <String>[];
      for (var index = 0; index < draft.workPhotoPaths.length; index++) {
        final path = await _upload(draft.workPhotoPaths[index], 'work', 'work-$index', uploadedPaths);
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
      return await load() ?? ProviderApplication.demo(status: ProviderApplicationStatus.pending);
    } catch (error) {
      if (uploadedPaths.isNotEmpty) {
        try {
          await client.storage.from('provider-verifications').remove(uploadedPaths);
        } catch (_) {
          // Preserve the original submission error; cleanup can be retried by an admin.
        }
      }
      rethrow;
    }
  }

  Future<String?> _upload(String? localPath, String folder, String label, List<String> uploadedPaths) async {
    if (localPath == null || localPath.trim().isEmpty) return null;
    final file = File(localPath);
    if (!file.existsSync()) throw StateError('A selected verification file is no longer available.');
    final extension = _extension(localPath);
    final storagePath = '$userId/$folder/${DateTime.now().microsecondsSinceEpoch}_$label.$extension';
    await client.storage.from('provider-verifications').upload(storagePath, file, fileOptions: const FileOptions(upsert: false));
    uploadedPaths.add(storagePath);
    return storagePath;
  }

  static String _extension(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return 'jpg';
    final extension = path.substring(dot + 1).toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    return extension.isEmpty ? 'jpg' : extension;
  }

  static List<String> _ids(dynamic rows, String key) => (rows as List).whereType<Map<String, dynamic>>().map((row) => row[key]).whereType<String>().toList();

  static List<String> _stringList(dynamic value) => value is List ? value.whereType<String>().toList() : const [];

  static List<String> _workPhotoPaths(dynamic rows) => (rows as List).whereType<Map<String, dynamic>>().map((row) => row['storage_path']).whereType<String>().toList();

  static ServiceCategoryOption _categoryOption(String id) => serviceCategoryOptions.firstWhere((item) => item.id == id, orElse: () => ServiceCategoryOption(id: id, label: 'Service'));

  static ServiceAreaOption _areaOption(String id) => serviceAreaOptions.firstWhere((item) => item.id == id, orElse: () => ServiceAreaOption(id: id, label: 'Area'));
}
