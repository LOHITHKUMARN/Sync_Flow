import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ai_assistant_service.dart';
import '../domain/ai_action_result.dart';
import '../../tasks/domain/task_model.dart';

final aiAssistantServiceProvider = Provider<AiAssistantService>((ref) {
  return LocalRuleBasedAiService();
});

final aiTaskBreakdownProvider =
    FutureProvider.family<List<AiSubtaskSuggestion>, ({String title, String? description})>(
  (ref, arg) async {
    final service = ref.watch(aiAssistantServiceProvider);
    return service.generateSubtasks(
      taskTitle: arg.title,
      taskDescription: arg.description,
    );
  },
);

final aiTaskAnalysisProvider =
    FutureProvider.family<AiTaskAnalysis, TaskItem>((ref, task) async {
  final service = ref.watch(aiAssistantServiceProvider);
  return service.analyzeTask(task: task);
});

final aiBrainstormProvider =
    FutureProvider.family<List<AiProjectIdea>, String>((ref, projectName) async {
  final service = ref.watch(aiAssistantServiceProvider);
  return service.brainstormTasks(projectName: projectName);
});
