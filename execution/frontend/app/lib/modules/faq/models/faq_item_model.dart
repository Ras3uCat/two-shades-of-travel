class FaqItemModel {
  final String  id;
  final String  question;
  final String  answer;
  final String? category;
  final int     displayOrder;
  final bool    isActive;

  const FaqItemModel({
    required this.id,
    required this.question,
    required this.answer,
    this.category,
    required this.displayOrder,
    required this.isActive,
  });

  factory FaqItemModel.fromMap(Map<String, dynamic> map) {
    return FaqItemModel(
      id:           map['id']            as String,
      question:     map['question']      as String,
      answer:       map['answer']        as String,
      category:     map['category']      as String?,
      displayOrder: (map['display_order'] as num?)?.toInt() ?? 0,
      isActive:     map['is_active']     as bool? ?? true,
    );
  }
}
