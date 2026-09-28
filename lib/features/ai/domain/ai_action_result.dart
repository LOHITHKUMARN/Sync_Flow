class AiSubtaskSuggestion {
  final String title;
  final int estimatedMinutes;
  bool isSelected;

  AiSubtaskSuggestion({
    required this.title,
    this.estimatedMinutes = 30,
    this.isSelected = true,
  });
}

class AiTaskAnalysis {
  final String summary;
  final String statusEvaluation;
  final String suggestedNextAction;
  final String recommendedPriority;
  final List<String> keyRisks;
  final List<AiSubtaskSuggestion> suggestedSubtasks;

  const AiTaskAnalysis({
    required this.summary,
    required this.statusEvaluation,
    required this.suggestedNextAction,
    required this.recommendedPriority,
    this.keyRisks = const [],
    this.suggestedSubtasks = const [],
  });
}

class AiProjectIdea {
  final String title;
  final String description;
  final String priority;
  final String category;

  const AiProjectIdea({
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
  });
}
