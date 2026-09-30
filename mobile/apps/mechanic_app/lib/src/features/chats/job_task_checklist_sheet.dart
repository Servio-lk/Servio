import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:shared_core/shared_core.dart';
import '../worker/worker_providers.dart';

class JobTaskChecklistSheet extends ConsumerStatefulWidget {
  final int appointmentId;
  final ValueChanged<String>? onTaskCompleted;

  const JobTaskChecklistSheet({
    super.key,
    required this.appointmentId,
    this.onTaskCompleted,
  });

  static Future<void> show(
    BuildContext context, {
    required int appointmentId,
    ValueChanged<String>? onTaskCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => JobTaskChecklistSheet(
        appointmentId: appointmentId,
        onTaskCompleted: onTaskCompleted,
      ),
    );
  }

  @override
  ConsumerState<JobTaskChecklistSheet> createState() => _JobTaskChecklistSheetState();
}

class _JobTaskChecklistSheetState extends ConsumerState<JobTaskChecklistSheet> {
  List<JobTaskModel> _tasks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
  }

  Future<void> _fetchTasks() async {
    final tasks = await ref.read(workerRepositoryProvider).getJobTasks(widget.appointmentId);
    if (mounted) {
      setState(() {
        _tasks = tasks;
        _loading = false;
      });
    }
  }

  Future<void> _toggleTask(JobTaskModel task, bool? completed) async {
    final newStatus = (completed ?? false) ? 'COMPLETED' : 'PENDING';
    final updated = task.copyWith(
      status: newStatus,
      completedAt: newStatus == 'COMPLETED' ? DateTime.now() : null,
      completedByName: newStatus == 'COMPLETED' ? 'Mechanic' : null,
    );

    setState(() {
      final index = _tasks.indexWhere((t) => t.id == task.id);
      if (index != -1) {
        _tasks[index] = updated;
      }
    });

    await ref.read(workerRepositoryProvider).updateJobTaskStatus(task.id, newStatus);
    if (newStatus == 'COMPLETED') {
      widget.onTaskCompleted?.call('Completed task: "${task.description}"');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Marked "${task.description}" as complete! Synced to activity timeline.'),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _addNewTaskDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Add Service Task',
          style: GoogleFonts.instrumentSans(fontWeight: FontWeight.w600),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Replace serpentine accessory belt',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty) {
                final newTask = JobTaskModel(
                  id: DateTime.now().millisecondsSinceEpoch,
                  appointmentId: widget.appointmentId,
                  description: text,
                  status: 'PENDING',
                );
                setState(() => _tasks.add(newTask));
                Navigator.pop(ctx);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5D2E),
              foregroundColor: Colors.white,
            ),
            child: const Text('Add Task'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _tasks.where((t) => t.isCompleted).length;
    final totalCount = _tasks.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;
    final safeBottom = math.max(MediaQuery.paddingOf(context).bottom, 16.0);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, safeBottom + MediaQuery.of(context).viewInsets.bottom),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Default Service Tasks',
                    style: GoogleFonts.instrumentSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    'Put ticks to sync with Job Activity Timeline',
                    style: GoogleFonts.instrumentSans(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
              IconButton.filledTonal(
                onPressed: _addNewTaskDialog,
                icon: const PhosphorIcon(PhosphorIconsBold.plus, size: 18),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFFF2ED),
                  foregroundColor: const Color(0xFFFF5D2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFEEEEEE),
              color: const Color(0xFF16A34A),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$completedCount of $totalCount tasks completed',
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}% Done',
                style: GoogleFonts.instrumentSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF16A34A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFF5D2E)),
                  )
                : ListView.separated(
                    itemCount: _tasks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final task = _tasks[index];
                      final isDone = task.isCompleted;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDone ? const Color(0xFFF9FDF9) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDone ? const Color(0xFFB8E6C1) : const Color(0xFFE5E5E5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: isDone,
                              activeColor: const Color(0xFF16A34A),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: (val) => _toggleTask(task, val),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.description,
                                      style: GoogleFonts.instrumentSans(
                                        fontSize: 13,
                                        fontWeight: isDone ? FontWeight.w500 : FontWeight.w600,
                                        decoration: isDone ? TextDecoration.lineThrough : null,
                                        color: isDone ? Colors.black54 : Colors.black87,
                                      ),
                                    ),
                                    if (task.instructions != null && task.instructions!.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        task.instructions!,
                                        style: GoogleFonts.instrumentSans(
                                          fontSize: 11,
                                          color: Colors.black45,
                                        ),
                                      ),
                                    ],
                                    if (isDone && task.completedByName != null) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const PhosphorIcon(PhosphorIconsFill.checkCircle, size: 12, color: Color(0xFF16A34A)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Done by ${task.completedByName}',
                                            style: GoogleFonts.instrumentSans(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: const Color(0xFF16A34A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5D2E),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Done with Tasks',
                style: GoogleFonts.instrumentSans(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
