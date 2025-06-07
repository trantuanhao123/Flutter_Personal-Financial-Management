part of models;

@RealmModel()
class _GiaoDich {
  @PrimaryKey()
  late String id;

  late double amount;

  late String category;

  late DateTime date;

  String? note;

  late String type;

  late bool isPinned;
}
