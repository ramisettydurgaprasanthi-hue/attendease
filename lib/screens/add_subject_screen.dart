import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/subject.dart';
import '../providers/subject_provider.dart';
import '../theme/ui_colors.dart';

class AddSubjectScreen extends StatefulWidget {
  /// Pass a subject to edit it; leave null to add a new one.
  final Subject? subject;

  const AddSubjectScreen({super.key, this.subject});

  @override
  State<AddSubjectScreen> createState() => _AddSubjectScreenState();
}

class _AddSubjectScreenState extends State<AddSubjectScreen> {
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late Set<int> _days;

  bool get _isEditing => widget.subject != null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.subject?.name ?? '');
    _days = {...(widget.subject?.days ?? [1, 2, 3, 4, 5])};
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one class day')),
      );
      return;
    }
    final p = context.read<SubjectProvider>();
    final name = _controller.text.trim();
    final days = _days.toList()..sort();
    if (_isEditing) {
      p.editSubject(widget.subject!.id, name, days);
    } else {
      p.addSubject(name, days);
    }
    Navigator.pop(context);
  }

  OutlineInputBorder _border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = UiColors.mutedText(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit subject' : 'New subject',
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Subject name',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _controller,
                autofocus: !_isEditing,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Mobile App Development',
                  prefixIcon: const Icon(Icons.menu_book_rounded),
                  filled: true,
                  fillColor: UiColors.surface(context),
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  border: _border(Colors.transparent),
                  enabledBorder: _border(scheme.outline.withOpacity(0.3)),
                  focusedBorder: _border(scheme.primary, width: 1.8),
                  errorBorder: _border(UiColors.danger),
                  focusedErrorBorder: _border(UiColors.danger, width: 1.8),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Please enter a subject name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  const Text(
                    'Class days',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        setState(() => _days = {1, 2, 3, 4, 5}),
                    child: const Text('Mon–Fri'),
                  ),
                  TextButton(
                    onPressed: () =>
                        setState(() => _days = {1, 2, 3, 4, 5, 6, 7}),
                    child: const Text('Every day'),
                  ),
                ],
              ),
              Text(
                'Reminders only mention subjects scheduled that day.',
                style: TextStyle(fontSize: 13, color: muted),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(7, (i) {
                  final day = i + 1;
                  final selected = _days.contains(day);
                  return FilterChip(
                    label: Text(_dayNames[i]),
                    selected: selected,
                    showCheckmark: false,
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected ? scheme.onPrimary : scheme.onSurface,
                    ),
                    selectedColor: scheme.primary,
                    backgroundColor: UiColors.surface(context),
                    side: BorderSide(
                      color: selected
                          ? scheme.primary
                          : scheme.outline.withOpacity(0.3),
                    ),
                    shape: const StadiumBorder(),
                    padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _days.add(day);
                        } else {
                          _days.remove(day);
                        }
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: Icon(_isEditing ? Icons.check : Icons.add),
                  label: Text(
                    _isEditing ? 'Save changes' : 'Add subject',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}