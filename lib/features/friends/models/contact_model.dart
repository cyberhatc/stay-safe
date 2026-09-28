class Contact {
  final int? id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isEmergency;
  final DateTime createdAt;
  final DateTime updatedAt;

  Contact({
    this.id,
    required this.name,
    required this.phoneNumber,
    this.relationship = '',
    this.isEmergency = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'relationship': relationship,
      'isEmergency': isEmergency ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'] as int?,
      name: map['name'] as String,
      phoneNumber: map['phoneNumber'] as String,
      relationship: map['relationship'] as String? ?? '',
      isEmergency: (map['isEmergency'] as int?) == 1,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  Contact copyWith({
    int? id,
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? isEmergency,
  }) {
    return Contact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isEmergency: isEmergency ?? this.isEmergency,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get displayPhone {
    if (phoneNumber.length == 10) {
      return '(${phoneNumber.substring(0, 3)}) ${phoneNumber.substring(3, 6)}-${phoneNumber.substring(6)}';
    }
    return phoneNumber;
  }
}
