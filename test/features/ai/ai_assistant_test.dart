import 'package:flutter_test/flutter_test.dart';
import 'package:sync_flow/features/ai/data/ai_assistant_service.dart';
import 'package:sync_flow/features/tasks/domain/task_model.dart';
import 'package:sync_flow/features/tasks/domain/subtask_model.dart';

void main() {
  late LocalRuleBasedAiService aiService;

  setUp(() {
    aiService = LocalRuleBasedAiService();
  });

  group('AiAssistantService - generateSubtasks', () {
    test('generates authentication-specific subtasks for auth tasks', () async {
      final subtasks = await aiService.generateSubtasks(
        taskTitle: 'Implement User Login with Supabase',
        taskDescription: 'Add credentials form, error toast, and session tokens',
      );

      expect(subtasks.isNotEmpty, isTrue);
      expect(subtasks.length, greaterThanOrEqualTo(4));
      expect(
        subtasks.any((s) => s.title.toLowerCase().contains('validation') || s.title.toLowerCase().contains('auth')),
        isTrue,
      );
    });

    test('generates design-specific subtasks for UI tasks', () async {
      final subtasks = await aiService.generateSubtasks(
        taskTitle: 'Design System & Typography Tokens',
        taskDescription: 'Define theme palettes and reusable UI widgets',
      );

      expect(subtasks.isNotEmpty, isTrue);
      expect(
        subtasks.any((s) => s.title.toLowerCase().contains('theme') || s.title.toLowerCase().contains('typography') || s.title.toLowerCase().contains('tokens')),
        isTrue,
      );
    });

    test('generates API & database subtasks for backend tasks', () async {
      final subtasks = await aiService.generateSubtasks(
        taskTitle: 'PostgreSQL Database Migrations and Sync API',
      );

      expect(subtasks.isNotEmpty, isTrue);
      expect(
        subtasks.any((s) => s.title.toLowerCase().contains('database') || s.title.toLowerCase().contains('openapi') || s.title.toLowerCase().contains('rls')),
        isTrue,
      );
    });

    test('generates standard structured breakdown for general tasks', () async {
      final subtasks = await aiService.generateSubtasks(
        taskTitle: 'Conduct quarterly team retrospective',
      );

      expect(subtasks.isNotEmpty, isTrue);
      expect(subtasks.first.isSelected, isTrue);
      expect(subtasks.first.estimatedMinutes, greaterThan(0));
    });
  });

  group('AiAssistantService - analyzeTask', () {
    test('identifies overdue task risks and urgent priority', () async {
      final task = TaskItem(
        id: 't-overdue',
        projectId: 'p-1',
        title: 'Overdue feature deliverable',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        dueDate: DateTime.now().subtract(const Duration(days: 3)),
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      );

      final analysis = await aiService.analyzeTask(task: task);

      expect(analysis.statusEvaluation, contains('Overdue'));
      expect(analysis.recommendedPriority, 'URGENT');
      expect(analysis.keyRisks.isNotEmpty, isTrue);
    });

    test('evaluates subtask progress accuracy', () async {
      final task = TaskItem(
        id: 't-prog',
        projectId: 'p-1',
        title: 'Task with subtasks',
        status: TaskStatus.inProgress,
        priority: TaskPriority.medium,
        subtasks: [
          TaskSubtask(id: 's1', taskId: 't-prog', title: 'Subtask 1', isCompleted: true, createdAt: DateTime.now()),
          TaskSubtask(id: 's2', taskId: 't-prog', title: 'Subtask 2', isCompleted: false, createdAt: DateTime.now()),
          TaskSubtask(id: 's3', taskId: 't-prog', title: 'Subtask 3', isCompleted: false, createdAt: DateTime.now()),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final analysis = await aiService.analyzeTask(task: task);

      expect(analysis.summary, contains('1 of 3'));
      expect(analysis.suggestedNextAction, contains('Subtask 2'));
    });

    test('evaluates completed task appropriately', () async {
      final task = TaskItem(
        id: 't-done',
        projectId: 'p-1',
        title: 'Finished feature',
        status: TaskStatus.done,
        priority: TaskPriority.low,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final analysis = await aiService.analyzeTask(task: task);

      expect(analysis.statusEvaluation, contains('Completed'));
      expect(analysis.suggestedNextAction, contains('Archive'));
    });
  });

  group('AiAssistantService - brainstormTasks', () {
    test('returns high-impact backlog ideas for a project', () async {
      final ideas = await aiService.brainstormTasks(projectName: 'Mobile App');

      expect(ideas.length, greaterThanOrEqualTo(3));
      expect(ideas.any((i) => i.category.isNotEmpty), isTrue);
      expect(ideas.every((i) => i.title.isNotEmpty && i.description.isNotEmpty), isTrue);
    });
  });
}
