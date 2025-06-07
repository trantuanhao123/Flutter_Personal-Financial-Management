// dart format width=80
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// RealmObjectGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
class DanhMuc extends _DanhMuc with RealmEntity, RealmObjectBase, RealmObject {
  DanhMuc(
    String id,
    String name,
    String type, {
    double? limit,
    String? icon,
    String? color,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'name', name);
    RealmObjectBase.set(this, 'type', type);
    RealmObjectBase.set(this, 'limit', limit);
    RealmObjectBase.set(this, 'icon', icon);
    RealmObjectBase.set(this, 'color', color);
  }

  DanhMuc._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  String get name => RealmObjectBase.get<String>(this, 'name') as String;
  @override
  set name(String value) => RealmObjectBase.set(this, 'name', value);

  @override
  String get type => RealmObjectBase.get<String>(this, 'type') as String;
  @override
  set type(String value) => RealmObjectBase.set(this, 'type', value);

  @override
  double? get limit => RealmObjectBase.get<double>(this, 'limit') as double?;
  @override
  set limit(double? value) => RealmObjectBase.set(this, 'limit', value);

  @override
  String? get icon => RealmObjectBase.get<String>(this, 'icon') as String?;
  @override
  set icon(String? value) => RealmObjectBase.set(this, 'icon', value);

  @override
  String? get color => RealmObjectBase.get<String>(this, 'color') as String?;
  @override
  set color(String? value) => RealmObjectBase.set(this, 'color', value);

  @override
  Stream<RealmObjectChanges<DanhMuc>> get changes =>
      RealmObjectBase.getChanges<DanhMuc>(this);

  @override
  Stream<RealmObjectChanges<DanhMuc>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<DanhMuc>(this, keyPaths);

  @override
  DanhMuc freeze() => RealmObjectBase.freezeObject<DanhMuc>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'name': name.toEJson(),
      'type': type.toEJson(),
      'limit': limit.toEJson(),
      'icon': icon.toEJson(),
      'color': color.toEJson(),
    };
  }

  static EJsonValue _toEJson(DanhMuc value) => value.toEJson();
  static DanhMuc _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {'id': EJsonValue id, 'name': EJsonValue name, 'type': EJsonValue type} =>
        DanhMuc(
          fromEJson(id),
          fromEJson(name),
          fromEJson(type),
          limit: fromEJson(ejson['limit']),
          icon: fromEJson(ejson['icon']),
          color: fromEJson(ejson['color']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(DanhMuc._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, DanhMuc, 'DanhMuc', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('name', RealmPropertyType.string),
      SchemaProperty('type', RealmPropertyType.string),
      SchemaProperty('limit', RealmPropertyType.double, optional: true),
      SchemaProperty('icon', RealmPropertyType.string, optional: true),
      SchemaProperty('color', RealmPropertyType.string, optional: true),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}

class GiaoDich extends _GiaoDich
    with RealmEntity, RealmObjectBase, RealmObject {
  GiaoDich(
    String id,
    double amount,
    String category,
    DateTime date,
    String type,
    bool isPinned, {
    String? note,
  }) {
    RealmObjectBase.set(this, 'id', id);
    RealmObjectBase.set(this, 'amount', amount);
    RealmObjectBase.set(this, 'category', category);
    RealmObjectBase.set(this, 'date', date);
    RealmObjectBase.set(this, 'note', note);
    RealmObjectBase.set(this, 'type', type);
    RealmObjectBase.set(this, 'isPinned', isPinned);
  }

  GiaoDich._();

  @override
  String get id => RealmObjectBase.get<String>(this, 'id') as String;
  @override
  set id(String value) => RealmObjectBase.set(this, 'id', value);

  @override
  double get amount => RealmObjectBase.get<double>(this, 'amount') as double;
  @override
  set amount(double value) => RealmObjectBase.set(this, 'amount', value);

  @override
  String get category =>
      RealmObjectBase.get<String>(this, 'category') as String;
  @override
  set category(String value) => RealmObjectBase.set(this, 'category', value);

  @override
  DateTime get date => RealmObjectBase.get<DateTime>(this, 'date') as DateTime;
  @override
  set date(DateTime value) => RealmObjectBase.set(this, 'date', value);

  @override
  String? get note => RealmObjectBase.get<String>(this, 'note') as String?;
  @override
  set note(String? value) => RealmObjectBase.set(this, 'note', value);

  @override
  String get type => RealmObjectBase.get<String>(this, 'type') as String;
  @override
  set type(String value) => RealmObjectBase.set(this, 'type', value);

  @override
  bool get isPinned => RealmObjectBase.get<bool>(this, 'isPinned') as bool;
  @override
  set isPinned(bool value) => RealmObjectBase.set(this, 'isPinned', value);

  @override
  Stream<RealmObjectChanges<GiaoDich>> get changes =>
      RealmObjectBase.getChanges<GiaoDich>(this);

  @override
  Stream<RealmObjectChanges<GiaoDich>> changesFor([List<String>? keyPaths]) =>
      RealmObjectBase.getChangesFor<GiaoDich>(this, keyPaths);

  @override
  GiaoDich freeze() => RealmObjectBase.freezeObject<GiaoDich>(this);

  EJsonValue toEJson() {
    return <String, dynamic>{
      'id': id.toEJson(),
      'amount': amount.toEJson(),
      'category': category.toEJson(),
      'date': date.toEJson(),
      'note': note.toEJson(),
      'type': type.toEJson(),
      'isPinned': isPinned.toEJson(),
    };
  }

  static EJsonValue _toEJson(GiaoDich value) => value.toEJson();
  static GiaoDich _fromEJson(EJsonValue ejson) {
    if (ejson is! Map<String, dynamic>) return raiseInvalidEJson(ejson);
    return switch (ejson) {
      {
        'id': EJsonValue id,
        'amount': EJsonValue amount,
        'category': EJsonValue category,
        'date': EJsonValue date,
        'type': EJsonValue type,
        'isPinned': EJsonValue isPinned,
      } =>
        GiaoDich(
          fromEJson(id),
          fromEJson(amount),
          fromEJson(category),
          fromEJson(date),
          fromEJson(type),
          fromEJson(isPinned),
          note: fromEJson(ejson['note']),
        ),
      _ => raiseInvalidEJson(ejson),
    };
  }

  static final schema = () {
    RealmObjectBase.registerFactory(GiaoDich._);
    register(_toEJson, _fromEJson);
    return const SchemaObject(ObjectType.realmObject, GiaoDich, 'GiaoDich', [
      SchemaProperty('id', RealmPropertyType.string, primaryKey: true),
      SchemaProperty('amount', RealmPropertyType.double),
      SchemaProperty('category', RealmPropertyType.string),
      SchemaProperty('date', RealmPropertyType.timestamp),
      SchemaProperty('note', RealmPropertyType.string, optional: true),
      SchemaProperty('type', RealmPropertyType.string),
      SchemaProperty('isPinned', RealmPropertyType.bool),
    ]);
  }();

  @override
  SchemaObject get objectSchema => RealmObjectBase.getSchema(this) ?? schema;
}
