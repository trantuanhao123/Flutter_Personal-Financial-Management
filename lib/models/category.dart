part of models;

@RealmModel()
class _DanhMuc {
  @PrimaryKey()
  late String id;

  late String name;

  late String type;

  double? limit;

  String? icon;

  String? color;
}
