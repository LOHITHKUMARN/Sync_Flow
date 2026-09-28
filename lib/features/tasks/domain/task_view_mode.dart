enum TaskViewMode {
  board,
  list,
  calendar;

  String get label {
    switch (this) {
      case TaskViewMode.board:
        return 'Board';
      case TaskViewMode.list:
        return 'List';
      case TaskViewMode.calendar:
        return 'Calendar';
    }
  }
}

enum TaskListSortBy {
  dueDate,
  priority,
  status,
  title,
}
