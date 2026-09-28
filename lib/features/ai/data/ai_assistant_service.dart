import 'dart:async';
import '../domain/ai_action_result.dart';
import '../../tasks/domain/task_model.dart';

abstract class AiAssistantService {
  Future<List<AiSubtaskSuggestion>> generateSubtasks({
    required String taskTitle,
    String? taskDescription,
  });

  Future<AiTaskAnalysis> analyzeTask({
    required TaskItem task,
    List<String>? recentComments,
  });

  Future<List<AiProjectIdea>> brainstormTasks({
    required String projectName,
    String? projectDescription,
    List<TaskItem>? existingTasks,
  });
}

class LocalRuleBasedAiService implements AiAssistantService {
  @override
  Future<List<AiSubtaskSuggestion>> generateSubtasks({
    required String taskTitle,
    String? taskDescription,
  }) async {
    // Simulate natural AI thinking delay
    await Future.delayed(const Duration(milliseconds: 350));

    final text = '${taskTitle.toLowerCase()} ${taskDescription?.toLowerCase() ?? ''}';

    if (text.contains('auth') ||
        text.contains('login') ||
        text.contains('signup') ||
        text.contains('password') ||
        text.contains('oauth')) {
      return [
        AiSubtaskSuggestion(title: 'Design responsive credentials form & inputs', estimatedMinutes: 45),
        AiSubtaskSuggestion(title: 'Implement input validation & sanitization', estimatedMinutes: 30),
        AiSubtaskSuggestion(title: 'Integrate Supabase Auth / JWT session storage', estimatedMinutes: 60),
        AiSubtaskSuggestion(title: 'Add password reset & email verification flows', estimatedMinutes: 45),
        AiSubtaskSuggestion(title: 'Write automated unit tests for auth state provider', estimatedMinutes: 30),
      ];
    }

    if (text.contains('design') ||
        text.contains('ui') ||
        text.contains('theme') ||
        text.contains('layout') ||
        text.contains('screen') ||
        text.contains('widget')) {
      return [
        AiSubtaskSuggestion(title: 'Define typography scale & HSL color tokens', estimatedMinutes: 30),
        AiSubtaskSuggestion(title: 'Build component skeleton with dark/light theme support', estimatedMinutes: 60),
        AiSubtaskSuggestion(title: 'Add micro-interactions and smooth spring transitions', estimatedMinutes: 45),
        AiSubtaskSuggestion(title: 'Verify accessibility and WCAG AA contrast ratios', estimatedMinutes: 20),
        AiSubtaskSuggestion(title: 'Conduct cross-device tablet/desktop responsiveness review', estimatedMinutes: 30),
      ];
    }

    if (text.contains('api') ||
        text.contains('backend') ||
        text.contains('database') ||
        text.contains('schema') ||
        text.contains('sync') ||
        text.contains('endpoint')) {
      return [
        AiSubtaskSuggestion(title: 'Draft OpenAPI specification & JSON response types', estimatedMinutes: 30),
        AiSubtaskSuggestion(title: 'Write database migrations & apply RLS security policies', estimatedMinutes: 45),
        AiSubtaskSuggestion(title: 'Implement local caching & optimistic mutation handlers', estimatedMinutes: 60),
        AiSubtaskSuggestion(title: 'Configure error retry policies and exponential backoff', estimatedMinutes: 30),
        AiSubtaskSuggestion(title: 'Perform load test and query performance profiling', estimatedMinutes: 40),
      ];
    }

    if (text.contains('bug') ||
        text.contains('fix') ||
        text.contains('issue') ||
        text.contains('error') ||
        text.contains('crash')) {
      return [
        AiSubtaskSuggestion(title: 'Reproduce bug with minimal isolated test case', estimatedMinutes: 20),
        AiSubtaskSuggestion(title: 'Trace state management mutation chain & root cause', estimatedMinutes: 35),
        AiSubtaskSuggestion(title: 'Implement code fix and handle missing edge condition', estimatedMinutes: 30),
        AiSubtaskSuggestion(title: 'Add regression test to CI pipeline', estimatedMinutes: 25),
        AiSubtaskSuggestion(title: 'Verify fix on physical Android/iOS devices', estimatedMinutes: 20),
      ];
    }

    // Default intelligent technical breakdown
    return [
      AiSubtaskSuggestion(title: 'Review specifications & align on acceptance criteria', estimatedMinutes: 20),
      AiSubtaskSuggestion(title: 'Implement core functionality and data models', estimatedMinutes: 60),
      AiSubtaskSuggestion(title: 'Handle boundary states, loading animations & errors', estimatedMinutes: 30),
      AiSubtaskSuggestion(title: 'Write automated unit & widget test coverage', estimatedMinutes: 35),
      AiSubtaskSuggestion(title: 'Conduct peer review & prepare production pull request', estimatedMinutes: 25),
    ];
  }

  @override
  Future<AiTaskAnalysis> analyzeTask({
    required TaskItem task,
    List<String>? recentComments,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final hasSubtasks = task.subtasks.isNotEmpty;
    final totalSubtasks = task.subtasks.length;
    final completedSubtasks = task.subtasks.where((s) => s.isCompleted).length;
    final isDone = task.status == TaskStatus.done;
    final isOverdue = task.dueDate != null && task.dueDate!.isBefore(DateTime.now()) && !isDone;

    String summary;
    String statusEvaluation;
    String suggestedNextAction;
    String recommendedPriority = task.priority.name.toUpperCase();
    final List<String> keyRisks = [];

    if (isDone) {
      summary = 'Task is complete and all deliverables have been satisfied.';
      statusEvaluation = 'Completed (100%)';
      suggestedNextAction = 'Archive or celebrate milestone with the team!';
    } else if (isOverdue) {
      summary = 'Task is behind schedule! Past target due date.';
      statusEvaluation = 'At Risk - Overdue';
      recommendedPriority = 'URGENT';
      keyRisks.add('Target delivery date passed without final closure.');
      if (task.assigneeName == null) {
        keyRisks.add('Unassigned task with pending deliverables.');
        suggestedNextAction = 'Immediately assign task to an active team member.';
      } else {
        suggestedNextAction = 'Ping ${task.assigneeName} for an immediate progress blocker check.';
      }
    } else if (hasSubtasks) {
      final percent = (task.subtaskProgress * 100).round();
      summary = '$completedSubtasks of $totalSubtasks checklist milestones completed ($percent%).';
      if (percent < 50) {
        statusEvaluation = 'In Progress - Initial Stage';
        final pending = task.subtasks.where((s) => !s.isCompleted).first;
        suggestedNextAction = 'Focus on finishing checklist item: "${pending.title}".';
      } else {
        statusEvaluation = 'In Progress - Near Completion';
        final pending = task.subtasks.where((s) => !s.isCompleted).first;
        suggestedNextAction = 'Tackle final remaining subtask: "${pending.title}".';
      }
    } else {
      summary = 'Active task without checklist breakdown.';
      statusEvaluation = 'Needs Breakdown';
      suggestedNextAction = 'Use "AI Breakdown" to generate actionable subtasks for this item.';
      if (task.assigneeName == null) {
        keyRisks.add('No member assigned yet.');
      }
    }

    final suggestedSubtasks = await generateSubtasks(
      taskTitle: task.title,
      taskDescription: task.description,
    );

    return AiTaskAnalysis(
      summary: summary,
      statusEvaluation: statusEvaluation,
      suggestedNextAction: suggestedNextAction,
      recommendedPriority: recommendedPriority,
      keyRisks: keyRisks,
      suggestedSubtasks: suggestedSubtasks,
    );
  }

  @override
  Future<List<AiProjectIdea>> brainstormTasks({
    required String projectName,
    String? projectDescription,
    List<TaskItem>? existingTasks,
  }) async {
    await Future.delayed(const Duration(milliseconds: 350));

    return [
      const AiProjectIdea(
        title: 'CI/CD Pipeline with GitHub Actions',
        description: 'Automate linting, unit test validation, and multi-platform build artifacts on every push.',
        priority: 'HIGH',
        category: 'DevOps & Tooling',
      ),
      const AiProjectIdea(
        title: 'Biometric App Lock & PIN Security',
        description: 'Secure sensitive workspace data with Face ID, Touch ID, and hardware key storage.',
        priority: 'MEDIUM',
        category: 'Security',
      ),
      const AiProjectIdea(
        title: 'CSV & PDF Sprint Report Exporter',
        description: 'Export velocity graphs, completed task breakdowns, and timesheet logs for stakeholders.',
        priority: 'MEDIUM',
        category: 'Reporting & Analytics',
      ),
      const AiProjectIdea(
        title: 'Live Presence Typing & Cursor Broadcast',
        description: 'Stream cursor position and active typing indicators across teammates in real-time.',
        priority: 'LOW',
        category: 'Collaboration',
      ),
    ];
  }
}
