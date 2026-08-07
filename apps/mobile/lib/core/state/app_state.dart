import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_data.dart';
import '../models/app_models.dart';

final appModeProvider = StateProvider<AppMode>((ref) => AppMode.customer);
final fakeJobsProvider = Provider<List<Job>>((ref) => fakeJobs);
final fakeBidsProvider = Provider<List<Bid>>((ref) => fakeBids);
