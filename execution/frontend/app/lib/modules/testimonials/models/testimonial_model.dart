class TestimonialModel {
  final String  id;
  final String  author;
  final String? role;
  final String  quote;
  final int?    rating;       // 1–5, null = unrated
  final int     displayOrder;
  final bool    isActive;

  const TestimonialModel({
    required this.id,
    required this.author,
    this.role,
    required this.quote,
    this.rating,
    required this.displayOrder,
    required this.isActive,
  });

  factory TestimonialModel.fromMap(Map<String, dynamic> map) {
    return TestimonialModel(
      id:           map['id']            as String,
      author:       map['author']        as String,
      role:         map['role']          as String?,
      quote:        map['quote']         as String,
      rating:       map['rating']        as int?,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      isActive:     map['is_active']     as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() => {
        'author':        author,
        'role':          role,
        'quote':         quote,
        'rating':        rating,
        'display_order': displayOrder,
        'is_active':     isActive,
      };
}
