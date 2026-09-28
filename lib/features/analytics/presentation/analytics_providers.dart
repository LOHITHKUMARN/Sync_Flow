import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../tasks/presentation/task_providers.dart';
import '../domain/project_analytics.dart';

final projectAnalyticsProvider = Provider.family<ProjectAnalytics, String>((ref, projectId) {
  final tasksAsync = ref.watch(tasksNotifierProvider(projectId));
  final tasks = tasksAsync.value ?? [];
  return ProjectAnalytics.fromTasks(tasks);
});
