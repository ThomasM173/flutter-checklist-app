/// Checklist item model
class ChecklistItem {
  final String id;
  final String text;
  final int order;
  
  ChecklistItem({
    required this.id,
    required this.text,
    required this.order,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'order': order,
  };

  factory ChecklistItem.fromJson(Map<String, dynamic> json) => ChecklistItem(
    id: json['id'],
    text: json['text'],
    order: json['order'],
  );

  ChecklistItem copyWith({
    String? id,
    String? text,
    int? order,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      text: text ?? this.text,
      order: order ?? this.order,
    );
  }
}

/// Checklist section model
class ChecklistSection {
  final String id;
  final String title;
  final int order;
  final List<ChecklistItem> items;
  
  ChecklistSection({
    required this.id,
    required this.title,
    required this.order,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'order': order,
    'items': items.map((i) => i.toJson()).toList(),
  };

  factory ChecklistSection.fromJson(Map<String, dynamic> json) => ChecklistSection(
    id: json['id'],
    title: json['title'],
    order: json['order'],
    items: (json['items'] as List)
        .map((i) => ChecklistItem.fromJson(i))
        .toList(),
  );

  ChecklistSection copyWith({
    String? id,
    String? title,
    int? order,
    List<ChecklistItem>? items,
  }) {
    return ChecklistSection(
      id: id ?? this.id,
      title: title ?? this.title,
      order: order ?? this.order,
      items: items ?? this.items,
    );
  }
}

/// Checklist template for an aircraft type
class ChecklistTemplate {
  final String id;
  final String aircraftType; // C152, C172, PA28, etc.
  final String? flightSchoolId; // null = default/built-in, non-null = custom
  final List<ChecklistSection> sections;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  ChecklistTemplate({
    required this.id,
    required this.aircraftType,
    this.flightSchoolId,
    required this.sections,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  bool get isCustom => flightSchoolId != null;
  bool get isDefault => flightSchoolId == null;

  Map<String, dynamic> toJson() => {
    'id': id,
    'aircraftType': aircraftType,
    'flightSchoolId': flightSchoolId,
    'sections': sections.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ChecklistTemplate.fromJson(Map<String, dynamic> json) => ChecklistTemplate(
    id: json['id'],
    aircraftType: json['aircraftType'],
    flightSchoolId: json['flightSchoolId'],
    sections: (json['sections'] as List)
        .map((s) => ChecklistSection.fromJson(s))
        .toList(),
    createdAt: DateTime.parse(json['createdAt']),
    updatedAt: DateTime.parse(json['updatedAt']),
  );

  ChecklistTemplate copyWith({
    String? id,
    String? aircraftType,
    String? flightSchoolId,
    List<ChecklistSection>? sections,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChecklistTemplate(
      id: id ?? this.id,
      aircraftType: aircraftType ?? this.aircraftType,
      flightSchoolId: flightSchoolId ?? this.flightSchoolId,
      sections: sections ?? this.sections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
