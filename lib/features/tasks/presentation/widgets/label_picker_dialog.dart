import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/neumorphic_widgets.dart';
import '../../domain/label_model.dart';
import '../label_providers.dart';

class LabelPickerDialog extends ConsumerStatefulWidget {
  final String workspaceId;
  final List<TaskLabel> currentLabels;

  const LabelPickerDialog({
    super.key,
    required this.workspaceId,
    required this.currentLabels,
  });

  @override
  ConsumerState<LabelPickerDialog> createState() => _LabelPickerDialogState();
}

class _LabelPickerDialogState extends ConsumerState<LabelPickerDialog> {
  late List<TaskLabel> _selected;
  final _newLabelController = TextEditingController();
  String _selectedColorHex = '#3B82F6';
  bool _isCreating = false;

  final List<String> _presetColors = [
    '#3B82F6', // Blue
    '#10B981', // Emerald
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#06B6D4', // Cyan
    '#71717A', // Zinc
  ];

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.currentLabels);
  }

  @override
  void dispose() {
    _newLabelController.dispose();
    super.dispose();
  }

  Color _parseColor(String hex) {
    try {
      final cleanHex = hex.replaceAll('#', '');
      return Color(int.parse('0xFF$cleanHex'));
    } catch (_) {
      return AppColors.primary;
    }
  }

  Future<void> _handleCreateLabel() async {
    final name = _newLabelController.text.trim();
    if (name.isEmpty) return;

    final created = await ref
        .read(workspaceLabelsProvider(widget.workspaceId).notifier)
        .addCustomLabel(name: name, colorHex: _selectedColorHex);

    setState(() {
      _selected.add(created);
      _newLabelController.clear();
      _isCreating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelsAsync = ref.watch(workspaceLabelsProvider(widget.workspaceId));
    final available = labelsAsync.value ?? [];

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: NeumorphicContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Title & Close Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Task Labels',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF09090B),
                      ),
                    ),
                    NeumorphicIconButton(
                      icon: Icons.close_rounded,
                      size: 34,
                      iconSize: 18,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select labels to apply to this task:',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                // Labels chip wrap
                if (available.isEmpty && labelsAsync.isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: available.map((label) {
                      final isSelected = _selected.any((l) => l.id == label.id);
                      final color = _parseColor(label.colorHex);

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selected.removeWhere((l) => l.id == label.id);
                            } else {
                              _selected.add(label);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: isSelected
                                ? color.withAlpha(isDark ? 50 : 35)
                                : (isDark ? NeumorphicColors.darkSurfaceTop : NeumorphicColors.lightSurfaceTop),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : (isDark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(15)),
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withAlpha(isDark ? 70 : 40),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? color : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_rounded, size: 14, color: color),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 18),

                // Divider line with subtle neumorphic indentation
                Container(
                  height: 1,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.black12,
                  ),
                ),
                const SizedBox(height: 16),

                // Create Custom Label Section
                if (!_isCreating)
                  GestureDetector(
                    onTap: () => setState(() => _isCreating = true),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Create New Label',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Text(
                    'Create New Label',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: NeumorphicContainer(
                          isPressed: true,
                          borderRadius: 12,
                          depth: 0.8,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                          child: TextField(
                            controller: _newLabelController,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            cursorColor: AppColors.primary,
                            decoration: InputDecoration(
                              hintText: 'Label name (e.g. Critical)',
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: isDark ? Colors.white30 : Colors.black38,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      NeumorphicIconButton(
                        icon: Icons.check_rounded,
                        size: 38,
                        iconSize: 18,
                        iconColor: AppColors.primary,
                        onTap: _handleCreateLabel,
                        tooltip: 'Save Label',
                      ),
                      const SizedBox(width: 6),
                      NeumorphicIconButton(
                        icon: Icons.close_rounded,
                        size: 38,
                        iconSize: 18,
                        onTap: () => setState(() => _isCreating = false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: _presetColors.map((hex) {
                      final isCurrent = _selectedColorHex == hex;
                      final c = _parseColor(hex);
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorHex = hex),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isCurrent ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isCurrent
                                ? [BoxShadow(color: c.withAlpha(140), blurRadius: 8, spreadRadius: 1)]
                                : null,
                          ),
                          child: isCurrent
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],

                const SizedBox(height: 22),

                // Footer Actions
                Row(
                  children: [
                    Expanded(
                      child: NeumorphicButton(
                        label: 'Cancel',
                        isOutlined: true,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: NeumorphicButton(
                        label: 'Apply',
                        color: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        onPressed: () => Navigator.of(context).pop(_selected),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
