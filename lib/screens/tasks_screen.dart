import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/task_provider.dart';
import '../theme/ui_colors.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  String _fmt(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day}/${d.month}/${d.year}  $h:$m $ampm';
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    DateTime? remindAt;
    String? error;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final reminder = remindAt;
          return AlertDialog(
            title: const Text('New task'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Task',
                    prefixIcon: const Icon(Icons.edit_note),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.alarm),
                  label: Text(
                      reminder == null ? 'Set reminder' : _fmt(reminder)),
                  onPressed: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: now,
                      firstDate: now,
                      lastDate: DateTime(now.year + 2),
                    );
                    if (date == null || !ctx.mounted) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: TimeOfDay.fromDateTime(
                          now.add(const Duration(hours: 1))),
                    );
                    if (time == null) return;
                    setState(() {
                      error = null;
                      remindAt = DateTime(date.year, date.month, date.day,
                          time.hour, time.minute);
                    });
                  },
                ),
                if (reminder != null)
                  TextButton(
                    onPressed: () => setState(() => remindAt = null),
                    child: const Text('Remove reminder'),
                  ),
                if (error != null)
                  Text(
                    error!,
                    style: TextStyle(color: Theme.of(ctx).colorScheme.error),
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
                  final title = controller.text.trim();
                  if (title.isEmpty) {
                    setState(() => error = 'Please enter a task');
                    return;
                  }
                  final when = remindAt;
                  if (when != null && !when.isAfter(DateTime.now())) {
                    setState(() => error = 'Pick a time in the future');
                    return;
                  }
                  context.read<TaskProvider>().addTask(title, remindAt: when);
                  Navigator.pop(ctx);
                },
                child: const Text('Add'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<TaskProvider>();
    // Pending tasks first, completed ones at the bottom.
    final tasks = [
      ...p.tasks.where((t) => !t.done),
      ...p.tasks.where((t) => t.done),
    ];
    final doneCount = p.tasks.where((t) => t.done).length;
    final muted = UiColors.mutedText(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 72,
        titleSpacing: 20,
        title: const Text(
          'My tasks',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
      ),
      body: tasks.isEmpty
          ? Center(
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
                  Icons.checklist_rounded,
                  size: 56,
                  color: UiColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No tasks yet',
                style:
                TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Write your tasks, set a reminder, and tick them off when done.',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _showAddDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add your first task'),
              ),
            ],
          ),
        ),
      )
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: UiColors.gradientOnTrack,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: UiColors.gradientOnTrack.first.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$doneCount of ${p.tasks.length} tasks done',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                LinearProgressIndicator(
                  value: p.tasks.isEmpty ? 0 : doneCount / p.tasks.length,
                  minHeight: 8,
                  color: Colors.white,
                  backgroundColor: Colors.white24,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...tasks.map((t) {
            final reminder = t.remindAt;
            final overdue = !t.done &&
                reminder != null &&
                reminder.isBefore(DateTime.now());
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: UiColors.surface(context),
                borderRadius: BorderRadius.circular(18),
                boxShadow: UiColors.softShadow(context),
              ),
              child: ListTile(
                contentPadding:
                const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                onTap: () => p.toggleDone(t.id),
                leading: Checkbox(
                  value: t.done,
                  shape: const CircleBorder(),
                  activeColor: UiColors.success,
                  onChanged: (_) => p.toggleDone(t.id),
                ),
                title: Text(
                  t.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration:
                    t.done ? TextDecoration.lineThrough : null,
                    color: t.done ? muted : null,
                  ),
                ),
                subtitle: reminder == null
                    ? null
                    : Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.alarm,
                        size: 14,
                        color: overdue
                            ? UiColors.danger
                            : UiColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _fmt(reminder),
                          style: TextStyle(
                            fontSize: 12.5,
                            color: overdue
                                ? UiColors.danger
                                : muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete',
                  onPressed: () => p.deleteTask(t.id),
                ),
              ),
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add task'),
        onPressed: () => _showAddDialog(context),
      ),
    );
  }
}