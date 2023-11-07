class Note {
  String title;
  String content;
  DateTime dateTime;

  Note({
    required this.title,
    required this.content,
    required this.dateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      'dateTime': dateTime.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      title: map['title'],
      content: map['content'],
      dateTime: DateTime.parse(map['dateTime']),
    );
  }
}
