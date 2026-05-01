import 'package:raspucat/utils/constants/exports.dart';

class EData {
  EData._();

  static final List<ProjectModel> projects = [
    ProjectModel(
      title: 'Raspucat',
      description: 'My personal website and portfolio.',
      technologies: ['Flutter', 'GetX'],
      githubUrl: 'https://github.com/rmr32/raspucat',
      liveUrl: 'https://raspucat.com',
      imagePaths: [
        'assets/images/logos/raspucat_gradient.png',
        // 'assets/images/logos/raspucat_black.svg',
        // 'assets/images/logos/raspucat_white.svg',
      ],
    ),
    ProjectModel(
      title: 'Dashing Beard Co',
      description:
          'Frontend development for a product-based business with custom animations.',
      technologies: ['HTML', 'SCSS', 'JavaScript'],
      githubUrl: 'https://github.com/rmr32/Dashing_Beard_Co',
      liveUrl: 'https://dashingbeardco.com',
      imagePaths: [
        'assets/images/projects/dashing_beard_co_hero.gif',
        // 'assets/images/projects/dashing_beard_co_full.gif',
        'assets/images/projects/dashing_beard_co.png',
      ],
    ),
    ProjectModel(
      title: 'Red Dot Entertainment',
      description:
          'A full-stack booking application with user authentication, payment processing, and real-time booking management.',
      technologies: ['Flutter', 'GetX', 'Firebase', 'Stripe'],
      // githubUrl: 'https://github.com/yourusername/ecommerce',
      liveUrl: 'https://reddotentertainment.com',
      imagePaths: [
        'assets/images/projects/red_dot_entertainment_hero.gif',
        'assets/images/projects/red_dot_entertainment_booking.gif',
        'assets/images/projects/red_dot_entertainment.png',
      ],
    ),
    ProjectModel(
      title: 'DarkArc',
      description: 'Throw simulation game with realistic physics and gameplay.',
      technologies: ['Flutter', 'GetX', 'Firebase'],
      // githubUrl: 'https://github.com/yourusername/ecommerce',
      // liveUrl: 'https://reddotentertainment.com',
      imagePaths: [],
    ),
  ];
}
