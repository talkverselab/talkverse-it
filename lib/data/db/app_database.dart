import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ─── Tables ─────────────────────────────────────────────────────────────────

@DataClassName('TurnRow')
class Turns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get level => text()(); // 'L1' | 'L2' | 'L3'
  TextColumn get variety => text().withDefault(const Constant('es_ES'))(); // 'es_ES' | 'es_MX'
  TextColumn get episodeId => text().nullable()(); // 'ep1' .. 'ep5'
  IntColumn get num => integer()();
  TextColumn get speaker => text()(); // 'A' | 'B'
  TextColumn get es => text()(); // 대상어 문장 (템플릿 이름 그대로)
  TextColumn get rd => text().nullable()(); // 한글 독음
  TextColumn get ko => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get tagsJson => text().nullable()();
}

@DataClassName('WordRow')
class Words extends Table {
  IntColumn get rank => integer()();
  TextColumn get word => text()();
  TextColumn get pos => text().nullable()(); // noun, verb, adj, ...
  TextColumn get gender => text().nullable()(); // 'm' | 'f' (명사)
  TextColumn get meaningKo => text().nullable()();
  RealColumn get freq => real().nullable()();
  RealColumn get cumPct => real().nullable()();
  TextColumn get region => text().nullable()(); // R1, R2, R3, R4
  TextColumn get cefr => text().nullable()(); // A1, A2, B1, ...

  @override
  Set<Column> get primaryKey => {rank};
}

@DataClassName('VerbRow')
class Verbs extends Table {
  TextColumn get infinitive => text()();
  TextColumn get group => text()(); // 'ar' | 'er' | 'ir' | 'irregular'
  TextColumn get meaningKo => text().nullable()();
  IntColumn get rank => integer().nullable()();
  TextColumn get presentJson => text().nullable()(); // [yo, tú, él, nosotros, vosotros, ellos]
  TextColumn get preteriteJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {infinitive};
}

@DataClassName('UserProgressRow')
class UserProgress extends Table {
  IntColumn get turnId => integer().references(Turns, #id)();
  BoolColumn get learned => boolean().withDefault(const Constant(false))();
  BoolColumn get favorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get lastReviewed => dateTime().nullable()();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {turnId};
}

@DataClassName('VerbProgressRow')
class VerbProgress extends Table {
  TextColumn get infinitive => text().references(Verbs, #infinitive)();
  BoolColumn get known => boolean().withDefault(const Constant(false))();
  IntColumn get exposureCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastReviewed => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {infinitive};
}

@DataClassName('UserMemoRow')
class UserMemos extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get context => text()(); // screen+turn or 'global'
  TextColumn get body => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// ─── Database ───────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Turns,
  Words,
  Verbs,
  UserProgress,
  VerbProgress,
  UserMemos,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          // v2: 대화 턴에 한글 독음(rd) 칸 추가
          if (from < 2) await m.addColumn(turns, turns.rd);
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'spanish_universe');
  }
}
