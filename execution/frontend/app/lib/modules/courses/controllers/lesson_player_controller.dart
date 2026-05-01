import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../models/course_model.dart';
import '../models/enrollment_model.dart';
import '../repositories/course_repository.dart';

class LessonPlayerController extends GetxController {
  final CourseRepository _repository;

  LessonPlayerController(this._repository);

  final Rx<CourseModel?> course = Rx<CourseModel?>(null);
  final RxList<CourseSection> sections = <CourseSection>[].obs;
  final RxList<CourseLesson> lessons = <CourseLesson>[].obs;

  // Progress
  final RxList<LessonProgress> progress = <LessonProgress>[].obs;
  final Rx<CourseLesson?> currentLesson = Rx<CourseLesson?>(null);

  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  VideoPlayerController? videoPlayerController;
  ChewieController? chewieController;

  Timer? _progressTimer;
  Timer? _urlRefreshTimer;

  // Track if video is playing to resume after URL refresh
  bool _isPlaying = false;

  @override
  void onInit() {
    super.onInit();
    final slug = Get.parameters['slug'];
    final lessonId = Get.parameters['id']; // matches route template :id
    if (slug != null) {
      _loadData(slug, lessonId);
    } else {
      error.value = 'Course not found';
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _progressTimer?.cancel();
    _urlRefreshTimer?.cancel();
    _disposeVideo();
    super.onClose();
  }

  Future<void> _loadData(String slug, String? lessonId) async {
    isLoading.value = true;
    error.value = '';
    try {
      final fetchedCourse = await _repository.getCourseBySlug(slug);
      if (fetchedCourse == null) {
        error.value = 'Course not found';
        return;
      }
      course.value = fetchedCourse;

      final fetchedSections = await _repository.getSections(fetchedCourse.id);
      sections.assignAll(fetchedSections);

      final fetchedLessons = await _repository.getLessons(fetchedCourse.id);
      lessons.assignAll(fetchedLessons);

      final fetchedProgress = await _repository.getProgress(fetchedCourse.id);
      progress.assignAll(fetchedProgress);

      if (lessonId != null) {
        final initialLesson = fetchedLessons.firstWhereOrNull(
          (l) => l.id == lessonId,
        );
        if (initialLesson != null) {
          playLesson(initialLesson);
        } else if (fetchedLessons.isNotEmpty) {
          playLesson(fetchedLessons.first);
        }
      } else if (fetchedLessons.isNotEmpty) {
        // Try to resume from where user left off or play first
        playLesson(fetchedLessons.first);
      }
    } catch (e) {
      error.value = 'Failed to load course details';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> playLesson(CourseLesson lesson) async {
    currentLesson.value = lesson;
    await _initVideo(lesson);
  }

  Future<void> _initVideo(CourseLesson lesson) async {
    _disposeVideo();
    _progressTimer?.cancel();
    _urlRefreshTimer?.cancel();

    // Setup refresh mechanism
    // Signed URL lasts 4 hours according to plan. We will refresh every 3 hours.
    _urlRefreshTimer = Timer.periodic(const Duration(hours: 3), (_) {
      _refreshSignedUrl(lesson);
    });

    await _loadVideoUrlAndInitialize(lesson);
  }

  void _disposeVideo() {
    chewieController?.dispose();
    chewieController = null;
    videoPlayerController?.dispose();
    videoPlayerController = null;
  }

  Future<void> _loadVideoUrlAndInitialize(
    CourseLesson lesson, {
    Duration? startAt,
  }) async {
    try {
      final signedUrl = await _repository.getLessonVideoUrl(lesson.id);
      if (signedUrl == null) {
        Get.snackbar(
          'Error',
          'Could not load video. You may not have access.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(signedUrl),
      );
      await videoPlayerController!.initialize();

      // Find saved progress to resume
      Duration seekTo = startAt ?? Duration.zero;
      if (startAt == null) {
        final p = progress.firstWhereOrNull(
          (prog) => prog.lessonId == lesson.id,
        );
        if (p != null) {
          seekTo = Duration(seconds: p.watchedSeconds);
        }
      }

      chewieController = ChewieController(
        videoPlayerController: videoPlayerController!,
        autoPlay: _isPlaying || startAt == null,
        looping: false,
        startAt: seekTo,
        allowFullScreen: true,
      );

      _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        _saveProgress();
      });

      update(); // trigger rebuild for GetBuilder
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to initialize video player',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> _refreshSignedUrl(CourseLesson lesson) async {
    final curPos = videoPlayerController?.value.position;
    _isPlaying = videoPlayerController?.value.isPlaying ?? false;
    _progressTimer?.cancel();
    _disposeVideo();
    await _loadVideoUrlAndInitialize(lesson, startAt: curPos);
  }

  Future<void> _saveProgress() async {
    final lesson = currentLesson.value;
    if (lesson == null || videoPlayerController == null) return;

    final position = videoPlayerController!.value.position;
    final duration = videoPlayerController!.value.duration;

    if (position.inSeconds == 0) return;

    final completed =
        duration.inSeconds > 0 &&
        position.inSeconds >= (duration.inSeconds * 0.9).floor();

    await _repository.saveLessonProgress(
      lesson.id,
      position.inSeconds,
      completed,
    );

    // Update local state
    final index = progress.indexWhere((p) => p.lessonId == lesson.id);
    if (index >= 0) {
      final old = progress[index];
      progress[index] = LessonProgress(
        id: old.id,
        clientEmail: old.clientEmail,
        lessonId: old.lessonId,
        watchedSeconds: position.inSeconds,
        completedAt: completed ? DateTime.now() : old.completedAt,
        updatedAt: DateTime.now(),
      );
    } else {
      final fetchedProgress = await _repository.getProgress(course.value!.id);
      progress.assignAll(fetchedProgress);
    }
  }

  bool isLessonCompleted(String lessonId) {
    return progress.any((p) => p.lessonId == lessonId && p.isCompleted);
  }

  void goToNextLesson() {
    if (currentLesson.value == null || lessons.isEmpty) return;
    final currentIndex = lessons.indexWhere(
      (l) => l.id == currentLesson.value!.id,
    );
    if (currentIndex >= 0 && currentIndex < lessons.length - 1) {
      playLesson(lessons[currentIndex + 1]);
    }
  }

  void goToPreviousLesson() {
    if (currentLesson.value == null || lessons.isEmpty) return;
    final currentIndex = lessons.indexWhere(
      (l) => l.id == currentLesson.value!.id,
    );
    if (currentIndex > 0) {
      playLesson(lessons[currentIndex - 1]);
    }
  }
}
