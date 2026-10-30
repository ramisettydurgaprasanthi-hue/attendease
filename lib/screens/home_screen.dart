import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/subject_provider.dart';
import '../theme/ui_colors.dart';
import '../widgets/subject_card.dart';
import 'add_subject_screen.dart';

const _weekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _dateLine() {
    final n = DateTime.now();
    return '${_weekdays[n.weekday - 1]}, ${n.day} ${_months[n.month - 1]}';
  }

  void _openAdd(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSubjectScreen()),
    );
  }

  void _showTargetDialog(BuildContext context) {
    final p = context.read<SubjectProvider>();
    double value = p.target;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Target attendance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${value.round()}%',
                  style: Theme.of(ctx).textTheme.headlineMedium),
              Slider(
                value: value,
                min: 50,
                max: 95,
                divisions: 45,
                label: '${value.round()}%',
                onChanged: (v) => setState(() => value = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                p.setTarget(value.roundToDouble());
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SubjectProvider>();

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dateLine(),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: UiColors.mutedText(context),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _greeting(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Set target',
            onPressed: () => _showTargetDialog(context),
          ),
          IconButton(
            icon: Icon(p.isDark ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle theme',
            onPressed: p.toggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: p.subjects.isEmpty
          ? _EmptyState(onAdd: () => _openAdd(context))
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          _SummaryCard(p: p),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 24, 4, 8),
            child: Row(
              children: [
                const Text(
                  'Your subjects',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: UiColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${p.subjects.length}',
                    style: const TextStyle(
                      color: UiColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          ...p.subjects.map((s) => SubjectCard(subject: s)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add subject'),
        onPressed: () => _openAdd(context),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final SubjectProvider p;

  const _SummaryCard({required this.p});

  String _plural(int n, String word) => '$n $word${n == 1 ? '' : 's'}';

  String _advice() {
    final target = p.target.round();
    if (p.overallTotal == 0) {
      return 'Mark some classes to see how many you can miss or need to attend.';
    }
    if (p.overallPercentage >= p.target) {
      final n = p.overallCanMiss;
      if (n == 0) {
        return 'You are right at the limit, so you cannot miss the next class.';
      }
      final d = p.daysFor(n, roundUp: false);
      final days = (d != null && d > 0) ? ' (about ${_plural(d, 'day')})' : '';
      return 'You can miss ${_plural(n, 'more class')}$days and still stay at $target%.';
    }
    final n = p.overallNeeded;
    final d = p.daysFor(n, roundUp: true);
    final days = d != null
        ? ' (about ${_plural(d, 'day')} without missing any)'
        : '';
    return 'Attend the next ${_plural(n, 'class')}$days to reach $target%.';
  }

  @override
  Widget build(BuildContext context) {
    final onTrack = p.overallTotal == 0 || p.overallPercentage >= p.target;
    final colors = onTrack ? UiColors.gradientOnTrack : UiColors.gradientBelow;
    final pending = p.pendingToday;
    final progress = (p.overallPercentage / 100).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colors.first.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 84,
                height: 84,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 8,
                      color: Colors.white,
                      backgroundColor: Colors.white24,
                    ),
                    Center(
                      child: Text(
                        '${p.overallPercentage.round()}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall attendance',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            onTrack
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            onTrack ? 'On track' : 'Below target',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline,
                    size: 20, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _advice(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(value: '${p.overallAttended}', label: 'Attended'),
              _Stat(value: '${p.overallTotal}', label: 'Classes'),
              _Stat(value: '${p.target.round()}%', label: 'Target'),
            ],
          ),
          if (pending.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.edit_calendar, size: 18, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Not marked today',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pending
                  .map(
                    (name) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: UiColors.primary.withOpacity(0.12),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 56,
                color: UiColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No subjects yet',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your subjects and class days to start tracking your attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(color: UiColors.mutedText(context)),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add your first subject'),
            ),
          ],
        ),
      ),
    );
  }
}