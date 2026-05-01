import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/router/app_router.dart';
import '../_registry/module_registry.dart';
import 'courses_binding.dart';
import 'views/course_catalog_view.dart';
import 'views/course_detail_view.dart';
import 'admin/course_manager_view.dart';
import 'admin/course_section_editor.dart';
import 'admin/course_enrollments_view.dart';
import 'views/lesson_player_view.dart';

class CoursesModule extends AppModule {
  @override
  String get moduleId => 'courses';

  @override
  NavItem? get navItem => const NavItem(
        label: 'Courses',
        icon: Icons.school_outlined,
        route: ERoutes.courses,
      );

  @override
  Bindings? get binding => CoursesBinding();

  @override
  List<GetPage> get routes => [
        GetPage(
          name: ERoutes.courses,
          page: () => const CourseCatalogView(),
          binding: CoursesBinding(),
        ),
        GetPage(
          name: ERoutes.courseDetail,
          page: () => const CourseDetailView(),
          binding: CoursesBinding(),
        ),
        GetPage(
          name: ERoutes.adminCourses,
          page: () => const CourseManagerView(),
          binding: CoursesBinding(),
        ),
        GetPage(
          name: ERoutes.adminCourseEditor,
          page: () => const CourseSectionEditor(),
          binding: CoursesBinding(),
        ),
        GetPage(
          name: ERoutes.lessonPlayer,
          page: () => const LessonPlayerView(),
          binding: CoursesBinding(),
        ),
        GetPage(
          name: ERoutes.adminCourseEnrollments,
          page: () => const CourseEnrollmentsView(),
          binding: CoursesBinding(),
        ),
      ];
}
