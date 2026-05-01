import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:chewie/chewie.dart';
import '../controllers/lesson_player_controller.dart';

class LessonPlayerView extends GetView<LessonPlayerController> {
  const LessonPlayerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.course.value?.title ?? 'Loading...')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.error.value.isNotEmpty) {
          return Center(child: Text(controller.error.value));
        }

        if (controller.course.value == null) {
          return const Center(child: Text('Course not found'));
        }

        final isMobile = MediaQuery.of(context).size.width < 800;

        if (isMobile) {
          return Column(
            children: [
              _buildVideoPlayer(),
              Expanded(child: _buildSidebar()),
            ],
          );
        } else {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildVideoPlayer(),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 1,
                child: _buildSidebar(),
              ),
            ],
          );
        }
      }),
    );
  }

  Widget _buildVideoPlayer() {
    return GetBuilder<LessonPlayerController>(
      builder: (_) {
        if (controller.chewieController != null &&
            controller
                .chewieController!.videoPlayerController.value.isInitialized) {
          return AspectRatio(
            aspectRatio: controller
                .chewieController!.videoPlayerController.value.aspectRatio,
            child: Chewie(
              controller: controller.chewieController!,
            ),
          );
        } else {
          return const AspectRatio(
            aspectRatio: 16 / 9,
            child: Center(child: CircularProgressIndicator()),
          );
        }
      },
    );
  }

  Widget _buildSidebar() {
    return ListView.builder(
      itemCount: controller.sections.length,
      itemBuilder: (context, index) {
        final section = controller.sections[index];
        final sectionLessons = controller.lessons
            .where((l) => l.sectionId == section.id)
            .toList()
          ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        return ExpansionTile(
          title: Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          initiallyExpanded: true,
          children: sectionLessons.map((lesson) {
            final isCurrent = controller.currentLesson.value?.id == lesson.id;
            final isCompleted = controller.isLessonCompleted(lesson.id);

            return ListTile(
              leading: Icon(
                isCompleted ? Icons.check_circle : Icons.play_circle_outline,
                color: isCompleted
                    ? Colors.green
                    : (isCurrent ? Colors.blue : Colors.grey),
              ),
              title: Text(
                lesson.title,
                style: TextStyle(
                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              selected: isCurrent,
              onTap: () => controller.playLesson(lesson),
            );
          }).toList(),
        );
      },
    );
  }
}
