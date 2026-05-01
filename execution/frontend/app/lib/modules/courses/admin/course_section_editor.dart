import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/theme/e_spacing.dart';
import '../../../../core/theme/e_text_styles.dart';
import '../models/course_model.dart';
import '../repositories/course_repository.dart';

class CourseSectionEditor extends StatefulWidget {
  const CourseSectionEditor({super.key});

  @override
  State<CourseSectionEditor> createState() => _CourseSectionEditorState();
}

class _CourseSectionEditorState extends State<CourseSectionEditor> {
  final _repo = Get.find<CourseRepository>();
  late CourseModel _course;
  bool _isLoading = true;
  List<CourseSection> _sections = [];
  List<CourseLesson> _lessons = [];

  @override
  void initState() {
    super.initState();
    _course = Get.arguments as CourseModel;
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final parts = await Future.wait([
        _repo.getSections(_course.id),
        _repo.getLessons(_course.id),
      ]);
      _sections = parts[0] as List<CourseSection>;
      _lessons = parts[1] as List<CourseLesson>;
    } catch (_) {
      Get.snackbar('Error', 'Failed to load sections and lessons');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCreateSection() {
    String title = '';
    Get.dialog(
      AlertDialog(
        title: const Text('New Section'),
        content: TextField(
          decoration: const InputDecoration(labelText: 'Title'),
          onChanged: (v) => title = v,
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (title.isEmpty) return;
              Get.back();
              setState(() => _isLoading = true);
              try {
                await _repo.createSection(
                  CourseSection(
                    id: '',
                    courseId: _course.id,
                    title: title,
                    displayOrder: _sections.length,
                  ),
                );
                await _loadData();
              } catch (_) {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _onCreateLesson(CourseSection section) {
    String title = '';
    String videoPath = '';
    int duration = 0;
    bool isPreview = false;

    Get.dialog(
      AlertDialog(
        title: Text('New Lesson in ${section.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Title'),
                onChanged: (v) => title = v,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Video Storage Path (viewably private)',
                ),
                onChanged: (v) => videoPath = v,
              ),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Duration (seconds)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) => duration = int.tryParse(v) ?? 0,
              ),
              Row(
                children: [
                  StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Checkbox(
                        value: isPreview,
                        onChanged: (v) {
                          setDialogState(() => isPreview = v ?? false);
                        },
                      );
                    },
                  ),
                  const Text('Is Free Preview?'),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (title.isEmpty) return;
              Get.back();
              setState(() => _isLoading = true);
              try {
                await _repo.createLesson(
                  CourseLesson(
                    id: '',
                    courseId: _course.id,
                    sectionId: section.id,
                    title: title,
                    videoStoragePath: videoPath.isNotEmpty ? videoPath : null,
                    durationSeconds: duration,
                    isPreview: isPreview,
                    displayOrder: _lessons
                        .where((l) => l.sectionId == section.id)
                        .length,
                  ),
                );
                await _loadData();
              } catch (_) {
                setState(() => _isLoading = false);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Sections: ${_course.title}'),
        elevation: 1,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(ESpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ElevatedButton.icon(
                    onPressed: _onCreateSection,
                    icon: const Icon(Icons.add),
                    label: const Text('New Section'),
                  ),
                  const SizedBox(height: ESpacing.lg),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _sections.length,
                      itemBuilder: (_, i) {
                        final section = _sections[i];
                        final secLessons = _lessons
                            .where((l) => l.sectionId == section.id)
                            .toList();
                        return Card(
                          margin: const EdgeInsets.only(bottom: ESpacing.lg),
                          child: Padding(
                            padding: const EdgeInsets.all(ESpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(section.title, style: ETextStyles.h3),
                                    TextButton.icon(
                                      onPressed: () => _onCreateLesson(section),
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Add Lesson'),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                if (secLessons.isEmpty)
                                  const Padding(
                                    padding: EdgeInsets.all(ESpacing.md),
                                    child: Text('No lessons yet.'),
                                  )
                                else
                                  ...secLessons.map(
                                    (l) => ListTile(
                                      title: Text(l.title),
                                      subtitle: Text(
                                        'Path: ${l.videoStoragePath ?? "None"} • ${l.durationSeconds}s • ${l.isPreview ? "Preview" : "Paid"}',
                                      ),
                                      trailing: const Icon(
                                        Icons.edit,
                                        size: 16,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
