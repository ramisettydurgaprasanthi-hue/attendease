import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../screens/add_subject_screen.dart';
import '../theme/ui_colors.dart';

const _dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

class SubjectCard extends StatelessWidget {
  final Subject subject;

  const SubjectCard({super.key, required this.subject});

  Color _statusColor(double target) {
    if (subject.total == 0) return Colors.grey;
    if (subject.percentage >= target) return UiColors.success;
    if (subject.percentage >= target - 10) return UiColors.warning;
    return UiColors.danger;
  }

  IconData _statusIcon(double target) {
    if (subject.total == 0) return Icons.info_outline;
    if (subject.percentage >= target) return Icons.check_circle_outline;
    return Icons.warning_amber_rounded;
  }

  String _message(double target) {
    if (subject.total == 0) return 'No classes marked yet';
    if (subject.percentage >= target) {
      final n = subject.classesCanMiss(target);
      return n == 0
          ? 'On track, but you cannot miss the next class'
          : 'You can miss $n more ${n == 1 ? 'class' : 'classes'}';
    }
    final n = subject.classesNeeded(target);
    return 'Attend the next $n ${n == 1 ? 'class' : 'classes'} to reach ${target.round()}%';
  }

  Future<void> _markOtherDay(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(now.year - 1),
      lastDate: now, // future dates are not allowed
      helpText: 'Select class date',
    );
    if (picked == null || !context.mounted) return;

    final existing = subject.statusOn(picked);
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${picked.day}/${picked.month}/${picked.year}'),
        content: Text(existing == null
            ? 'Were you present for ${subject.name}?'
            : 'Already marked ${existing ? 'present' : 'absent'}. Change it?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(foregroundColor: UiColors.danger),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Absent'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: UiColors.success),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Present'),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    context
        .read<SubjectProvider>()
        .mark(subject.id, present: result, date: picked);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<SubjectProvider>();
    final target = context.select<SubjectProvider, double>((p) => p.target);
    final color = _statusColor(target);
    final today = DateTime.now();
    final todayStatus = subject.statusOn(today);
    final scheduledToday = subject.isScheduledOn(today);
    final muted = UiColors.mutedText(context);
    final progress = (subject.percentage / 100).clamp(0.0, 1.0);
    final days = (List<int>.from(subject.days)..sort())
        .map((d) => _dayShort[d - 1])
        .join(' · ');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: UiColors.surface(context),
        borderRadius: BorderRadius.circular(24),
        boxShadow: UiColors.softShadow(context),
        border: Border.all(color: color.withOpacity(0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 62,
                height: 62,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 6,
                      color: color,
                      backgroundColor: color.withOpacity(0.15),
                    ),
                    Center(
                      child: Text(
                        '${subject.percentage.round()}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Attended ${subject.attended} of ${subject.total} classes',
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddSubjectScreen(subject: subject),
                      ),
                    );
                  } else if (value == 'reset') {
                    provider.resetSubject(subject.id);
                  } else if (value == 'delete') {
                    provider.deleteSubject(subject.id);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit name')),
                  PopupMenuItem(value: 'reset', child: Text('Reset counts')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Icon(_statusIcon(target), size: 18, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _message(target),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 16, color: muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  days,
                  style: TextStyle(fontSize: 12.5, color: muted),
                ),
              ),
              if (scheduledToday)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: UiColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Class today',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: UiColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            todayStatus == null
                ? 'Today: not marked yet'
                : 'Today: ${todayStatus ? 'Present' : 'Absent'}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: todayStatus == null
                  ? muted
                  : (todayStatus ? UiColors.success : UiColors.danger),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: todayStatus == true
                    ? FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: UiColors.success,
                    minimumSize: const Size(0, 46),
                  ),
                  onPressed: () =>
                      provider.mark(subject.id, present: true),
                  icon: const Icon(Icons.check),
                  label: const Text('Present'),
                )
                    : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: UiColors.success,
                    side: const BorderSide(color: UiColors.success),
                    minimumSize: const Size(0, 46),
                  ),
                  onPressed: () =>
                      provider.mark(subject.id, present: true),
                  icon: const Icon(Icons.check),
                  label: const Text('Present'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: todayStatus == false
                    ? FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: UiColors.danger,
                    minimumSize: const Size(0, 46),
                  ),
                  onPressed: () =>
                      provider.mark(subject.id, present: false),
                  icon: const Icon(Icons.close),
                  label: const Text('Absent'),
                )
                    : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: UiColors.danger,
                    side: const BorderSide(color: UiColors.danger),
                    minimumSize: const Size(0, 46),
                  ),
                  onPressed: () =>
                      provider.mark(subject.id, present: false),
                  icon: const Icon(Icons.close),
                  label: const Text('Absent'),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (todayStatus != null)
                TextButton(
                  onPressed: () => provider.clearMark(subject.id, today),
                  child: const Text("Clear today's mark"),
                ),
              TextButton.icon(
                onPressed: () => _markOtherDay(context),
                icon: const Icon(Icons.calendar_today, size: 16),
                label: const Text('Other day'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}