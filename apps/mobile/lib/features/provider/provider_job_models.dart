import '../../core/models/app_models.dart';

enum ProviderJobSort { newest, noBids, highestBudget, soonest }

extension ProviderJobSortLabel on ProviderJobSort {
  String get label {
    switch (this) {
      case ProviderJobSort.newest:
        return 'Newest';
      case ProviderJobSort.noBids:
        return 'No bids yet';
      case ProviderJobSort.highestBudget:
        return 'Highest budget';
      case ProviderJobSort.soonest:
        return 'Soonest service';
    }
  }
}

class ProviderJobFilters {
  const ProviderJobFilters({
    this.categoryId,
    this.categoryLabel,
    this.areaId,
    this.areaLabel,
    this.serviceDate,
    this.minBudget,
    this.maxBudget,
    this.urgentOnly = false,
    this.noBidsOnly = false,
    this.sort = ProviderJobSort.newest,
  });

  final String? categoryId;
  final String? categoryLabel;
  final String? areaId;
  final String? areaLabel;
  final DateTime? serviceDate;
  final double? minBudget;
  final double? maxBudget;
  final bool urgentOnly;
  final bool noBidsOnly;
  final ProviderJobSort sort;

  bool get isDefault =>
      categoryId == null &&
      areaId == null &&
      serviceDate == null &&
      minBudget == null &&
      maxBudget == null &&
      !urgentOnly &&
      !noBidsOnly &&
      sort == ProviderJobSort.newest;

  bool matches(Job job) {
    if (categoryId != null && job.categoryId != categoryId) return false;
    if (categoryId == null && categoryLabel != null && job.category != categoryLabel) return false;
    if (areaId != null && job.areaId != areaId) return false;
    if (areaId == null && areaLabel != null && job.area != areaLabel) return false;
    if (urgentOnly && !job.urgent) return false;
    if (noBidsOnly && job.bidCount != 0) return false;
    if (minBudget != null && job.budget < minBudget!) return false;
    if (maxBudget != null && job.budget > maxBudget!) return false;
    if (serviceDate != null) {
      final scheduled = job.scheduledAt;
      if (scheduled == null || !_sameDate(scheduled, serviceDate!)) return false;
    }
    return true;
  }

  List<Job> apply(List<Job> jobs) {
    final result = jobs.where(matches).toList();
    result.sort((a, b) {
      switch (sort) {
        case ProviderJobSort.newest:
          return _dateValue(b.createdAt).compareTo(_dateValue(a.createdAt));
        case ProviderJobSort.noBids:
          final byCount = a.bidCount.compareTo(b.bidCount);
          return byCount == 0 ? _dateValue(b.createdAt).compareTo(_dateValue(a.createdAt)) : byCount;
        case ProviderJobSort.highestBudget:
          final byBudget = b.budget.compareTo(a.budget);
          return byBudget == 0 ? _dateValue(b.createdAt).compareTo(_dateValue(a.createdAt)) : byBudget;
        case ProviderJobSort.soonest:
          return _dateValue(a.scheduledAt ?? a.createdAt).compareTo(_dateValue(b.scheduledAt ?? b.createdAt));
      }
    });
    return result;
  }

  ProviderJobFilters copyWith({
    String? categoryId,
    String? categoryLabel,
    String? areaId,
    String? areaLabel,
    DateTime? serviceDate,
    double? minBudget,
    double? maxBudget,
    bool? urgentOnly,
    bool? noBidsOnly,
    ProviderJobSort? sort,
    bool clearCategory = false,
    bool clearArea = false,
    bool clearServiceDate = false,
    bool clearMinBudget = false,
    bool clearMaxBudget = false,
  }) {
    return ProviderJobFilters(
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      categoryLabel: clearCategory ? null : categoryLabel ?? this.categoryLabel,
      areaId: clearArea ? null : areaId ?? this.areaId,
      areaLabel: clearArea ? null : areaLabel ?? this.areaLabel,
      serviceDate: clearServiceDate ? null : serviceDate ?? this.serviceDate,
      minBudget: clearMinBudget ? null : minBudget ?? this.minBudget,
      maxBudget: clearMaxBudget ? null : maxBudget ?? this.maxBudget,
      urgentOnly: urgentOnly ?? this.urgentOnly,
      noBidsOnly: noBidsOnly ?? this.noBidsOnly,
      sort: sort ?? this.sort,
    );
  }

  static DateTime _dateValue(DateTime? value) => value ?? DateTime.fromMillisecondsSinceEpoch(0);

  static bool _sameDate(DateTime left, DateTime right) => left.year == right.year && left.month == right.month && left.day == right.day;
}

class BidDraft {
  const BidDraft({
    required this.jobId,
    required this.amount,
    required this.availableAt,
    required this.inclusions,
    required this.exclusions,
    required this.materialsNote,
    required this.message,
    this.bidId,
  });

  final String? bidId;
  final String jobId;
  final String amount;
  final DateTime availableAt;
  final String inclusions;
  final String exclusions;
  final String materialsNote;
  final String message;

  double? get amountValue => double.tryParse(amount.trim());

  String? validate() {
    if (amountValue == null || amountValue! <= 0) return 'Enter a bid amount greater than RM0.';
    if (inclusions.trim().isEmpty) return 'Explain what your bid includes.';
    if (inclusions.trim().length > 2000) return 'Keep inclusions under 2,000 characters.';
    if (exclusions.trim().length > 2000) return 'Keep exclusions under 2,000 characters.';
    if (materialsNote.trim().length > 500) return 'Keep the materials note under 500 characters.';
    if (message.trim().length > 1000) return 'Keep the additional note under 1,000 characters.';
    return null;
  }
}

class ProviderBid {
  const ProviderBid({required this.bid, this.job});

  final Bid bid;
  final Job? job;
}

class ProviderJobState {
  const ProviderJobState({
    this.initialized = false,
    this.isLoading = false,
    this.isSubmitting = false,
    this.jobs = const [],
    this.myBids = const [],
    this.filters = const ProviderJobFilters(),
    this.error,
  });

  final bool initialized;
  final bool isLoading;
  final bool isSubmitting;
  final List<Job> jobs;
  final List<ProviderBid> myBids;
  final ProviderJobFilters filters;
  final String? error;

  List<Job> get visibleJobs => filters.apply(jobs);

  ProviderJobState copyWith({
    bool? initialized,
    bool? isLoading,
    bool? isSubmitting,
    List<Job>? jobs,
    List<ProviderBid>? myBids,
    ProviderJobFilters? filters,
    String? error,
    bool clearError = false,
  }) {
    return ProviderJobState(
      initialized: initialized ?? this.initialized,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      jobs: jobs ?? this.jobs,
      myBids: myBids ?? this.myBids,
      filters: filters ?? this.filters,
      error: clearError ? null : error ?? this.error,
    );
  }
}
