import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/models/service_options.dart';
import '../../core/validation/image_validation.dart';
import '../../shared/widgets/app_widgets.dart';
import 'provider_application_controller.dart';
import 'provider_application_models.dart';

class ProviderProfileEditScreen extends ConsumerStatefulWidget {
  const ProviderProfileEditScreen({super.key});

  @override
  ConsumerState<ProviderProfileEditScreen> createState() =>
      _ProviderProfileEditScreenState();
}

class _ProviderProfileEditScreenState
    extends ConsumerState<ProviderProfileEditScreen> {
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _picker = ImagePicker();
  final _categories = <ServiceCategoryOption>[];
  final _areas = <ServiceAreaOption>[];
  List<String> _workPhotos = [];
  bool _available = false;
  bool _hydrated = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  void _hydrate(ProviderApplication? application) {
    if (_hydrated || application == null) return;
    _hydrated = true;
    _displayNameController.text = application.displayName;
    _bioController.text = application.bio;
    _phoneController.text = application.phone;
    _whatsappController.text = application.whatsapp;
    _categories.addAll(application.categories);
    _areas.addAll(application.areas);
    _workPhotos = [...application.workPhotoPaths];
    _available = application.isAvailable;
  }

  Future<void> _pickWorkPhotos() async {
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    final next = [..._workPhotos, ...picked.map((file) => file.path)];
    final localPaths = next.where((path) => File(path).existsSync()).toList();
    final result = await ImageValidation.validatePaths(localPaths, maxCount: 6);
    if (!mounted) return;
    if (!result.isValid) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(result.error!)));
      return;
    }
    setState(() => _workPhotos = next.take(6).toList());
  }

  Future<void> _save() async {
    final controller = ref.read(providerApplicationControllerProvider.notifier);
    final application =
        ref.read(providerApplicationControllerProvider).application;
    if (application == null) return;
    final updated = await controller.updateProfile(
      displayName: _displayNameController.text,
      bio: _bioController.text,
      phone: _phoneController.text,
      whatsapp: _whatsappController.text,
      areas: _areas,
      workPhotoPaths: _workPhotos,
    );
    if (!mounted || updated == null) return;
    if (application.status == ProviderApplicationStatus.approved) {
      final withCategories =
          await controller.submitCategoryChanges(_categories);
      if (!mounted || withCategories == null) return;
      final current =
          ref.read(providerApplicationControllerProvider).application;
      if (current != null && current.isAvailable != _available) {
        final withAvailability = await controller.setAvailability(_available);
        if (!mounted || withAvailability == null) return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Provider profile updated.')));
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(providerApplicationControllerProvider);
    _hydrate(state.application);
    final application = state.application;
    if (!state.initialized || application == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Edit Provider Profile',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
              SizedBox(height: 6),
              Text(
                  'Keep your public profile and job matching preferences up to date.'),
            ],
          ),
        ),
        _section(
          title: 'Public profile',
          child: Column(
            children: [
              TextField(
                controller: _displayNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Display name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _whatsappController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'WhatsApp'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _section(
          title: 'Service categories',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'New categories stay hidden from your feed until Admin approves them.'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final category in serviceCategoryOptions)
                    FilterChip(
                      label: Text(category.label),
                      selected:
                          _categories.any((item) => item.id == category.id),
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            if (_categories.length < 6) {
                              _categories.add(category);
                            }
                          } else {
                            _categories
                                .removeWhere((item) => item.id == category.id);
                          }
                        });
                      },
                    ),
                ],
              ),
              if (application.categorySelections.isNotEmpty) ...[
                const SizedBox(height: 12),
                for (final item in application.categorySelections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Expanded(child: Text(item.category.label)),
                        _statusChip(item.status),
                      ],
                    ),
                  ),
                for (final item in application.categorySelections)
                  if (item.status == ProviderCategoryStatus.rejected &&
                      (item.adminNote?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('Admin note: ${item.adminNote}',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.error)),
                    ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _section(
          title: 'Service areas',
          child: Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final area in serviceAreaOptions)
                FilterChip(
                  label: Text(area.label),
                  selected: _areas.any((item) => item.id == area.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        if (_areas.length < 10) _areas.add(area);
                      } else {
                        _areas.removeWhere((item) => item.id == area.id);
                      }
                    });
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _section(
          title: 'Portfolio',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var index = 0; index < _workPhotos.length; index++)
                    InputChip(
                      label: Text('Work photo ${index + 1}'),
                      onDeleted: () =>
                          setState(() => _workPhotos.removeAt(index)),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickWorkPhotos,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Add work photos'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _available,
          onChanged: (value) => setState(() => _available = value),
          title: const Text('Available for new jobs'),
          subtitle: const Text(
              'Turn off to hide new matching requests. Existing bids and assigned jobs remain.'),
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(state.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        PrimaryButton(
          label: state.isLoading ? 'Saving...' : 'Save profile',
          onPressed: state.isLoading ? null : _save,
        ),
        const SizedBox(height: 8),
        SecondaryButton(
          label: 'Cancel',
          onPressed: state.isLoading ? null : () => context.pop(),
        ),
      ],
    );
  }

  Widget _section({required String title, required Widget child}) => Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      );

  Widget _statusChip(ProviderCategoryStatus status) {
    final label = switch (status) {
      ProviderCategoryStatus.approved => 'Approved',
      ProviderCategoryStatus.pending => 'Pending',
      ProviderCategoryStatus.rejected => 'Rejected',
    };
    return Chip(label: Text(label));
  }
}
