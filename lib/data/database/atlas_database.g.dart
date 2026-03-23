// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'atlas_database.dart';

// ignore_for_file: type=lint
class $UsersTable extends Users with TableInfo<$UsersTable, User> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UsersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _emailMeta = const VerificationMeta('email');
  @override
  late final GeneratedColumn<String> email = GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fullNameMeta = const VerificationMeta(
    'fullName',
  );
  @override
  late final GeneratedColumn<String> fullName = GeneratedColumn<String>(
    'full_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _photoUrlMeta = const VerificationMeta(
    'photoUrl',
  );
  @override
  late final GeneratedColumn<String> photoUrl = GeneratedColumn<String>(
    'photo_url',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _totalXpMeta = const VerificationMeta(
    'totalXp',
  );
  @override
  late final GeneratedColumn<int> totalXp = GeneratedColumn<int>(
    'total_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _currentStreakMeta = const VerificationMeta(
    'currentStreak',
  );
  @override
  late final GeneratedColumn<int> currentStreak = GeneratedColumn<int>(
    'current_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _longestStreakMeta = const VerificationMeta(
    'longestStreak',
  );
  @override
  late final GeneratedColumn<int> longestStreak = GeneratedColumn<int>(
    'longest_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isEmailVerifiedMeta = const VerificationMeta(
    'isEmailVerified',
  );
  @override
  late final GeneratedColumn<bool> isEmailVerified = GeneratedColumn<bool>(
    'is_email_verified',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_email_verified" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _authProviderMeta = const VerificationMeta(
    'authProvider',
  );
  @override
  late final GeneratedColumn<String> authProvider = GeneratedColumn<String>(
    'auth_provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('email'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _lastActiveDateMeta = const VerificationMeta(
    'lastActiveDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastActiveDate =
      GeneratedColumn<DateTime>(
        'last_active_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    email,
    fullName,
    photoUrl,
    level,
    totalXp,
    currentStreak,
    longestStreak,
    isEmailVerified,
    authProvider,
    createdAt,
    updatedAt,
    lastActiveDate,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  VerificationContext validateIntegrity(
    Insertable<User> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('full_name')) {
      context.handle(
        _fullNameMeta,
        fullName.isAcceptableOrUnknown(data['full_name']!, _fullNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fullNameMeta);
    }
    if (data.containsKey('photo_url')) {
      context.handle(
        _photoUrlMeta,
        photoUrl.isAcceptableOrUnknown(data['photo_url']!, _photoUrlMeta),
      );
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('total_xp')) {
      context.handle(
        _totalXpMeta,
        totalXp.isAcceptableOrUnknown(data['total_xp']!, _totalXpMeta),
      );
    }
    if (data.containsKey('current_streak')) {
      context.handle(
        _currentStreakMeta,
        currentStreak.isAcceptableOrUnknown(
          data['current_streak']!,
          _currentStreakMeta,
        ),
      );
    }
    if (data.containsKey('longest_streak')) {
      context.handle(
        _longestStreakMeta,
        longestStreak.isAcceptableOrUnknown(
          data['longest_streak']!,
          _longestStreakMeta,
        ),
      );
    }
    if (data.containsKey('is_email_verified')) {
      context.handle(
        _isEmailVerifiedMeta,
        isEmailVerified.isAcceptableOrUnknown(
          data['is_email_verified']!,
          _isEmailVerifiedMeta,
        ),
      );
    }
    if (data.containsKey('auth_provider')) {
      context.handle(
        _authProviderMeta,
        authProvider.isAcceptableOrUnknown(
          data['auth_provider']!,
          _authProviderMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('last_active_date')) {
      context.handle(
        _lastActiveDateMeta,
        lastActiveDate.isAcceptableOrUnknown(
          data['last_active_date']!,
          _lastActiveDateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return User(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      fullName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}full_name'],
      )!,
      photoUrl: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}photo_url'],
      ),
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      totalXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_xp'],
      )!,
      currentStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_streak'],
      )!,
      longestStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_streak'],
      )!,
      isEmailVerified: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_email_verified'],
      )!,
      authProvider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}auth_provider'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      lastActiveDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_active_date'],
      ),
    );
  }

  @override
  $UsersTable createAlias(String alias) {
    return $UsersTable(attachedDatabase, alias);
  }
}

class User extends DataClass implements Insertable<User> {
  final String id;
  final String email;
  final String fullName;
  final String? photoUrl;
  final int level;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final bool isEmailVerified;
  final String authProvider;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastActiveDate;
  const User({
    required this.id,
    required this.email,
    required this.fullName,
    this.photoUrl,
    required this.level,
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.isEmailVerified,
    required this.authProvider,
    required this.createdAt,
    required this.updatedAt,
    this.lastActiveDate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['email'] = Variable<String>(email);
    map['full_name'] = Variable<String>(fullName);
    if (!nullToAbsent || photoUrl != null) {
      map['photo_url'] = Variable<String>(photoUrl);
    }
    map['level'] = Variable<int>(level);
    map['total_xp'] = Variable<int>(totalXp);
    map['current_streak'] = Variable<int>(currentStreak);
    map['longest_streak'] = Variable<int>(longestStreak);
    map['is_email_verified'] = Variable<bool>(isEmailVerified);
    map['auth_provider'] = Variable<String>(authProvider);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || lastActiveDate != null) {
      map['last_active_date'] = Variable<DateTime>(lastActiveDate);
    }
    return map;
  }

  UsersCompanion toCompanion(bool nullToAbsent) {
    return UsersCompanion(
      id: Value(id),
      email: Value(email),
      fullName: Value(fullName),
      photoUrl: photoUrl == null && nullToAbsent
          ? const Value.absent()
          : Value(photoUrl),
      level: Value(level),
      totalXp: Value(totalXp),
      currentStreak: Value(currentStreak),
      longestStreak: Value(longestStreak),
      isEmailVerified: Value(isEmailVerified),
      authProvider: Value(authProvider),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      lastActiveDate: lastActiveDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastActiveDate),
    );
  }

  factory User.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return User(
      id: serializer.fromJson<String>(json['id']),
      email: serializer.fromJson<String>(json['email']),
      fullName: serializer.fromJson<String>(json['fullName']),
      photoUrl: serializer.fromJson<String?>(json['photoUrl']),
      level: serializer.fromJson<int>(json['level']),
      totalXp: serializer.fromJson<int>(json['totalXp']),
      currentStreak: serializer.fromJson<int>(json['currentStreak']),
      longestStreak: serializer.fromJson<int>(json['longestStreak']),
      isEmailVerified: serializer.fromJson<bool>(json['isEmailVerified']),
      authProvider: serializer.fromJson<String>(json['authProvider']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      lastActiveDate: serializer.fromJson<DateTime?>(json['lastActiveDate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'email': serializer.toJson<String>(email),
      'fullName': serializer.toJson<String>(fullName),
      'photoUrl': serializer.toJson<String?>(photoUrl),
      'level': serializer.toJson<int>(level),
      'totalXp': serializer.toJson<int>(totalXp),
      'currentStreak': serializer.toJson<int>(currentStreak),
      'longestStreak': serializer.toJson<int>(longestStreak),
      'isEmailVerified': serializer.toJson<bool>(isEmailVerified),
      'authProvider': serializer.toJson<String>(authProvider),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'lastActiveDate': serializer.toJson<DateTime?>(lastActiveDate),
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? fullName,
    Value<String?> photoUrl = const Value.absent(),
    int? level,
    int? totalXp,
    int? currentStreak,
    int? longestStreak,
    bool? isEmailVerified,
    String? authProvider,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> lastActiveDate = const Value.absent(),
  }) => User(
    id: id ?? this.id,
    email: email ?? this.email,
    fullName: fullName ?? this.fullName,
    photoUrl: photoUrl.present ? photoUrl.value : this.photoUrl,
    level: level ?? this.level,
    totalXp: totalXp ?? this.totalXp,
    currentStreak: currentStreak ?? this.currentStreak,
    longestStreak: longestStreak ?? this.longestStreak,
    isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    authProvider: authProvider ?? this.authProvider,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    lastActiveDate: lastActiveDate.present
        ? lastActiveDate.value
        : this.lastActiveDate,
  );
  User copyWithCompanion(UsersCompanion data) {
    return User(
      id: data.id.present ? data.id.value : this.id,
      email: data.email.present ? data.email.value : this.email,
      fullName: data.fullName.present ? data.fullName.value : this.fullName,
      photoUrl: data.photoUrl.present ? data.photoUrl.value : this.photoUrl,
      level: data.level.present ? data.level.value : this.level,
      totalXp: data.totalXp.present ? data.totalXp.value : this.totalXp,
      currentStreak: data.currentStreak.present
          ? data.currentStreak.value
          : this.currentStreak,
      longestStreak: data.longestStreak.present
          ? data.longestStreak.value
          : this.longestStreak,
      isEmailVerified: data.isEmailVerified.present
          ? data.isEmailVerified.value
          : this.isEmailVerified,
      authProvider: data.authProvider.present
          ? data.authProvider.value
          : this.authProvider,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      lastActiveDate: data.lastActiveDate.present
          ? data.lastActiveDate.value
          : this.lastActiveDate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('User(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('level: $level, ')
          ..write('totalXp: $totalXp, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('isEmailVerified: $isEmailVerified, ')
          ..write('authProvider: $authProvider, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastActiveDate: $lastActiveDate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    email,
    fullName,
    photoUrl,
    level,
    totalXp,
    currentStreak,
    longestStreak,
    isEmailVerified,
    authProvider,
    createdAt,
    updatedAt,
    lastActiveDate,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is User &&
          other.id == this.id &&
          other.email == this.email &&
          other.fullName == this.fullName &&
          other.photoUrl == this.photoUrl &&
          other.level == this.level &&
          other.totalXp == this.totalXp &&
          other.currentStreak == this.currentStreak &&
          other.longestStreak == this.longestStreak &&
          other.isEmailVerified == this.isEmailVerified &&
          other.authProvider == this.authProvider &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.lastActiveDate == this.lastActiveDate);
}

class UsersCompanion extends UpdateCompanion<User> {
  final Value<String> id;
  final Value<String> email;
  final Value<String> fullName;
  final Value<String?> photoUrl;
  final Value<int> level;
  final Value<int> totalXp;
  final Value<int> currentStreak;
  final Value<int> longestStreak;
  final Value<bool> isEmailVerified;
  final Value<String> authProvider;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> lastActiveDate;
  final Value<int> rowid;
  const UsersCompanion({
    this.id = const Value.absent(),
    this.email = const Value.absent(),
    this.fullName = const Value.absent(),
    this.photoUrl = const Value.absent(),
    this.level = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.isEmailVerified = const Value.absent(),
    this.authProvider = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.lastActiveDate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  UsersCompanion.insert({
    required String id,
    required String email,
    required String fullName,
    this.photoUrl = const Value.absent(),
    this.level = const Value.absent(),
    this.totalXp = const Value.absent(),
    this.currentStreak = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.isEmailVerified = const Value.absent(),
    this.authProvider = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.lastActiveDate = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       email = Value(email),
       fullName = Value(fullName),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<User> custom({
    Expression<String>? id,
    Expression<String>? email,
    Expression<String>? fullName,
    Expression<String>? photoUrl,
    Expression<int>? level,
    Expression<int>? totalXp,
    Expression<int>? currentStreak,
    Expression<int>? longestStreak,
    Expression<bool>? isEmailVerified,
    Expression<String>? authProvider,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? lastActiveDate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (fullName != null) 'full_name': fullName,
      if (photoUrl != null) 'photo_url': photoUrl,
      if (level != null) 'level': level,
      if (totalXp != null) 'total_xp': totalXp,
      if (currentStreak != null) 'current_streak': currentStreak,
      if (longestStreak != null) 'longest_streak': longestStreak,
      if (isEmailVerified != null) 'is_email_verified': isEmailVerified,
      if (authProvider != null) 'auth_provider': authProvider,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (lastActiveDate != null) 'last_active_date': lastActiveDate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  UsersCompanion copyWith({
    Value<String>? id,
    Value<String>? email,
    Value<String>? fullName,
    Value<String?>? photoUrl,
    Value<int>? level,
    Value<int>? totalXp,
    Value<int>? currentStreak,
    Value<int>? longestStreak,
    Value<bool>? isEmailVerified,
    Value<String>? authProvider,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? lastActiveDate,
    Value<int>? rowid,
  }) {
    return UsersCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      authProvider: authProvider ?? this.authProvider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (email.present) {
      map['email'] = Variable<String>(email.value);
    }
    if (fullName.present) {
      map['full_name'] = Variable<String>(fullName.value);
    }
    if (photoUrl.present) {
      map['photo_url'] = Variable<String>(photoUrl.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (totalXp.present) {
      map['total_xp'] = Variable<int>(totalXp.value);
    }
    if (currentStreak.present) {
      map['current_streak'] = Variable<int>(currentStreak.value);
    }
    if (longestStreak.present) {
      map['longest_streak'] = Variable<int>(longestStreak.value);
    }
    if (isEmailVerified.present) {
      map['is_email_verified'] = Variable<bool>(isEmailVerified.value);
    }
    if (authProvider.present) {
      map['auth_provider'] = Variable<String>(authProvider.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (lastActiveDate.present) {
      map['last_active_date'] = Variable<DateTime>(lastActiveDate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('UsersCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('fullName: $fullName, ')
          ..write('photoUrl: $photoUrl, ')
          ..write('level: $level, ')
          ..write('totalXp: $totalXp, ')
          ..write('currentStreak: $currentStreak, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('isEmailVerified: $isEmailVerified, ')
          ..write('authProvider: $authProvider, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('lastActiveDate: $lastActiveDate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, Task> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpRewardMeta = const VerificationMeta(
    'xpReward',
  );
  @override
  late final GeneratedColumn<int> xpReward = GeneratedColumn<int>(
    'xp_reward',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(25),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _streakCountMeta = const VerificationMeta(
    'streakCount',
  );
  @override
  late final GeneratedColumn<int> streakCount = GeneratedColumn<int>(
    'streak_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastCompletedDateMeta = const VerificationMeta(
    'lastCompletedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastCompletedDate =
      GeneratedColumn<DateTime>(
        'last_completed_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    description,
    type,
    category,
    xpReward,
    difficulty,
    dueDate,
    isCompleted,
    streakCount,
    lastCompletedDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Task> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('xp_reward')) {
      context.handle(
        _xpRewardMeta,
        xpReward.isAcceptableOrUnknown(data['xp_reward']!, _xpRewardMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('streak_count')) {
      context.handle(
        _streakCountMeta,
        streakCount.isAcceptableOrUnknown(
          data['streak_count']!,
          _streakCountMeta,
        ),
      );
    }
    if (data.containsKey('last_completed_date')) {
      context.handle(
        _lastCompletedDateMeta,
        lastCompletedDate.isAcceptableOrUnknown(
          data['last_completed_date']!,
          _lastCompletedDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Task map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Task(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      xpReward: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_reward'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      streakCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_count'],
      )!,
      lastCompletedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_completed_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class Task extends DataClass implements Insertable<Task> {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String type;
  final String category;
  final int xpReward;
  final int difficulty;
  final DateTime? dueDate;
  final bool isCompleted;
  final int streakCount;
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Task({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.type,
    required this.category,
    required this.xpReward,
    required this.difficulty,
    this.dueDate,
    required this.isCompleted,
    required this.streakCount,
    this.lastCompletedDate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['type'] = Variable<String>(type);
    map['category'] = Variable<String>(category);
    map['xp_reward'] = Variable<int>(xpReward);
    map['difficulty'] = Variable<int>(difficulty);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    map['streak_count'] = Variable<int>(streakCount);
    if (!nullToAbsent || lastCompletedDate != null) {
      map['last_completed_date'] = Variable<DateTime>(lastCompletedDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      type: Value(type),
      category: Value(category),
      xpReward: Value(xpReward),
      difficulty: Value(difficulty),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      isCompleted: Value(isCompleted),
      streakCount: Value(streakCount),
      lastCompletedDate: lastCompletedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Task.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Task(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      type: serializer.fromJson<String>(json['type']),
      category: serializer.fromJson<String>(json['category']),
      xpReward: serializer.fromJson<int>(json['xpReward']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      streakCount: serializer.fromJson<int>(json['streakCount']),
      lastCompletedDate: serializer.fromJson<DateTime?>(
        json['lastCompletedDate'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'type': serializer.toJson<String>(type),
      'category': serializer.toJson<String>(category),
      'xpReward': serializer.toJson<int>(xpReward),
      'difficulty': serializer.toJson<int>(difficulty),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'streakCount': serializer.toJson<int>(streakCount),
      'lastCompletedDate': serializer.toJson<DateTime?>(lastCompletedDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Task copyWith({
    String? id,
    String? userId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? type,
    String? category,
    int? xpReward,
    int? difficulty,
    Value<DateTime?> dueDate = const Value.absent(),
    bool? isCompleted,
    int? streakCount,
    Value<DateTime?> lastCompletedDate = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Task(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    type: type ?? this.type,
    category: category ?? this.category,
    xpReward: xpReward ?? this.xpReward,
    difficulty: difficulty ?? this.difficulty,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    isCompleted: isCompleted ?? this.isCompleted,
    streakCount: streakCount ?? this.streakCount,
    lastCompletedDate: lastCompletedDate.present
        ? lastCompletedDate.value
        : this.lastCompletedDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Task copyWithCompanion(TasksCompanion data) {
    return Task(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      type: data.type.present ? data.type.value : this.type,
      category: data.category.present ? data.category.value : this.category,
      xpReward: data.xpReward.present ? data.xpReward.value : this.xpReward,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      streakCount: data.streakCount.present
          ? data.streakCount.value
          : this.streakCount,
      lastCompletedDate: data.lastCompletedDate.present
          ? data.lastCompletedDate.value
          : this.lastCompletedDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Task(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('xpReward: $xpReward, ')
          ..write('difficulty: $difficulty, ')
          ..write('dueDate: $dueDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('streakCount: $streakCount, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    description,
    type,
    category,
    xpReward,
    difficulty,
    dueDate,
    isCompleted,
    streakCount,
    lastCompletedDate,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Task &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.description == this.description &&
          other.type == this.type &&
          other.category == this.category &&
          other.xpReward == this.xpReward &&
          other.difficulty == this.difficulty &&
          other.dueDate == this.dueDate &&
          other.isCompleted == this.isCompleted &&
          other.streakCount == this.streakCount &&
          other.lastCompletedDate == this.lastCompletedDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class TasksCompanion extends UpdateCompanion<Task> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> type;
  final Value<String> category;
  final Value<int> xpReward;
  final Value<int> difficulty;
  final Value<DateTime?> dueDate;
  final Value<bool> isCompleted;
  final Value<int> streakCount;
  final Value<DateTime?> lastCompletedDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.type = const Value.absent(),
    this.category = const Value.absent(),
    this.xpReward = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String userId,
    required String title,
    this.description = const Value.absent(),
    required String type,
    required String category,
    this.xpReward = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       title = Value(title),
       type = Value(type),
       category = Value(category),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Task> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? type,
    Expression<String>? category,
    Expression<int>? xpReward,
    Expression<int>? difficulty,
    Expression<DateTime>? dueDate,
    Expression<bool>? isCompleted,
    Expression<int>? streakCount,
    Expression<DateTime>? lastCompletedDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (xpReward != null) 'xp_reward': xpReward,
      if (difficulty != null) 'difficulty': difficulty,
      if (dueDate != null) 'due_date': dueDate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (streakCount != null) 'streak_count': streakCount,
      if (lastCompletedDate != null) 'last_completed_date': lastCompletedDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? type,
    Value<String>? category,
    Value<int>? xpReward,
    Value<int>? difficulty,
    Value<DateTime?>? dueDate,
    Value<bool>? isCompleted,
    Value<int>? streakCount,
    Value<DateTime?>? lastCompletedDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      category: category ?? this.category,
      xpReward: xpReward ?? this.xpReward,
      difficulty: difficulty ?? this.difficulty,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      streakCount: streakCount ?? this.streakCount,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (xpReward.present) {
      map['xp_reward'] = Variable<int>(xpReward.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (streakCount.present) {
      map['streak_count'] = Variable<int>(streakCount.value);
    }
    if (lastCompletedDate.present) {
      map['last_completed_date'] = Variable<DateTime>(lastCompletedDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('type: $type, ')
          ..write('category: $category, ')
          ..write('xpReward: $xpReward, ')
          ..write('difficulty: $difficulty, ')
          ..write('dueDate: $dueDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('streakCount: $streakCount, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<int> difficulty = GeneratedColumn<int>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isCompletedTodayMeta = const VerificationMeta(
    'isCompletedToday',
  );
  @override
  late final GeneratedColumn<bool> isCompletedToday = GeneratedColumn<bool>(
    'is_completed_today',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed_today" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _streakCountMeta = const VerificationMeta(
    'streakCount',
  );
  @override
  late final GeneratedColumn<int> streakCount = GeneratedColumn<int>(
    'streak_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _longestStreakMeta = const VerificationMeta(
    'longestStreak',
  );
  @override
  late final GeneratedColumn<int> longestStreak = GeneratedColumn<int>(
    'longest_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _completionRateMeta = const VerificationMeta(
    'completionRate',
  );
  @override
  late final GeneratedColumn<double> completionRate = GeneratedColumn<double>(
    'completion_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _totalCompletionsMeta = const VerificationMeta(
    'totalCompletions',
  );
  @override
  late final GeneratedColumn<int> totalCompletions = GeneratedColumn<int>(
    'total_completions',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastCompletedDateMeta = const VerificationMeta(
    'lastCompletedDate',
  );
  @override
  late final GeneratedColumn<DateTime> lastCompletedDate =
      GeneratedColumn<DateTime>(
        'last_completed_date',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    description,
    category,
    frequency,
    difficulty,
    isCompletedToday,
    streakCount,
    longestStreak,
    completionRate,
    totalCompletions,
    reminderTime,
    lastCompletedDate,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Habit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('is_completed_today')) {
      context.handle(
        _isCompletedTodayMeta,
        isCompletedToday.isAcceptableOrUnknown(
          data['is_completed_today']!,
          _isCompletedTodayMeta,
        ),
      );
    }
    if (data.containsKey('streak_count')) {
      context.handle(
        _streakCountMeta,
        streakCount.isAcceptableOrUnknown(
          data['streak_count']!,
          _streakCountMeta,
        ),
      );
    }
    if (data.containsKey('longest_streak')) {
      context.handle(
        _longestStreakMeta,
        longestStreak.isAcceptableOrUnknown(
          data['longest_streak']!,
          _longestStreakMeta,
        ),
      );
    }
    if (data.containsKey('completion_rate')) {
      context.handle(
        _completionRateMeta,
        completionRate.isAcceptableOrUnknown(
          data['completion_rate']!,
          _completionRateMeta,
        ),
      );
    }
    if (data.containsKey('total_completions')) {
      context.handle(
        _totalCompletionsMeta,
        totalCompletions.isAcceptableOrUnknown(
          data['total_completions']!,
          _totalCompletionsMeta,
        ),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('last_completed_date')) {
      context.handle(
        _lastCompletedDateMeta,
        lastCompletedDate.isAcceptableOrUnknown(
          data['last_completed_date']!,
          _lastCompletedDateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}difficulty'],
      )!,
      isCompletedToday: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed_today'],
      )!,
      streakCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_count'],
      )!,
      longestStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_streak'],
      )!,
      completionRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}completion_rate'],
      )!,
      totalCompletions: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_completions'],
      )!,
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      ),
      lastCompletedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_completed_date'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class Habit extends DataClass implements Insertable<Habit> {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final String frequency;
  final int difficulty;
  final bool isCompletedToday;
  final int streakCount;
  final int longestStreak;
  final double completionRate;
  final int totalCompletions;
  final String? reminderTime;
  final DateTime? lastCompletedDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Habit({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.frequency,
    required this.difficulty,
    required this.isCompletedToday,
    required this.streakCount,
    required this.longestStreak,
    required this.completionRate,
    required this.totalCompletions,
    this.reminderTime,
    this.lastCompletedDate,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['category'] = Variable<String>(category);
    map['frequency'] = Variable<String>(frequency);
    map['difficulty'] = Variable<int>(difficulty);
    map['is_completed_today'] = Variable<bool>(isCompletedToday);
    map['streak_count'] = Variable<int>(streakCount);
    map['longest_streak'] = Variable<int>(longestStreak);
    map['completion_rate'] = Variable<double>(completionRate);
    map['total_completions'] = Variable<int>(totalCompletions);
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    if (!nullToAbsent || lastCompletedDate != null) {
      map['last_completed_date'] = Variable<DateTime>(lastCompletedDate);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: Value(category),
      frequency: Value(frequency),
      difficulty: Value(difficulty),
      isCompletedToday: Value(isCompletedToday),
      streakCount: Value(streakCount),
      longestStreak: Value(longestStreak),
      completionRate: Value(completionRate),
      totalCompletions: Value(totalCompletions),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      lastCompletedDate: lastCompletedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCompletedDate),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Habit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      frequency: serializer.fromJson<String>(json['frequency']),
      difficulty: serializer.fromJson<int>(json['difficulty']),
      isCompletedToday: serializer.fromJson<bool>(json['isCompletedToday']),
      streakCount: serializer.fromJson<int>(json['streakCount']),
      longestStreak: serializer.fromJson<int>(json['longestStreak']),
      completionRate: serializer.fromJson<double>(json['completionRate']),
      totalCompletions: serializer.fromJson<int>(json['totalCompletions']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      lastCompletedDate: serializer.fromJson<DateTime?>(
        json['lastCompletedDate'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String>(category),
      'frequency': serializer.toJson<String>(frequency),
      'difficulty': serializer.toJson<int>(difficulty),
      'isCompletedToday': serializer.toJson<bool>(isCompletedToday),
      'streakCount': serializer.toJson<int>(streakCount),
      'longestStreak': serializer.toJson<int>(longestStreak),
      'completionRate': serializer.toJson<double>(completionRate),
      'totalCompletions': serializer.toJson<int>(totalCompletions),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'lastCompletedDate': serializer.toJson<DateTime?>(lastCompletedDate),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Habit copyWith({
    String? id,
    String? userId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? category,
    String? frequency,
    int? difficulty,
    bool? isCompletedToday,
    int? streakCount,
    int? longestStreak,
    double? completionRate,
    int? totalCompletions,
    Value<String?> reminderTime = const Value.absent(),
    Value<DateTime?> lastCompletedDate = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Habit(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    category: category ?? this.category,
    frequency: frequency ?? this.frequency,
    difficulty: difficulty ?? this.difficulty,
    isCompletedToday: isCompletedToday ?? this.isCompletedToday,
    streakCount: streakCount ?? this.streakCount,
    longestStreak: longestStreak ?? this.longestStreak,
    completionRate: completionRate ?? this.completionRate,
    totalCompletions: totalCompletions ?? this.totalCompletions,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    lastCompletedDate: lastCompletedDate.present
        ? lastCompletedDate.value
        : this.lastCompletedDate,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      isCompletedToday: data.isCompletedToday.present
          ? data.isCompletedToday.value
          : this.isCompletedToday,
      streakCount: data.streakCount.present
          ? data.streakCount.value
          : this.streakCount,
      longestStreak: data.longestStreak.present
          ? data.longestStreak.value
          : this.longestStreak,
      completionRate: data.completionRate.present
          ? data.completionRate.value
          : this.completionRate,
      totalCompletions: data.totalCompletions.present
          ? data.totalCompletions.value
          : this.totalCompletions,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      lastCompletedDate: data.lastCompletedDate.present
          ? data.lastCompletedDate.value
          : this.lastCompletedDate,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('frequency: $frequency, ')
          ..write('difficulty: $difficulty, ')
          ..write('isCompletedToday: $isCompletedToday, ')
          ..write('streakCount: $streakCount, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('completionRate: $completionRate, ')
          ..write('totalCompletions: $totalCompletions, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    description,
    category,
    frequency,
    difficulty,
    isCompletedToday,
    streakCount,
    longestStreak,
    completionRate,
    totalCompletions,
    reminderTime,
    lastCompletedDate,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.frequency == this.frequency &&
          other.difficulty == this.difficulty &&
          other.isCompletedToday == this.isCompletedToday &&
          other.streakCount == this.streakCount &&
          other.longestStreak == this.longestStreak &&
          other.completionRate == this.completionRate &&
          other.totalCompletions == this.totalCompletions &&
          other.reminderTime == this.reminderTime &&
          other.lastCompletedDate == this.lastCompletedDate &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> category;
  final Value<String> frequency;
  final Value<int> difficulty;
  final Value<bool> isCompletedToday;
  final Value<int> streakCount;
  final Value<int> longestStreak;
  final Value<double> completionRate;
  final Value<int> totalCompletions;
  final Value<String?> reminderTime;
  final Value<DateTime?> lastCompletedDate;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.frequency = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.isCompletedToday = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.completionRate = const Value.absent(),
    this.totalCompletions = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsCompanion.insert({
    required String id,
    required String userId,
    required String title,
    this.description = const Value.absent(),
    required String category,
    required String frequency,
    this.difficulty = const Value.absent(),
    this.isCompletedToday = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.completionRate = const Value.absent(),
    this.totalCompletions = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.lastCompletedDate = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       title = Value(title),
       category = Value(category),
       frequency = Value(frequency),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Habit> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? frequency,
    Expression<int>? difficulty,
    Expression<bool>? isCompletedToday,
    Expression<int>? streakCount,
    Expression<int>? longestStreak,
    Expression<double>? completionRate,
    Expression<int>? totalCompletions,
    Expression<String>? reminderTime,
    Expression<DateTime>? lastCompletedDate,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (frequency != null) 'frequency': frequency,
      if (difficulty != null) 'difficulty': difficulty,
      if (isCompletedToday != null) 'is_completed_today': isCompletedToday,
      if (streakCount != null) 'streak_count': streakCount,
      if (longestStreak != null) 'longest_streak': longestStreak,
      if (completionRate != null) 'completion_rate': completionRate,
      if (totalCompletions != null) 'total_completions': totalCompletions,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (lastCompletedDate != null) 'last_completed_date': lastCompletedDate,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? category,
    Value<String>? frequency,
    Value<int>? difficulty,
    Value<bool>? isCompletedToday,
    Value<int>? streakCount,
    Value<int>? longestStreak,
    Value<double>? completionRate,
    Value<int>? totalCompletions,
    Value<String?>? reminderTime,
    Value<DateTime?>? lastCompletedDate,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      difficulty: difficulty ?? this.difficulty,
      isCompletedToday: isCompletedToday ?? this.isCompletedToday,
      streakCount: streakCount ?? this.streakCount,
      longestStreak: longestStreak ?? this.longestStreak,
      completionRate: completionRate ?? this.completionRate,
      totalCompletions: totalCompletions ?? this.totalCompletions,
      reminderTime: reminderTime ?? this.reminderTime,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<int>(difficulty.value);
    }
    if (isCompletedToday.present) {
      map['is_completed_today'] = Variable<bool>(isCompletedToday.value);
    }
    if (streakCount.present) {
      map['streak_count'] = Variable<int>(streakCount.value);
    }
    if (longestStreak.present) {
      map['longest_streak'] = Variable<int>(longestStreak.value);
    }
    if (completionRate.present) {
      map['completion_rate'] = Variable<double>(completionRate.value);
    }
    if (totalCompletions.present) {
      map['total_completions'] = Variable<int>(totalCompletions.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (lastCompletedDate.present) {
      map['last_completed_date'] = Variable<DateTime>(lastCompletedDate.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('frequency: $frequency, ')
          ..write('difficulty: $difficulty, ')
          ..write('isCompletedToday: $isCompletedToday, ')
          ..write('streakCount: $streakCount, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('completionRate: $completionRate, ')
          ..write('totalCompletions: $totalCompletions, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('lastCompletedDate: $lastCompletedDate, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, Goal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<String> priority = GeneratedColumn<String>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _deadlineMeta = const VerificationMeta(
    'deadline',
  );
  @override
  late final GeneratedColumn<DateTime> deadline = GeneratedColumn<DateTime>(
    'deadline',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _parentGoalIdMeta = const VerificationMeta(
    'parentGoalId',
  );
  @override
  late final GeneratedColumn<String> parentGoalId = GeneratedColumn<String>(
    'parent_goal_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    description,
    category,
    priority,
    status,
    progress,
    startDate,
    deadline,
    completedAt,
    parentGoalId,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<Goal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    } else if (isInserting) {
      context.missing(_priorityMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    }
    if (data.containsKey('deadline')) {
      context.handle(
        _deadlineMeta,
        deadline.isAcceptableOrUnknown(data['deadline']!, _deadlineMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('parent_goal_id')) {
      context.handle(
        _parentGoalIdMeta,
        parentGoalId.isAcceptableOrUnknown(
          data['parent_goal_id']!,
          _parentGoalIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Goal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Goal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      ),
      deadline: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deadline'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      parentGoalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_goal_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class Goal extends DataClass implements Insertable<Goal> {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String category;
  final String priority;
  final String status;
  final double progress;
  final DateTime? startDate;
  final DateTime? deadline;
  final DateTime? completedAt;
  final String? parentGoalId;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Goal({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.progress,
    this.startDate,
    this.deadline,
    this.completedAt,
    this.parentGoalId,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['category'] = Variable<String>(category);
    map['priority'] = Variable<String>(priority);
    map['status'] = Variable<String>(status);
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || startDate != null) {
      map['start_date'] = Variable<DateTime>(startDate);
    }
    if (!nullToAbsent || deadline != null) {
      map['deadline'] = Variable<DateTime>(deadline);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || parentGoalId != null) {
      map['parent_goal_id'] = Variable<String>(parentGoalId);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      category: Value(category),
      priority: Value(priority),
      status: Value(status),
      progress: Value(progress),
      startDate: startDate == null && nullToAbsent
          ? const Value.absent()
          : Value(startDate),
      deadline: deadline == null && nullToAbsent
          ? const Value.absent()
          : Value(deadline),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      parentGoalId: parentGoalId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentGoalId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Goal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Goal(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      category: serializer.fromJson<String>(json['category']),
      priority: serializer.fromJson<String>(json['priority']),
      status: serializer.fromJson<String>(json['status']),
      progress: serializer.fromJson<double>(json['progress']),
      startDate: serializer.fromJson<DateTime?>(json['startDate']),
      deadline: serializer.fromJson<DateTime?>(json['deadline']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      parentGoalId: serializer.fromJson<String?>(json['parentGoalId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'category': serializer.toJson<String>(category),
      'priority': serializer.toJson<String>(priority),
      'status': serializer.toJson<String>(status),
      'progress': serializer.toJson<double>(progress),
      'startDate': serializer.toJson<DateTime?>(startDate),
      'deadline': serializer.toJson<DateTime?>(deadline),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'parentGoalId': serializer.toJson<String?>(parentGoalId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Goal copyWith({
    String? id,
    String? userId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? category,
    String? priority,
    String? status,
    double? progress,
    Value<DateTime?> startDate = const Value.absent(),
    Value<DateTime?> deadline = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> parentGoalId = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Goal(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    category: category ?? this.category,
    priority: priority ?? this.priority,
    status: status ?? this.status,
    progress: progress ?? this.progress,
    startDate: startDate.present ? startDate.value : this.startDate,
    deadline: deadline.present ? deadline.value : this.deadline,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    parentGoalId: parentGoalId.present ? parentGoalId.value : this.parentGoalId,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Goal copyWithCompanion(GoalsCompanion data) {
    return Goal(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      category: data.category.present ? data.category.value : this.category,
      priority: data.priority.present ? data.priority.value : this.priority,
      status: data.status.present ? data.status.value : this.status,
      progress: data.progress.present ? data.progress.value : this.progress,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      deadline: data.deadline.present ? data.deadline.value : this.deadline,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      parentGoalId: data.parentGoalId.present
          ? data.parentGoalId.value
          : this.parentGoalId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Goal(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('startDate: $startDate, ')
          ..write('deadline: $deadline, ')
          ..write('completedAt: $completedAt, ')
          ..write('parentGoalId: $parentGoalId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    description,
    category,
    priority,
    status,
    progress,
    startDate,
    deadline,
    completedAt,
    parentGoalId,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Goal &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.description == this.description &&
          other.category == this.category &&
          other.priority == this.priority &&
          other.status == this.status &&
          other.progress == this.progress &&
          other.startDate == this.startDate &&
          other.deadline == this.deadline &&
          other.completedAt == this.completedAt &&
          other.parentGoalId == this.parentGoalId &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class GoalsCompanion extends UpdateCompanion<Goal> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> category;
  final Value<String> priority;
  final Value<String> status;
  final Value<double> progress;
  final Value<DateTime?> startDate;
  final Value<DateTime?> deadline;
  final Value<DateTime?> completedAt;
  final Value<String?> parentGoalId;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.category = const Value.absent(),
    this.priority = const Value.absent(),
    this.status = const Value.absent(),
    this.progress = const Value.absent(),
    this.startDate = const Value.absent(),
    this.deadline = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.parentGoalId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String userId,
    required String title,
    this.description = const Value.absent(),
    required String category,
    required String priority,
    required String status,
    this.progress = const Value.absent(),
    this.startDate = const Value.absent(),
    this.deadline = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.parentGoalId = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       title = Value(title),
       category = Value(category),
       priority = Value(priority),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Goal> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? category,
    Expression<String>? priority,
    Expression<String>? status,
    Expression<double>? progress,
    Expression<DateTime>? startDate,
    Expression<DateTime>? deadline,
    Expression<DateTime>? completedAt,
    Expression<String>? parentGoalId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (category != null) 'category': category,
      if (priority != null) 'priority': priority,
      if (status != null) 'status': status,
      if (progress != null) 'progress': progress,
      if (startDate != null) 'start_date': startDate,
      if (deadline != null) 'deadline': deadline,
      if (completedAt != null) 'completed_at': completedAt,
      if (parentGoalId != null) 'parent_goal_id': parentGoalId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? category,
    Value<String>? priority,
    Value<String>? status,
    Value<double>? progress,
    Value<DateTime?>? startDate,
    Value<DateTime?>? deadline,
    Value<DateTime?>? completedAt,
    Value<String?>? parentGoalId,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      startDate: startDate ?? this.startDate,
      deadline: deadline ?? this.deadline,
      completedAt: completedAt ?? this.completedAt,
      parentGoalId: parentGoalId ?? this.parentGoalId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (priority.present) {
      map['priority'] = Variable<String>(priority.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (deadline.present) {
      map['deadline'] = Variable<DateTime>(deadline.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (parentGoalId.present) {
      map['parent_goal_id'] = Variable<String>(parentGoalId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('category: $category, ')
          ..write('priority: $priority, ')
          ..write('status: $status, ')
          ..write('progress: $progress, ')
          ..write('startDate: $startDate, ')
          ..write('deadline: $deadline, ')
          ..write('completedAt: $completedAt, ')
          ..write('parentGoalId: $parentGoalId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AvatarsTable extends Avatars with TableInfo<$AvatarsTable, Avatar> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AvatarsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<int> level = GeneratedColumn<int>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _currentXpMeta = const VerificationMeta(
    'currentXp',
  );
  @override
  late final GeneratedColumn<int> currentXp = GeneratedColumn<int>(
    'current_xp',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _strengthMeta = const VerificationMeta(
    'strength',
  );
  @override
  late final GeneratedColumn<int> strength = GeneratedColumn<int>(
    'strength',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _wisdomMeta = const VerificationMeta('wisdom');
  @override
  late final GeneratedColumn<int> wisdom = GeneratedColumn<int>(
    'wisdom',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _intelligenceMeta = const VerificationMeta(
    'intelligence',
  );
  @override
  late final GeneratedColumn<int> intelligence = GeneratedColumn<int>(
    'intelligence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _appearanceDataMeta = const VerificationMeta(
    'appearanceData',
  );
  @override
  late final GeneratedColumn<String> appearanceData = GeneratedColumn<String>(
    'appearance_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _unlockedItemsMeta = const VerificationMeta(
    'unlockedItems',
  );
  @override
  late final GeneratedColumn<String> unlockedItems = GeneratedColumn<String>(
    'unlocked_items',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    level,
    currentXp,
    strength,
    wisdom,
    intelligence,
    appearanceData,
    unlockedItems,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'avatars';
  @override
  VerificationContext validateIntegrity(
    Insertable<Avatar> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    }
    if (data.containsKey('current_xp')) {
      context.handle(
        _currentXpMeta,
        currentXp.isAcceptableOrUnknown(data['current_xp']!, _currentXpMeta),
      );
    }
    if (data.containsKey('strength')) {
      context.handle(
        _strengthMeta,
        strength.isAcceptableOrUnknown(data['strength']!, _strengthMeta),
      );
    }
    if (data.containsKey('wisdom')) {
      context.handle(
        _wisdomMeta,
        wisdom.isAcceptableOrUnknown(data['wisdom']!, _wisdomMeta),
      );
    }
    if (data.containsKey('intelligence')) {
      context.handle(
        _intelligenceMeta,
        intelligence.isAcceptableOrUnknown(
          data['intelligence']!,
          _intelligenceMeta,
        ),
      );
    }
    if (data.containsKey('appearance_data')) {
      context.handle(
        _appearanceDataMeta,
        appearanceData.isAcceptableOrUnknown(
          data['appearance_data']!,
          _appearanceDataMeta,
        ),
      );
    }
    if (data.containsKey('unlocked_items')) {
      context.handle(
        _unlockedItemsMeta,
        unlockedItems.isAcceptableOrUnknown(
          data['unlocked_items']!,
          _unlockedItemsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Avatar map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Avatar(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level'],
      )!,
      currentXp: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_xp'],
      )!,
      strength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}strength'],
      )!,
      wisdom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}wisdom'],
      )!,
      intelligence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}intelligence'],
      )!,
      appearanceData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}appearance_data'],
      ),
      unlockedItems: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unlocked_items'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AvatarsTable createAlias(String alias) {
    return $AvatarsTable(attachedDatabase, alias);
  }
}

class Avatar extends DataClass implements Insertable<Avatar> {
  final String id;
  final String userId;
  final String name;
  final int level;
  final int currentXp;
  final int strength;
  final int wisdom;
  final int intelligence;
  final String? appearanceData;
  final String? unlockedItems;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Avatar({
    required this.id,
    required this.userId,
    required this.name,
    required this.level,
    required this.currentXp,
    required this.strength,
    required this.wisdom,
    required this.intelligence,
    this.appearanceData,
    this.unlockedItems,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    map['level'] = Variable<int>(level);
    map['current_xp'] = Variable<int>(currentXp);
    map['strength'] = Variable<int>(strength);
    map['wisdom'] = Variable<int>(wisdom);
    map['intelligence'] = Variable<int>(intelligence);
    if (!nullToAbsent || appearanceData != null) {
      map['appearance_data'] = Variable<String>(appearanceData);
    }
    if (!nullToAbsent || unlockedItems != null) {
      map['unlocked_items'] = Variable<String>(unlockedItems);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AvatarsCompanion toCompanion(bool nullToAbsent) {
    return AvatarsCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      level: Value(level),
      currentXp: Value(currentXp),
      strength: Value(strength),
      wisdom: Value(wisdom),
      intelligence: Value(intelligence),
      appearanceData: appearanceData == null && nullToAbsent
          ? const Value.absent()
          : Value(appearanceData),
      unlockedItems: unlockedItems == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockedItems),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Avatar.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Avatar(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      level: serializer.fromJson<int>(json['level']),
      currentXp: serializer.fromJson<int>(json['currentXp']),
      strength: serializer.fromJson<int>(json['strength']),
      wisdom: serializer.fromJson<int>(json['wisdom']),
      intelligence: serializer.fromJson<int>(json['intelligence']),
      appearanceData: serializer.fromJson<String?>(json['appearanceData']),
      unlockedItems: serializer.fromJson<String?>(json['unlockedItems']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'level': serializer.toJson<int>(level),
      'currentXp': serializer.toJson<int>(currentXp),
      'strength': serializer.toJson<int>(strength),
      'wisdom': serializer.toJson<int>(wisdom),
      'intelligence': serializer.toJson<int>(intelligence),
      'appearanceData': serializer.toJson<String?>(appearanceData),
      'unlockedItems': serializer.toJson<String?>(unlockedItems),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Avatar copyWith({
    String? id,
    String? userId,
    String? name,
    int? level,
    int? currentXp,
    int? strength,
    int? wisdom,
    int? intelligence,
    Value<String?> appearanceData = const Value.absent(),
    Value<String?> unlockedItems = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Avatar(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    level: level ?? this.level,
    currentXp: currentXp ?? this.currentXp,
    strength: strength ?? this.strength,
    wisdom: wisdom ?? this.wisdom,
    intelligence: intelligence ?? this.intelligence,
    appearanceData: appearanceData.present
        ? appearanceData.value
        : this.appearanceData,
    unlockedItems: unlockedItems.present
        ? unlockedItems.value
        : this.unlockedItems,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Avatar copyWithCompanion(AvatarsCompanion data) {
    return Avatar(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      level: data.level.present ? data.level.value : this.level,
      currentXp: data.currentXp.present ? data.currentXp.value : this.currentXp,
      strength: data.strength.present ? data.strength.value : this.strength,
      wisdom: data.wisdom.present ? data.wisdom.value : this.wisdom,
      intelligence: data.intelligence.present
          ? data.intelligence.value
          : this.intelligence,
      appearanceData: data.appearanceData.present
          ? data.appearanceData.value
          : this.appearanceData,
      unlockedItems: data.unlockedItems.present
          ? data.unlockedItems.value
          : this.unlockedItems,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Avatar(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('level: $level, ')
          ..write('currentXp: $currentXp, ')
          ..write('strength: $strength, ')
          ..write('wisdom: $wisdom, ')
          ..write('intelligence: $intelligence, ')
          ..write('appearanceData: $appearanceData, ')
          ..write('unlockedItems: $unlockedItems, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    level,
    currentXp,
    strength,
    wisdom,
    intelligence,
    appearanceData,
    unlockedItems,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Avatar &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.level == this.level &&
          other.currentXp == this.currentXp &&
          other.strength == this.strength &&
          other.wisdom == this.wisdom &&
          other.intelligence == this.intelligence &&
          other.appearanceData == this.appearanceData &&
          other.unlockedItems == this.unlockedItems &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AvatarsCompanion extends UpdateCompanion<Avatar> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<int> level;
  final Value<int> currentXp;
  final Value<int> strength;
  final Value<int> wisdom;
  final Value<int> intelligence;
  final Value<String?> appearanceData;
  final Value<String?> unlockedItems;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AvatarsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.level = const Value.absent(),
    this.currentXp = const Value.absent(),
    this.strength = const Value.absent(),
    this.wisdom = const Value.absent(),
    this.intelligence = const Value.absent(),
    this.appearanceData = const Value.absent(),
    this.unlockedItems = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AvatarsCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.level = const Value.absent(),
    this.currentXp = const Value.absent(),
    this.strength = const Value.absent(),
    this.wisdom = const Value.absent(),
    this.intelligence = const Value.absent(),
    this.appearanceData = const Value.absent(),
    this.unlockedItems = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Avatar> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<int>? level,
    Expression<int>? currentXp,
    Expression<int>? strength,
    Expression<int>? wisdom,
    Expression<int>? intelligence,
    Expression<String>? appearanceData,
    Expression<String>? unlockedItems,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (level != null) 'level': level,
      if (currentXp != null) 'current_xp': currentXp,
      if (strength != null) 'strength': strength,
      if (wisdom != null) 'wisdom': wisdom,
      if (intelligence != null) 'intelligence': intelligence,
      if (appearanceData != null) 'appearance_data': appearanceData,
      if (unlockedItems != null) 'unlocked_items': unlockedItems,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AvatarsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<int>? level,
    Value<int>? currentXp,
    Value<int>? strength,
    Value<int>? wisdom,
    Value<int>? intelligence,
    Value<String?>? appearanceData,
    Value<String?>? unlockedItems,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AvatarsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      strength: strength ?? this.strength,
      wisdom: wisdom ?? this.wisdom,
      intelligence: intelligence ?? this.intelligence,
      appearanceData: appearanceData ?? this.appearanceData,
      unlockedItems: unlockedItems ?? this.unlockedItems,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (level.present) {
      map['level'] = Variable<int>(level.value);
    }
    if (currentXp.present) {
      map['current_xp'] = Variable<int>(currentXp.value);
    }
    if (strength.present) {
      map['strength'] = Variable<int>(strength.value);
    }
    if (wisdom.present) {
      map['wisdom'] = Variable<int>(wisdom.value);
    }
    if (intelligence.present) {
      map['intelligence'] = Variable<int>(intelligence.value);
    }
    if (appearanceData.present) {
      map['appearance_data'] = Variable<String>(appearanceData.value);
    }
    if (unlockedItems.present) {
      map['unlocked_items'] = Variable<String>(unlockedItems.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AvatarsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('level: $level, ')
          ..write('currentXp: $currentXp, ')
          ..write('strength: $strength, ')
          ..write('wisdom: $wisdom, ')
          ..write('intelligence: $intelligence, ')
          ..write('appearanceData: $appearanceData, ')
          ..write('unlockedItems: $unlockedItems, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, Achievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iconPathMeta = const VerificationMeta(
    'iconPath',
  );
  @override
  late final GeneratedColumn<String> iconPath = GeneratedColumn<String>(
    'icon_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _achievementTypeMeta = const VerificationMeta(
    'achievementType',
  );
  @override
  late final GeneratedColumn<String> achievementType = GeneratedColumn<String>(
    'achievement_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _criteriaMeta = const VerificationMeta(
    'criteria',
  );
  @override
  late final GeneratedColumn<String> criteria = GeneratedColumn<String>(
    'criteria',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isUnlockedMeta = const VerificationMeta(
    'isUnlocked',
  );
  @override
  late final GeneratedColumn<bool> isUnlocked = GeneratedColumn<bool>(
    'is_unlocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unlocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _progressMeta = const VerificationMeta(
    'progress',
  );
  @override
  late final GeneratedColumn<double> progress = GeneratedColumn<double>(
    'progress',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    title,
    description,
    iconPath,
    achievementType,
    criteria,
    isUnlocked,
    progress,
    unlockedAt,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Achievement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('icon_path')) {
      context.handle(
        _iconPathMeta,
        iconPath.isAcceptableOrUnknown(data['icon_path']!, _iconPathMeta),
      );
    }
    if (data.containsKey('achievement_type')) {
      context.handle(
        _achievementTypeMeta,
        achievementType.isAcceptableOrUnknown(
          data['achievement_type']!,
          _achievementTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_achievementTypeMeta);
    }
    if (data.containsKey('criteria')) {
      context.handle(
        _criteriaMeta,
        criteria.isAcceptableOrUnknown(data['criteria']!, _criteriaMeta),
      );
    }
    if (data.containsKey('is_unlocked')) {
      context.handle(
        _isUnlockedMeta,
        isUnlocked.isAcceptableOrUnknown(data['is_unlocked']!, _isUnlockedMeta),
      );
    }
    if (data.containsKey('progress')) {
      context.handle(
        _progressMeta,
        progress.isAcceptableOrUnknown(data['progress']!, _progressMeta),
      );
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Achievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Achievement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      iconPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon_path'],
      ),
      achievementType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}achievement_type'],
      )!,
      criteria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criteria'],
      ),
      isUnlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unlocked'],
      )!,
      progress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}progress'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class Achievement extends DataClass implements Insertable<Achievement> {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? iconPath;
  final String achievementType;
  final String? criteria;
  final bool isUnlocked;
  final double progress;
  final DateTime? unlockedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Achievement({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.iconPath,
    required this.achievementType,
    this.criteria,
    required this.isUnlocked,
    required this.progress,
    this.unlockedAt,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || iconPath != null) {
      map['icon_path'] = Variable<String>(iconPath);
    }
    map['achievement_type'] = Variable<String>(achievementType);
    if (!nullToAbsent || criteria != null) {
      map['criteria'] = Variable<String>(criteria);
    }
    map['is_unlocked'] = Variable<bool>(isUnlocked);
    map['progress'] = Variable<double>(progress);
    if (!nullToAbsent || unlockedAt != null) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      userId: Value(userId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      iconPath: iconPath == null && nullToAbsent
          ? const Value.absent()
          : Value(iconPath),
      achievementType: Value(achievementType),
      criteria: criteria == null && nullToAbsent
          ? const Value.absent()
          : Value(criteria),
      isUnlocked: Value(isUnlocked),
      progress: Value(progress),
      unlockedAt: unlockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockedAt),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Achievement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Achievement(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      iconPath: serializer.fromJson<String?>(json['iconPath']),
      achievementType: serializer.fromJson<String>(json['achievementType']),
      criteria: serializer.fromJson<String?>(json['criteria']),
      isUnlocked: serializer.fromJson<bool>(json['isUnlocked']),
      progress: serializer.fromJson<double>(json['progress']),
      unlockedAt: serializer.fromJson<DateTime?>(json['unlockedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'iconPath': serializer.toJson<String?>(iconPath),
      'achievementType': serializer.toJson<String>(achievementType),
      'criteria': serializer.toJson<String?>(criteria),
      'isUnlocked': serializer.toJson<bool>(isUnlocked),
      'progress': serializer.toJson<double>(progress),
      'unlockedAt': serializer.toJson<DateTime?>(unlockedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Achievement copyWith({
    String? id,
    String? userId,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<String?> iconPath = const Value.absent(),
    String? achievementType,
    Value<String?> criteria = const Value.absent(),
    bool? isUnlocked,
    double? progress,
    Value<DateTime?> unlockedAt = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Achievement(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    iconPath: iconPath.present ? iconPath.value : this.iconPath,
    achievementType: achievementType ?? this.achievementType,
    criteria: criteria.present ? criteria.value : this.criteria,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    progress: progress ?? this.progress,
    unlockedAt: unlockedAt.present ? unlockedAt.value : this.unlockedAt,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Achievement copyWithCompanion(AchievementsCompanion data) {
    return Achievement(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      iconPath: data.iconPath.present ? data.iconPath.value : this.iconPath,
      achievementType: data.achievementType.present
          ? data.achievementType.value
          : this.achievementType,
      criteria: data.criteria.present ? data.criteria.value : this.criteria,
      isUnlocked: data.isUnlocked.present
          ? data.isUnlocked.value
          : this.isUnlocked,
      progress: data.progress.present ? data.progress.value : this.progress,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Achievement(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('iconPath: $iconPath, ')
          ..write('achievementType: $achievementType, ')
          ..write('criteria: $criteria, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('progress: $progress, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    title,
    description,
    iconPath,
    achievementType,
    criteria,
    isUnlocked,
    progress,
    unlockedAt,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.title == this.title &&
          other.description == this.description &&
          other.iconPath == this.iconPath &&
          other.achievementType == this.achievementType &&
          other.criteria == this.criteria &&
          other.isUnlocked == this.isUnlocked &&
          other.progress == this.progress &&
          other.unlockedAt == this.unlockedAt &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AchievementsCompanion extends UpdateCompanion<Achievement> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String?> iconPath;
  final Value<String> achievementType;
  final Value<String?> criteria;
  final Value<bool> isUnlocked;
  final Value<double> progress;
  final Value<DateTime?> unlockedAt;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.iconPath = const Value.absent(),
    this.achievementType = const Value.absent(),
    this.criteria = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.progress = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementsCompanion.insert({
    required String id,
    required String userId,
    required String title,
    this.description = const Value.absent(),
    this.iconPath = const Value.absent(),
    required String achievementType,
    this.criteria = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.progress = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       title = Value(title),
       achievementType = Value(achievementType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<Achievement> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? iconPath,
    Expression<String>? achievementType,
    Expression<String>? criteria,
    Expression<bool>? isUnlocked,
    Expression<double>? progress,
    Expression<DateTime>? unlockedAt,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (iconPath != null) 'icon_path': iconPath,
      if (achievementType != null) 'achievement_type': achievementType,
      if (criteria != null) 'criteria': criteria,
      if (isUnlocked != null) 'is_unlocked': isUnlocked,
      if (progress != null) 'progress': progress,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementsCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? title,
    Value<String?>? description,
    Value<String?>? iconPath,
    Value<String>? achievementType,
    Value<String?>? criteria,
    Value<bool>? isUnlocked,
    Value<double>? progress,
    Value<DateTime?>? unlockedAt,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AchievementsCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      iconPath: iconPath ?? this.iconPath,
      achievementType: achievementType ?? this.achievementType,
      criteria: criteria ?? this.criteria,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progress: progress ?? this.progress,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (iconPath.present) {
      map['icon_path'] = Variable<String>(iconPath.value);
    }
    if (achievementType.present) {
      map['achievement_type'] = Variable<String>(achievementType.value);
    }
    if (criteria.present) {
      map['criteria'] = Variable<String>(criteria.value);
    }
    if (isUnlocked.present) {
      map['is_unlocked'] = Variable<bool>(isUnlocked.value);
    }
    if (progress.present) {
      map['progress'] = Variable<double>(progress.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('iconPath: $iconPath, ')
          ..write('achievementType: $achievementType, ')
          ..write('criteria: $criteria, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('progress: $progress, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorldTilesTable extends WorldTiles
    with TableInfo<$WorldTilesTable, WorldTile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorldTilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathMeta = const VerificationMeta(
    'imagePath',
  );
  @override
  late final GeneratedColumn<String> imagePath = GeneratedColumn<String>(
    'image_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tileTypeMeta = const VerificationMeta(
    'tileType',
  );
  @override
  late final GeneratedColumn<String> tileType = GeneratedColumn<String>(
    'tile_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isUnlockedMeta = const VerificationMeta(
    'isUnlocked',
  );
  @override
  late final GeneratedColumn<bool> isUnlocked = GeneratedColumn<bool>(
    'is_unlocked',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_unlocked" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _unlockRequirementMeta = const VerificationMeta(
    'unlockRequirement',
  );
  @override
  late final GeneratedColumn<int> unlockRequirement = GeneratedColumn<int>(
    'unlock_requirement',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unlockCategoryMeta = const VerificationMeta(
    'unlockCategory',
  );
  @override
  late final GeneratedColumn<String> unlockCategory = GeneratedColumn<String>(
    'unlock_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionXMeta = const VerificationMeta(
    'positionX',
  );
  @override
  late final GeneratedColumn<int> positionX = GeneratedColumn<int>(
    'position_x',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _positionYMeta = const VerificationMeta(
    'positionY',
  );
  @override
  late final GeneratedColumn<int> positionY = GeneratedColumn<int>(
    'position_y',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _customPropertiesMeta = const VerificationMeta(
    'customProperties',
  );
  @override
  late final GeneratedColumn<String> customProperties = GeneratedColumn<String>(
    'custom_properties',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    name,
    description,
    imagePath,
    tileType,
    isUnlocked,
    unlockRequirement,
    unlockCategory,
    positionX,
    positionY,
    unlockedAt,
    customProperties,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'world_tiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorldTile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('image_path')) {
      context.handle(
        _imagePathMeta,
        imagePath.isAcceptableOrUnknown(data['image_path']!, _imagePathMeta),
      );
    }
    if (data.containsKey('tile_type')) {
      context.handle(
        _tileTypeMeta,
        tileType.isAcceptableOrUnknown(data['tile_type']!, _tileTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_tileTypeMeta);
    }
    if (data.containsKey('is_unlocked')) {
      context.handle(
        _isUnlockedMeta,
        isUnlocked.isAcceptableOrUnknown(data['is_unlocked']!, _isUnlockedMeta),
      );
    }
    if (data.containsKey('unlock_requirement')) {
      context.handle(
        _unlockRequirementMeta,
        unlockRequirement.isAcceptableOrUnknown(
          data['unlock_requirement']!,
          _unlockRequirementMeta,
        ),
      );
    }
    if (data.containsKey('unlock_category')) {
      context.handle(
        _unlockCategoryMeta,
        unlockCategory.isAcceptableOrUnknown(
          data['unlock_category']!,
          _unlockCategoryMeta,
        ),
      );
    }
    if (data.containsKey('position_x')) {
      context.handle(
        _positionXMeta,
        positionX.isAcceptableOrUnknown(data['position_x']!, _positionXMeta),
      );
    }
    if (data.containsKey('position_y')) {
      context.handle(
        _positionYMeta,
        positionY.isAcceptableOrUnknown(data['position_y']!, _positionYMeta),
      );
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    }
    if (data.containsKey('custom_properties')) {
      context.handle(
        _customPropertiesMeta,
        customProperties.isAcceptableOrUnknown(
          data['custom_properties']!,
          _customPropertiesMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorldTile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorldTile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      imagePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_path'],
      ),
      tileType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tile_type'],
      )!,
      isUnlocked: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_unlocked'],
      )!,
      unlockRequirement: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}unlock_requirement'],
      )!,
      unlockCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unlock_category'],
      ),
      positionX: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_x'],
      )!,
      positionY: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position_y'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      ),
      customProperties: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_properties'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $WorldTilesTable createAlias(String alias) {
    return $WorldTilesTable(attachedDatabase, alias);
  }
}

class WorldTile extends DataClass implements Insertable<WorldTile> {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? imagePath;
  final String tileType;
  final bool isUnlocked;
  final int unlockRequirement;
  final String? unlockCategory;
  final int positionX;
  final int positionY;
  final DateTime? unlockedAt;
  final String? customProperties;
  final DateTime createdAt;
  final DateTime updatedAt;
  const WorldTile({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.imagePath,
    required this.tileType,
    required this.isUnlocked,
    required this.unlockRequirement,
    this.unlockCategory,
    required this.positionX,
    required this.positionY,
    this.unlockedAt,
    this.customProperties,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || imagePath != null) {
      map['image_path'] = Variable<String>(imagePath);
    }
    map['tile_type'] = Variable<String>(tileType);
    map['is_unlocked'] = Variable<bool>(isUnlocked);
    map['unlock_requirement'] = Variable<int>(unlockRequirement);
    if (!nullToAbsent || unlockCategory != null) {
      map['unlock_category'] = Variable<String>(unlockCategory);
    }
    map['position_x'] = Variable<int>(positionX);
    map['position_y'] = Variable<int>(positionY);
    if (!nullToAbsent || unlockedAt != null) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    }
    if (!nullToAbsent || customProperties != null) {
      map['custom_properties'] = Variable<String>(customProperties);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  WorldTilesCompanion toCompanion(bool nullToAbsent) {
    return WorldTilesCompanion(
      id: Value(id),
      userId: Value(userId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      imagePath: imagePath == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePath),
      tileType: Value(tileType),
      isUnlocked: Value(isUnlocked),
      unlockRequirement: Value(unlockRequirement),
      unlockCategory: unlockCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockCategory),
      positionX: Value(positionX),
      positionY: Value(positionY),
      unlockedAt: unlockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(unlockedAt),
      customProperties: customProperties == null && nullToAbsent
          ? const Value.absent()
          : Value(customProperties),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory WorldTile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorldTile(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      imagePath: serializer.fromJson<String?>(json['imagePath']),
      tileType: serializer.fromJson<String>(json['tileType']),
      isUnlocked: serializer.fromJson<bool>(json['isUnlocked']),
      unlockRequirement: serializer.fromJson<int>(json['unlockRequirement']),
      unlockCategory: serializer.fromJson<String?>(json['unlockCategory']),
      positionX: serializer.fromJson<int>(json['positionX']),
      positionY: serializer.fromJson<int>(json['positionY']),
      unlockedAt: serializer.fromJson<DateTime?>(json['unlockedAt']),
      customProperties: serializer.fromJson<String?>(json['customProperties']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'imagePath': serializer.toJson<String?>(imagePath),
      'tileType': serializer.toJson<String>(tileType),
      'isUnlocked': serializer.toJson<bool>(isUnlocked),
      'unlockRequirement': serializer.toJson<int>(unlockRequirement),
      'unlockCategory': serializer.toJson<String?>(unlockCategory),
      'positionX': serializer.toJson<int>(positionX),
      'positionY': serializer.toJson<int>(positionY),
      'unlockedAt': serializer.toJson<DateTime?>(unlockedAt),
      'customProperties': serializer.toJson<String?>(customProperties),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  WorldTile copyWith({
    String? id,
    String? userId,
    String? name,
    Value<String?> description = const Value.absent(),
    Value<String?> imagePath = const Value.absent(),
    String? tileType,
    bool? isUnlocked,
    int? unlockRequirement,
    Value<String?> unlockCategory = const Value.absent(),
    int? positionX,
    int? positionY,
    Value<DateTime?> unlockedAt = const Value.absent(),
    Value<String?> customProperties = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => WorldTile(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    imagePath: imagePath.present ? imagePath.value : this.imagePath,
    tileType: tileType ?? this.tileType,
    isUnlocked: isUnlocked ?? this.isUnlocked,
    unlockRequirement: unlockRequirement ?? this.unlockRequirement,
    unlockCategory: unlockCategory.present
        ? unlockCategory.value
        : this.unlockCategory,
    positionX: positionX ?? this.positionX,
    positionY: positionY ?? this.positionY,
    unlockedAt: unlockedAt.present ? unlockedAt.value : this.unlockedAt,
    customProperties: customProperties.present
        ? customProperties.value
        : this.customProperties,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  WorldTile copyWithCompanion(WorldTilesCompanion data) {
    return WorldTile(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      imagePath: data.imagePath.present ? data.imagePath.value : this.imagePath,
      tileType: data.tileType.present ? data.tileType.value : this.tileType,
      isUnlocked: data.isUnlocked.present
          ? data.isUnlocked.value
          : this.isUnlocked,
      unlockRequirement: data.unlockRequirement.present
          ? data.unlockRequirement.value
          : this.unlockRequirement,
      unlockCategory: data.unlockCategory.present
          ? data.unlockCategory.value
          : this.unlockCategory,
      positionX: data.positionX.present ? data.positionX.value : this.positionX,
      positionY: data.positionY.present ? data.positionY.value : this.positionY,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
      customProperties: data.customProperties.present
          ? data.customProperties.value
          : this.customProperties,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorldTile(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('imagePath: $imagePath, ')
          ..write('tileType: $tileType, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('unlockRequirement: $unlockRequirement, ')
          ..write('unlockCategory: $unlockCategory, ')
          ..write('positionX: $positionX, ')
          ..write('positionY: $positionY, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('customProperties: $customProperties, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    name,
    description,
    imagePath,
    tileType,
    isUnlocked,
    unlockRequirement,
    unlockCategory,
    positionX,
    positionY,
    unlockedAt,
    customProperties,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorldTile &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.name == this.name &&
          other.description == this.description &&
          other.imagePath == this.imagePath &&
          other.tileType == this.tileType &&
          other.isUnlocked == this.isUnlocked &&
          other.unlockRequirement == this.unlockRequirement &&
          other.unlockCategory == this.unlockCategory &&
          other.positionX == this.positionX &&
          other.positionY == this.positionY &&
          other.unlockedAt == this.unlockedAt &&
          other.customProperties == this.customProperties &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class WorldTilesCompanion extends UpdateCompanion<WorldTile> {
  final Value<String> id;
  final Value<String> userId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String?> imagePath;
  final Value<String> tileType;
  final Value<bool> isUnlocked;
  final Value<int> unlockRequirement;
  final Value<String?> unlockCategory;
  final Value<int> positionX;
  final Value<int> positionY;
  final Value<DateTime?> unlockedAt;
  final Value<String?> customProperties;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const WorldTilesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.imagePath = const Value.absent(),
    this.tileType = const Value.absent(),
    this.isUnlocked = const Value.absent(),
    this.unlockRequirement = const Value.absent(),
    this.unlockCategory = const Value.absent(),
    this.positionX = const Value.absent(),
    this.positionY = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.customProperties = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorldTilesCompanion.insert({
    required String id,
    required String userId,
    required String name,
    this.description = const Value.absent(),
    this.imagePath = const Value.absent(),
    required String tileType,
    this.isUnlocked = const Value.absent(),
    this.unlockRequirement = const Value.absent(),
    this.unlockCategory = const Value.absent(),
    this.positionX = const Value.absent(),
    this.positionY = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.customProperties = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       name = Value(name),
       tileType = Value(tileType),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorldTile> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? imagePath,
    Expression<String>? tileType,
    Expression<bool>? isUnlocked,
    Expression<int>? unlockRequirement,
    Expression<String>? unlockCategory,
    Expression<int>? positionX,
    Expression<int>? positionY,
    Expression<DateTime>? unlockedAt,
    Expression<String>? customProperties,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (imagePath != null) 'image_path': imagePath,
      if (tileType != null) 'tile_type': tileType,
      if (isUnlocked != null) 'is_unlocked': isUnlocked,
      if (unlockRequirement != null) 'unlock_requirement': unlockRequirement,
      if (unlockCategory != null) 'unlock_category': unlockCategory,
      if (positionX != null) 'position_x': positionX,
      if (positionY != null) 'position_y': positionY,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (customProperties != null) 'custom_properties': customProperties,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorldTilesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<String>? name,
    Value<String?>? description,
    Value<String?>? imagePath,
    Value<String>? tileType,
    Value<bool>? isUnlocked,
    Value<int>? unlockRequirement,
    Value<String?>? unlockCategory,
    Value<int>? positionX,
    Value<int>? positionY,
    Value<DateTime?>? unlockedAt,
    Value<String?>? customProperties,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return WorldTilesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      imagePath: imagePath ?? this.imagePath,
      tileType: tileType ?? this.tileType,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockRequirement: unlockRequirement ?? this.unlockRequirement,
      unlockCategory: unlockCategory ?? this.unlockCategory,
      positionX: positionX ?? this.positionX,
      positionY: positionY ?? this.positionY,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      customProperties: customProperties ?? this.customProperties,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (imagePath.present) {
      map['image_path'] = Variable<String>(imagePath.value);
    }
    if (tileType.present) {
      map['tile_type'] = Variable<String>(tileType.value);
    }
    if (isUnlocked.present) {
      map['is_unlocked'] = Variable<bool>(isUnlocked.value);
    }
    if (unlockRequirement.present) {
      map['unlock_requirement'] = Variable<int>(unlockRequirement.value);
    }
    if (unlockCategory.present) {
      map['unlock_category'] = Variable<String>(unlockCategory.value);
    }
    if (positionX.present) {
      map['position_x'] = Variable<int>(positionX.value);
    }
    if (positionY.present) {
      map['position_y'] = Variable<int>(positionY.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (customProperties.present) {
      map['custom_properties'] = Variable<String>(customProperties.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorldTilesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('imagePath: $imagePath, ')
          ..write('tileType: $tileType, ')
          ..write('isUnlocked: $isUnlocked, ')
          ..write('unlockRequirement: $unlockRequirement, ')
          ..write('unlockCategory: $unlockCategory, ')
          ..write('positionX: $positionX, ')
          ..write('positionY: $positionY, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('customProperties: $customProperties, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgressEntriesTable extends ProgressEntries
    with TableInfo<$ProgressEntriesTable, ProgressEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgressEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<DateTime> date = GeneratedColumn<DateTime>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _xpGainedMeta = const VerificationMeta(
    'xpGained',
  );
  @override
  late final GeneratedColumn<int> xpGained = GeneratedColumn<int>(
    'xp_gained',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _tasksCompletedMeta = const VerificationMeta(
    'tasksCompleted',
  );
  @override
  late final GeneratedColumn<int> tasksCompleted = GeneratedColumn<int>(
    'tasks_completed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryBreakdownMeta = const VerificationMeta(
    'categoryBreakdown',
  );
  @override
  late final GeneratedColumn<String> categoryBreakdown =
      GeneratedColumn<String>(
        'category_breakdown',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _taskTypeBreakdownMeta = const VerificationMeta(
    'taskTypeBreakdown',
  );
  @override
  late final GeneratedColumn<String> taskTypeBreakdown =
      GeneratedColumn<String>(
        'task_type_breakdown',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _streakCountMeta = const VerificationMeta(
    'streakCount',
  );
  @override
  late final GeneratedColumn<int> streakCount = GeneratedColumn<int>(
    'streak_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _levelAtTimeMeta = const VerificationMeta(
    'levelAtTime',
  );
  @override
  late final GeneratedColumn<int> levelAtTime = GeneratedColumn<int>(
    'level_at_time',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _additionalMetricsMeta = const VerificationMeta(
    'additionalMetrics',
  );
  @override
  late final GeneratedColumn<String> additionalMetrics =
      GeneratedColumn<String>(
        'additional_metrics',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    userId,
    date,
    xpGained,
    tasksCompleted,
    category,
    categoryBreakdown,
    taskTypeBreakdown,
    streakCount,
    levelAtTime,
    additionalMetrics,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'progress_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProgressEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('xp_gained')) {
      context.handle(
        _xpGainedMeta,
        xpGained.isAcceptableOrUnknown(data['xp_gained']!, _xpGainedMeta),
      );
    }
    if (data.containsKey('tasks_completed')) {
      context.handle(
        _tasksCompletedMeta,
        tasksCompleted.isAcceptableOrUnknown(
          data['tasks_completed']!,
          _tasksCompletedMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('category_breakdown')) {
      context.handle(
        _categoryBreakdownMeta,
        categoryBreakdown.isAcceptableOrUnknown(
          data['category_breakdown']!,
          _categoryBreakdownMeta,
        ),
      );
    }
    if (data.containsKey('task_type_breakdown')) {
      context.handle(
        _taskTypeBreakdownMeta,
        taskTypeBreakdown.isAcceptableOrUnknown(
          data['task_type_breakdown']!,
          _taskTypeBreakdownMeta,
        ),
      );
    }
    if (data.containsKey('streak_count')) {
      context.handle(
        _streakCountMeta,
        streakCount.isAcceptableOrUnknown(
          data['streak_count']!,
          _streakCountMeta,
        ),
      );
    }
    if (data.containsKey('level_at_time')) {
      context.handle(
        _levelAtTimeMeta,
        levelAtTime.isAcceptableOrUnknown(
          data['level_at_time']!,
          _levelAtTimeMeta,
        ),
      );
    }
    if (data.containsKey('additional_metrics')) {
      context.handle(
        _additionalMetricsMeta,
        additionalMetrics.isAcceptableOrUnknown(
          data['additional_metrics']!,
          _additionalMetricsMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProgressEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProgressEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}date'],
      )!,
      xpGained: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}xp_gained'],
      )!,
      tasksCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tasks_completed'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      ),
      categoryBreakdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category_breakdown'],
      ),
      taskTypeBreakdown: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_type_breakdown'],
      ),
      streakCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}streak_count'],
      )!,
      levelAtTime: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}level_at_time'],
      )!,
      additionalMetrics: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}additional_metrics'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ProgressEntriesTable createAlias(String alias) {
    return $ProgressEntriesTable(attachedDatabase, alias);
  }
}

class ProgressEntry extends DataClass implements Insertable<ProgressEntry> {
  final String id;
  final String userId;
  final DateTime date;
  final int xpGained;
  final int tasksCompleted;
  final String? category;
  final String? categoryBreakdown;
  final String? taskTypeBreakdown;
  final int streakCount;
  final int levelAtTime;
  final String? additionalMetrics;
  final DateTime createdAt;
  final DateTime updatedAt;
  const ProgressEntry({
    required this.id,
    required this.userId,
    required this.date,
    required this.xpGained,
    required this.tasksCompleted,
    this.category,
    this.categoryBreakdown,
    this.taskTypeBreakdown,
    required this.streakCount,
    required this.levelAtTime,
    this.additionalMetrics,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['user_id'] = Variable<String>(userId);
    map['date'] = Variable<DateTime>(date);
    map['xp_gained'] = Variable<int>(xpGained);
    map['tasks_completed'] = Variable<int>(tasksCompleted);
    if (!nullToAbsent || category != null) {
      map['category'] = Variable<String>(category);
    }
    if (!nullToAbsent || categoryBreakdown != null) {
      map['category_breakdown'] = Variable<String>(categoryBreakdown);
    }
    if (!nullToAbsent || taskTypeBreakdown != null) {
      map['task_type_breakdown'] = Variable<String>(taskTypeBreakdown);
    }
    map['streak_count'] = Variable<int>(streakCount);
    map['level_at_time'] = Variable<int>(levelAtTime);
    if (!nullToAbsent || additionalMetrics != null) {
      map['additional_metrics'] = Variable<String>(additionalMetrics);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ProgressEntriesCompanion toCompanion(bool nullToAbsent) {
    return ProgressEntriesCompanion(
      id: Value(id),
      userId: Value(userId),
      date: Value(date),
      xpGained: Value(xpGained),
      tasksCompleted: Value(tasksCompleted),
      category: category == null && nullToAbsent
          ? const Value.absent()
          : Value(category),
      categoryBreakdown: categoryBreakdown == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryBreakdown),
      taskTypeBreakdown: taskTypeBreakdown == null && nullToAbsent
          ? const Value.absent()
          : Value(taskTypeBreakdown),
      streakCount: Value(streakCount),
      levelAtTime: Value(levelAtTime),
      additionalMetrics: additionalMetrics == null && nullToAbsent
          ? const Value.absent()
          : Value(additionalMetrics),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ProgressEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProgressEntry(
      id: serializer.fromJson<String>(json['id']),
      userId: serializer.fromJson<String>(json['userId']),
      date: serializer.fromJson<DateTime>(json['date']),
      xpGained: serializer.fromJson<int>(json['xpGained']),
      tasksCompleted: serializer.fromJson<int>(json['tasksCompleted']),
      category: serializer.fromJson<String?>(json['category']),
      categoryBreakdown: serializer.fromJson<String?>(
        json['categoryBreakdown'],
      ),
      taskTypeBreakdown: serializer.fromJson<String?>(
        json['taskTypeBreakdown'],
      ),
      streakCount: serializer.fromJson<int>(json['streakCount']),
      levelAtTime: serializer.fromJson<int>(json['levelAtTime']),
      additionalMetrics: serializer.fromJson<String?>(
        json['additionalMetrics'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'userId': serializer.toJson<String>(userId),
      'date': serializer.toJson<DateTime>(date),
      'xpGained': serializer.toJson<int>(xpGained),
      'tasksCompleted': serializer.toJson<int>(tasksCompleted),
      'category': serializer.toJson<String?>(category),
      'categoryBreakdown': serializer.toJson<String?>(categoryBreakdown),
      'taskTypeBreakdown': serializer.toJson<String?>(taskTypeBreakdown),
      'streakCount': serializer.toJson<int>(streakCount),
      'levelAtTime': serializer.toJson<int>(levelAtTime),
      'additionalMetrics': serializer.toJson<String?>(additionalMetrics),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ProgressEntry copyWith({
    String? id,
    String? userId,
    DateTime? date,
    int? xpGained,
    int? tasksCompleted,
    Value<String?> category = const Value.absent(),
    Value<String?> categoryBreakdown = const Value.absent(),
    Value<String?> taskTypeBreakdown = const Value.absent(),
    int? streakCount,
    int? levelAtTime,
    Value<String?> additionalMetrics = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => ProgressEntry(
    id: id ?? this.id,
    userId: userId ?? this.userId,
    date: date ?? this.date,
    xpGained: xpGained ?? this.xpGained,
    tasksCompleted: tasksCompleted ?? this.tasksCompleted,
    category: category.present ? category.value : this.category,
    categoryBreakdown: categoryBreakdown.present
        ? categoryBreakdown.value
        : this.categoryBreakdown,
    taskTypeBreakdown: taskTypeBreakdown.present
        ? taskTypeBreakdown.value
        : this.taskTypeBreakdown,
    streakCount: streakCount ?? this.streakCount,
    levelAtTime: levelAtTime ?? this.levelAtTime,
    additionalMetrics: additionalMetrics.present
        ? additionalMetrics.value
        : this.additionalMetrics,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ProgressEntry copyWithCompanion(ProgressEntriesCompanion data) {
    return ProgressEntry(
      id: data.id.present ? data.id.value : this.id,
      userId: data.userId.present ? data.userId.value : this.userId,
      date: data.date.present ? data.date.value : this.date,
      xpGained: data.xpGained.present ? data.xpGained.value : this.xpGained,
      tasksCompleted: data.tasksCompleted.present
          ? data.tasksCompleted.value
          : this.tasksCompleted,
      category: data.category.present ? data.category.value : this.category,
      categoryBreakdown: data.categoryBreakdown.present
          ? data.categoryBreakdown.value
          : this.categoryBreakdown,
      taskTypeBreakdown: data.taskTypeBreakdown.present
          ? data.taskTypeBreakdown.value
          : this.taskTypeBreakdown,
      streakCount: data.streakCount.present
          ? data.streakCount.value
          : this.streakCount,
      levelAtTime: data.levelAtTime.present
          ? data.levelAtTime.value
          : this.levelAtTime,
      additionalMetrics: data.additionalMetrics.present
          ? data.additionalMetrics.value
          : this.additionalMetrics,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProgressEntry(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('date: $date, ')
          ..write('xpGained: $xpGained, ')
          ..write('tasksCompleted: $tasksCompleted, ')
          ..write('category: $category, ')
          ..write('categoryBreakdown: $categoryBreakdown, ')
          ..write('taskTypeBreakdown: $taskTypeBreakdown, ')
          ..write('streakCount: $streakCount, ')
          ..write('levelAtTime: $levelAtTime, ')
          ..write('additionalMetrics: $additionalMetrics, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    userId,
    date,
    xpGained,
    tasksCompleted,
    category,
    categoryBreakdown,
    taskTypeBreakdown,
    streakCount,
    levelAtTime,
    additionalMetrics,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProgressEntry &&
          other.id == this.id &&
          other.userId == this.userId &&
          other.date == this.date &&
          other.xpGained == this.xpGained &&
          other.tasksCompleted == this.tasksCompleted &&
          other.category == this.category &&
          other.categoryBreakdown == this.categoryBreakdown &&
          other.taskTypeBreakdown == this.taskTypeBreakdown &&
          other.streakCount == this.streakCount &&
          other.levelAtTime == this.levelAtTime &&
          other.additionalMetrics == this.additionalMetrics &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ProgressEntriesCompanion extends UpdateCompanion<ProgressEntry> {
  final Value<String> id;
  final Value<String> userId;
  final Value<DateTime> date;
  final Value<int> xpGained;
  final Value<int> tasksCompleted;
  final Value<String?> category;
  final Value<String?> categoryBreakdown;
  final Value<String?> taskTypeBreakdown;
  final Value<int> streakCount;
  final Value<int> levelAtTime;
  final Value<String?> additionalMetrics;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ProgressEntriesCompanion({
    this.id = const Value.absent(),
    this.userId = const Value.absent(),
    this.date = const Value.absent(),
    this.xpGained = const Value.absent(),
    this.tasksCompleted = const Value.absent(),
    this.category = const Value.absent(),
    this.categoryBreakdown = const Value.absent(),
    this.taskTypeBreakdown = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.levelAtTime = const Value.absent(),
    this.additionalMetrics = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgressEntriesCompanion.insert({
    required String id,
    required String userId,
    required DateTime date,
    this.xpGained = const Value.absent(),
    this.tasksCompleted = const Value.absent(),
    this.category = const Value.absent(),
    this.categoryBreakdown = const Value.absent(),
    this.taskTypeBreakdown = const Value.absent(),
    this.streakCount = const Value.absent(),
    this.levelAtTime = const Value.absent(),
    this.additionalMetrics = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       userId = Value(userId),
       date = Value(date),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProgressEntry> custom({
    Expression<String>? id,
    Expression<String>? userId,
    Expression<DateTime>? date,
    Expression<int>? xpGained,
    Expression<int>? tasksCompleted,
    Expression<String>? category,
    Expression<String>? categoryBreakdown,
    Expression<String>? taskTypeBreakdown,
    Expression<int>? streakCount,
    Expression<int>? levelAtTime,
    Expression<String>? additionalMetrics,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (date != null) 'date': date,
      if (xpGained != null) 'xp_gained': xpGained,
      if (tasksCompleted != null) 'tasks_completed': tasksCompleted,
      if (category != null) 'category': category,
      if (categoryBreakdown != null) 'category_breakdown': categoryBreakdown,
      if (taskTypeBreakdown != null) 'task_type_breakdown': taskTypeBreakdown,
      if (streakCount != null) 'streak_count': streakCount,
      if (levelAtTime != null) 'level_at_time': levelAtTime,
      if (additionalMetrics != null) 'additional_metrics': additionalMetrics,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgressEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? userId,
    Value<DateTime>? date,
    Value<int>? xpGained,
    Value<int>? tasksCompleted,
    Value<String?>? category,
    Value<String?>? categoryBreakdown,
    Value<String?>? taskTypeBreakdown,
    Value<int>? streakCount,
    Value<int>? levelAtTime,
    Value<String?>? additionalMetrics,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ProgressEntriesCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      date: date ?? this.date,
      xpGained: xpGained ?? this.xpGained,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      category: category ?? this.category,
      categoryBreakdown: categoryBreakdown ?? this.categoryBreakdown,
      taskTypeBreakdown: taskTypeBreakdown ?? this.taskTypeBreakdown,
      streakCount: streakCount ?? this.streakCount,
      levelAtTime: levelAtTime ?? this.levelAtTime,
      additionalMetrics: additionalMetrics ?? this.additionalMetrics,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (date.present) {
      map['date'] = Variable<DateTime>(date.value);
    }
    if (xpGained.present) {
      map['xp_gained'] = Variable<int>(xpGained.value);
    }
    if (tasksCompleted.present) {
      map['tasks_completed'] = Variable<int>(tasksCompleted.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (categoryBreakdown.present) {
      map['category_breakdown'] = Variable<String>(categoryBreakdown.value);
    }
    if (taskTypeBreakdown.present) {
      map['task_type_breakdown'] = Variable<String>(taskTypeBreakdown.value);
    }
    if (streakCount.present) {
      map['streak_count'] = Variable<int>(streakCount.value);
    }
    if (levelAtTime.present) {
      map['level_at_time'] = Variable<int>(levelAtTime.value);
    }
    if (additionalMetrics.present) {
      map['additional_metrics'] = Variable<String>(additionalMetrics.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgressEntriesCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('date: $date, ')
          ..write('xpGained: $xpGained, ')
          ..write('tasksCompleted: $tasksCompleted, ')
          ..write('category: $category, ')
          ..write('categoryBreakdown: $categoryBreakdown, ')
          ..write('taskTypeBreakdown: $taskTypeBreakdown, ')
          ..write('streakCount: $streakCount, ')
          ..write('levelAtTime: $levelAtTime, ')
          ..write('additionalMetrics: $additionalMetrics, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOperationsTable extends SyncOperations
    with TableInfo<$SyncOperationsTable, SyncOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dataMeta = const VerificationMeta('data');
  @override
  late final GeneratedColumn<String> data = GeneratedColumn<String>(
    'data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxRetriesMeta = const VerificationMeta(
    'maxRetries',
  );
  @override
  late final GeneratedColumn<int> maxRetries = GeneratedColumn<int>(
    'max_retries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    operationType,
    entityType,
    entityId,
    data,
    timestamp,
    retryCount,
    maxRetries,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('data')) {
      context.handle(
        _dataMeta,
        this.data.isAcceptableOrUnknown(data['data']!, _dataMeta),
      );
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    } else if (isInserting) {
      context.missing(_timestampMeta);
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('max_retries')) {
      context.handle(
        _maxRetriesMeta,
        maxRetries.isAcceptableOrUnknown(data['max_retries']!, _maxRetriesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      data: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}data'],
      ),
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      maxRetries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_retries'],
      )!,
    );
  }

  @override
  $SyncOperationsTable createAlias(String alias) {
    return $SyncOperationsTable(attachedDatabase, alias);
  }
}

class SyncOperation extends DataClass implements Insertable<SyncOperation> {
  final String id;
  final String operationType;
  final String entityType;
  final String entityId;
  final String? data;
  final DateTime timestamp;
  final int retryCount;
  final int maxRetries;
  const SyncOperation({
    required this.id,
    required this.operationType,
    required this.entityType,
    required this.entityId,
    this.data,
    required this.timestamp,
    required this.retryCount,
    required this.maxRetries,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['operation_type'] = Variable<String>(operationType);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    if (!nullToAbsent || data != null) {
      map['data'] = Variable<String>(data);
    }
    map['timestamp'] = Variable<DateTime>(timestamp);
    map['retry_count'] = Variable<int>(retryCount);
    map['max_retries'] = Variable<int>(maxRetries);
    return map;
  }

  SyncOperationsCompanion toCompanion(bool nullToAbsent) {
    return SyncOperationsCompanion(
      id: Value(id),
      operationType: Value(operationType),
      entityType: Value(entityType),
      entityId: Value(entityId),
      data: data == null && nullToAbsent ? const Value.absent() : Value(data),
      timestamp: Value(timestamp),
      retryCount: Value(retryCount),
      maxRetries: Value(maxRetries),
    );
  }

  factory SyncOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOperation(
      id: serializer.fromJson<String>(json['id']),
      operationType: serializer.fromJson<String>(json['operationType']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      data: serializer.fromJson<String?>(json['data']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      maxRetries: serializer.fromJson<int>(json['maxRetries']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'operationType': serializer.toJson<String>(operationType),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'data': serializer.toJson<String?>(data),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'retryCount': serializer.toJson<int>(retryCount),
      'maxRetries': serializer.toJson<int>(maxRetries),
    };
  }

  SyncOperation copyWith({
    String? id,
    String? operationType,
    String? entityType,
    String? entityId,
    Value<String?> data = const Value.absent(),
    DateTime? timestamp,
    int? retryCount,
    int? maxRetries,
  }) => SyncOperation(
    id: id ?? this.id,
    operationType: operationType ?? this.operationType,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    data: data.present ? data.value : this.data,
    timestamp: timestamp ?? this.timestamp,
    retryCount: retryCount ?? this.retryCount,
    maxRetries: maxRetries ?? this.maxRetries,
  );
  SyncOperation copyWithCompanion(SyncOperationsCompanion data) {
    return SyncOperation(
      id: data.id.present ? data.id.value : this.id,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      data: data.data.present ? data.data.value : this.data,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      maxRetries: data.maxRetries.present
          ? data.maxRetries.value
          : this.maxRetries,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperation(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('data: $data, ')
          ..write('timestamp: $timestamp, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    operationType,
    entityType,
    entityId,
    data,
    timestamp,
    retryCount,
    maxRetries,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOperation &&
          other.id == this.id &&
          other.operationType == this.operationType &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.data == this.data &&
          other.timestamp == this.timestamp &&
          other.retryCount == this.retryCount &&
          other.maxRetries == this.maxRetries);
}

class SyncOperationsCompanion extends UpdateCompanion<SyncOperation> {
  final Value<String> id;
  final Value<String> operationType;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String?> data;
  final Value<DateTime> timestamp;
  final Value<int> retryCount;
  final Value<int> maxRetries;
  final Value<int> rowid;
  const SyncOperationsCompanion({
    this.id = const Value.absent(),
    this.operationType = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.data = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOperationsCompanion.insert({
    required String id,
    required String operationType,
    required String entityType,
    required String entityId,
    this.data = const Value.absent(),
    required DateTime timestamp,
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       operationType = Value(operationType),
       entityType = Value(entityType),
       entityId = Value(entityId),
       timestamp = Value(timestamp);
  static Insertable<SyncOperation> custom({
    Expression<String>? id,
    Expression<String>? operationType,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? data,
    Expression<DateTime>? timestamp,
    Expression<int>? retryCount,
    Expression<int>? maxRetries,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (operationType != null) 'operation_type': operationType,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (data != null) 'data': data,
      if (timestamp != null) 'timestamp': timestamp,
      if (retryCount != null) 'retry_count': retryCount,
      if (maxRetries != null) 'max_retries': maxRetries,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOperationsCompanion copyWith({
    Value<String>? id,
    Value<String>? operationType,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String?>? data,
    Value<DateTime>? timestamp,
    Value<int>? retryCount,
    Value<int>? maxRetries,
    Value<int>? rowid,
  }) {
    return SyncOperationsCompanion(
      id: id ?? this.id,
      operationType: operationType ?? this.operationType,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (data.present) {
      map['data'] = Variable<String>(data.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (maxRetries.present) {
      map['max_retries'] = Variable<int>(maxRetries.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationsCompanion(')
          ..write('id: $id, ')
          ..write('operationType: $operationType, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('data: $data, ')
          ..write('timestamp: $timestamp, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AtlasDatabase extends GeneratedDatabase {
  _$AtlasDatabase(QueryExecutor e) : super(e);
  $AtlasDatabaseManager get managers => $AtlasDatabaseManager(this);
  late final $UsersTable users = $UsersTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $AvatarsTable avatars = $AvatarsTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $WorldTilesTable worldTiles = $WorldTilesTable(this);
  late final $ProgressEntriesTable progressEntries = $ProgressEntriesTable(
    this,
  );
  late final $SyncOperationsTable syncOperations = $SyncOperationsTable(this);
  late final TaskDao taskDao = TaskDao(this as AtlasDatabase);
  late final HabitDao habitDao = HabitDao(this as AtlasDatabase);
  late final GoalDao goalDao = GoalDao(this as AtlasDatabase);
  late final AvatarDao avatarDao = AvatarDao(this as AtlasDatabase);
  late final AchievementDao achievementDao = AchievementDao(
    this as AtlasDatabase,
  );
  late final WorldDao worldDao = WorldDao(this as AtlasDatabase);
  late final ProgressDao progressDao = ProgressDao(this as AtlasDatabase);
  late final SyncDao syncDao = SyncDao(this as AtlasDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    users,
    tasks,
    habits,
    goals,
    avatars,
    achievements,
    worldTiles,
    progressEntries,
    syncOperations,
  ];
}

typedef $$UsersTableCreateCompanionBuilder =
    UsersCompanion Function({
      required String id,
      required String email,
      required String fullName,
      Value<String?> photoUrl,
      Value<int> level,
      Value<int> totalXp,
      Value<int> currentStreak,
      Value<int> longestStreak,
      Value<bool> isEmailVerified,
      Value<String> authProvider,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> lastActiveDate,
      Value<int> rowid,
    });
typedef $$UsersTableUpdateCompanionBuilder =
    UsersCompanion Function({
      Value<String> id,
      Value<String> email,
      Value<String> fullName,
      Value<String?> photoUrl,
      Value<int> level,
      Value<int> totalXp,
      Value<int> currentStreak,
      Value<int> longestStreak,
      Value<bool> isEmailVerified,
      Value<String> authProvider,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> lastActiveDate,
      Value<int> rowid,
    });

class $$UsersTableFilterComposer
    extends Composer<_$AtlasDatabase, $UsersTable> {
  $$UsersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEmailVerified => $composableBuilder(
    column: $table.isEmailVerified,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get authProvider => $composableBuilder(
    column: $table.authProvider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastActiveDate => $composableBuilder(
    column: $table.lastActiveDate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$UsersTableOrderingComposer
    extends Composer<_$AtlasDatabase, $UsersTable> {
  $$UsersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fullName => $composableBuilder(
    column: $table.fullName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get photoUrl => $composableBuilder(
    column: $table.photoUrl,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalXp => $composableBuilder(
    column: $table.totalXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEmailVerified => $composableBuilder(
    column: $table.isEmailVerified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get authProvider => $composableBuilder(
    column: $table.authProvider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastActiveDate => $composableBuilder(
    column: $table.lastActiveDate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$UsersTableAnnotationComposer
    extends Composer<_$AtlasDatabase, $UsersTable> {
  $$UsersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  GeneratedColumn<String> get fullName =>
      $composableBuilder(column: $table.fullName, builder: (column) => column);

  GeneratedColumn<String> get photoUrl =>
      $composableBuilder(column: $table.photoUrl, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get totalXp =>
      $composableBuilder(column: $table.totalXp, builder: (column) => column);

  GeneratedColumn<int> get currentStreak => $composableBuilder(
    column: $table.currentStreak,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEmailVerified => $composableBuilder(
    column: $table.isEmailVerified,
    builder: (column) => column,
  );

  GeneratedColumn<String> get authProvider => $composableBuilder(
    column: $table.authProvider,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get lastActiveDate => $composableBuilder(
    column: $table.lastActiveDate,
    builder: (column) => column,
  );
}

class $$UsersTableTableManager
    extends
        RootTableManager<
          _$AtlasDatabase,
          $UsersTable,
          User,
          $$UsersTableFilterComposer,
          $$UsersTableOrderingComposer,
          $$UsersTableAnnotationComposer,
          $$UsersTableCreateCompanionBuilder,
          $$UsersTableUpdateCompanionBuilder,
          (User, BaseReferences<_$AtlasDatabase, $UsersTable, User>),
          User,
          PrefetchHooks Function()
        > {
  $$UsersTableTableManager(_$AtlasDatabase db, $UsersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$UsersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$UsersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$UsersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> email = const Value.absent(),
                Value<String> fullName = const Value.absent(),
                Value<String?> photoUrl = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<bool> isEmailVerified = const Value.absent(),
                Value<String> authProvider = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> lastActiveDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion(
                id: id,
                email: email,
                fullName: fullName,
                photoUrl: photoUrl,
                level: level,
                totalXp: totalXp,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                isEmailVerified: isEmailVerified,
                authProvider: authProvider,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastActiveDate: lastActiveDate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String email,
                required String fullName,
                Value<String?> photoUrl = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> totalXp = const Value.absent(),
                Value<int> currentStreak = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<bool> isEmailVerified = const Value.absent(),
                Value<String> authProvider = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> lastActiveDate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => UsersCompanion.insert(
                id: id,
                email: email,
                fullName: fullName,
                photoUrl: photoUrl,
                level: level,
                totalXp: totalXp,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
                isEmailVerified: isEmailVerified,
                authProvider: authProvider,
                createdAt: createdAt,
                updatedAt: updatedAt,
                lastActiveDate: lastActiveDate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$UsersTableProcessedTableManager =
    ProcessedTableManager<
      _$AtlasDatabase,
      $UsersTable,
      User,
      $$UsersTableFilterComposer,
      $$UsersTableOrderingComposer,
      $$UsersTableAnnotationComposer,
      $$UsersTableCreateCompanionBuilder,
      $$UsersTableUpdateCompanionBuilder,
      (User, BaseReferences<_$AtlasDatabase, $UsersTable, User>),
      User,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String userId,
      required String title,
      Value<String?> description,
      required String type,
      required String category,
      Value<int> xpReward,
      Value<int> difficulty,
      Value<DateTime?> dueDate,
      Value<bool> isCompleted,
      Value<int> streakCount,
      Value<DateTime?> lastCompletedDate,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> title,
      Value<String?> description,
      Value<String> type,
      Value<String> category,
      Value<int> xpReward,
      Value<int> difficulty,
      Value<DateTime?> dueDate,
      Value<bool> isCompleted,
      Value<int> streakCount,
      Value<DateTime?> lastCompletedDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$TasksTableFilterComposer
    extends Composer<_$AtlasDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpReward => $composableBuilder(
    column: $table.xpReward,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$TasksTableOrderingComposer
    extends Composer<_$AtlasDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpReward => $composableBuilder(
    column: $table.xpReward,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AtlasDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<int> get xpReward =>
      $composableBuilder(column: $table.xpReward, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AtlasDatabase,
          $TasksTable,
          Task,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (Task, BaseReferences<_$AtlasDatabase, $TasksTable, Task>),
          Task,
          PrefetchHooks Function()
        > {
  $$TasksTableTableManager(_$AtlasDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<int> xpReward = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<DateTime?> lastCompletedDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                userId: userId,
                title: title,
                description: description,
                type: type,
                category: category,
                xpReward: xpReward,
                difficulty: difficulty,
                dueDate: dueDate,
                isCompleted: isCompleted,
                streakCount: streakCount,
                lastCompletedDate: lastCompletedDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String title,
                Value<String?> description = const Value.absent(),
                required String type,
                required String category,
                Value<int> xpReward = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<DateTime?> lastCompletedDate = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                description: description,
                type: type,
                category: category,
                xpReward: xpReward,
                difficulty: difficulty,
                dueDate: dueDate,
                isCompleted: isCompleted,
                streakCount: streakCount,
                lastCompletedDate: lastCompletedDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AtlasDatabase,
      $TasksTable,
      Task,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (Task, BaseReferences<_$AtlasDatabase, $TasksTable, Task>),
      Task,
      PrefetchHooks Function()
    >;
typedef $$HabitsTableCreateCompanionBuilder =
    HabitsCompanion Function({
      required String id,
      required String userId,
      required String title,
      Value<String?> description,
      required String category,
      required String frequency,
      Value<int> difficulty,
      Value<bool> isCompletedToday,
      Value<int> streakCount,
      Value<int> longestStreak,
      Value<double> completionRate,
      Value<int> totalCompletions,
      Value<String?> reminderTime,
      Value<DateTime?> lastCompletedDate,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$HabitsTableUpdateCompanionBuilder =
    HabitsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> title,
      Value<String?> description,
      Value<String> category,
      Value<String> frequency,
      Value<int> difficulty,
      Value<bool> isCompletedToday,
      Value<int> streakCount,
      Value<int> longestStreak,
      Value<double> completionRate,
      Value<int> totalCompletions,
      Value<String?> reminderTime,
      Value<DateTime?> lastCompletedDate,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$HabitsTableFilterComposer
    extends Composer<_$AtlasDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompletedToday => $composableBuilder(
    column: $table.isCompletedToday,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalCompletions => $composableBuilder(
    column: $table.totalCompletions,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AtlasDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompletedToday => $composableBuilder(
    column: $table.isCompletedToday,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalCompletions => $composableBuilder(
    column: $table.totalCompletions,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AtlasDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompletedToday => $composableBuilder(
    column: $table.isCompletedToday,
    builder: (column) => column,
  );

  GeneratedColumn<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => column,
  );

  GeneratedColumn<double> get completionRate => $composableBuilder(
    column: $table.completionRate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalCompletions => $composableBuilder(
    column: $table.totalCompletions,
    builder: (column) => column,
  );

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lastCompletedDate => $composableBuilder(
    column: $table.lastCompletedDate,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AtlasDatabase,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, BaseReferences<_$AtlasDatabase, $HabitsTable, Habit>),
          Habit,
          PrefetchHooks Function()
        > {
  $$HabitsTableTableManager(_$AtlasDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int> difficulty = const Value.absent(),
                Value<bool> isCompletedToday = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<double> completionRate = const Value.absent(),
                Value<int> totalCompletions = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<DateTime?> lastCompletedDate = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                userId: userId,
                title: title,
                description: description,
                category: category,
                frequency: frequency,
                difficulty: difficulty,
                isCompletedToday: isCompletedToday,
                streakCount: streakCount,
                longestStreak: longestStreak,
                completionRate: completionRate,
                totalCompletions: totalCompletions,
                reminderTime: reminderTime,
                lastCompletedDate: lastCompletedDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String title,
                Value<String?> description = const Value.absent(),
                required String category,
                required String frequency,
                Value<int> difficulty = const Value.absent(),
                Value<bool> isCompletedToday = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<double> completionRate = const Value.absent(),
                Value<int> totalCompletions = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<DateTime?> lastCompletedDate = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                description: description,
                category: category,
                frequency: frequency,
                difficulty: difficulty,
                isCompletedToday: isCompletedToday,
                streakCount: streakCount,
                longestStreak: longestStreak,
                completionRate: completionRate,
                totalCompletions: totalCompletions,
                reminderTime: reminderTime,
                lastCompletedDate: lastCompletedDate,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtlasDatabase,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, BaseReferences<_$AtlasDatabase, $HabitsTable, Habit>),
      Habit,
      PrefetchHooks Function()
    >;
typedef $$GoalsTableCreateCompanionBuilder =
    GoalsCompanion Function({
      required String id,
      required String userId,
      required String title,
      Value<String?> description,
      required String category,
      required String priority,
      required String status,
      Value<double> progress,
      Value<DateTime?> startDate,
      Value<DateTime?> deadline,
      Value<DateTime?> completedAt,
      Value<String?> parentGoalId,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$GoalsTableUpdateCompanionBuilder =
    GoalsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> title,
      Value<String?> description,
      Value<String> category,
      Value<String> priority,
      Value<String> status,
      Value<double> progress,
      Value<DateTime?> startDate,
      Value<DateTime?> deadline,
      Value<DateTime?> completedAt,
      Value<String?> parentGoalId,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$GoalsTableFilterComposer
    extends Composer<_$AtlasDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentGoalId => $composableBuilder(
    column: $table.parentGoalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AtlasDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deadline => $composableBuilder(
    column: $table.deadline,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentGoalId => $composableBuilder(
    column: $table.parentGoalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AtlasDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get deadline =>
      $composableBuilder(column: $table.deadline, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get parentGoalId => $composableBuilder(
    column: $table.parentGoalId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AtlasDatabase,
          $GoalsTable,
          Goal,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (Goal, BaseReferences<_$AtlasDatabase, $GoalsTable, Goal>),
          Goal,
          PrefetchHooks Function()
        > {
  $$GoalsTableTableManager(_$AtlasDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> priority = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> parentGoalId = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                userId: userId,
                title: title,
                description: description,
                category: category,
                priority: priority,
                status: status,
                progress: progress,
                startDate: startDate,
                deadline: deadline,
                completedAt: completedAt,
                parentGoalId: parentGoalId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String title,
                Value<String?> description = const Value.absent(),
                required String category,
                required String priority,
                required String status,
                Value<double> progress = const Value.absent(),
                Value<DateTime?> startDate = const Value.absent(),
                Value<DateTime?> deadline = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> parentGoalId = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                description: description,
                category: category,
                priority: priority,
                status: status,
                progress: progress,
                startDate: startDate,
                deadline: deadline,
                completedAt: completedAt,
                parentGoalId: parentGoalId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtlasDatabase,
      $GoalsTable,
      Goal,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (Goal, BaseReferences<_$AtlasDatabase, $GoalsTable, Goal>),
      Goal,
      PrefetchHooks Function()
    >;
typedef $$AvatarsTableCreateCompanionBuilder =
    AvatarsCompanion Function({
      required String id,
      required String userId,
      required String name,
      Value<int> level,
      Value<int> currentXp,
      Value<int> strength,
      Value<int> wisdom,
      Value<int> intelligence,
      Value<String?> appearanceData,
      Value<String?> unlockedItems,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AvatarsTableUpdateCompanionBuilder =
    AvatarsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<int> level,
      Value<int> currentXp,
      Value<int> strength,
      Value<int> wisdom,
      Value<int> intelligence,
      Value<String?> appearanceData,
      Value<String?> unlockedItems,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AvatarsTableFilterComposer
    extends Composer<_$AtlasDatabase, $AvatarsTable> {
  $$AvatarsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentXp => $composableBuilder(
    column: $table.currentXp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get wisdom => $composableBuilder(
    column: $table.wisdom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get intelligence => $composableBuilder(
    column: $table.intelligence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get appearanceData => $composableBuilder(
    column: $table.appearanceData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unlockedItems => $composableBuilder(
    column: $table.unlockedItems,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AvatarsTableOrderingComposer
    extends Composer<_$AtlasDatabase, $AvatarsTable> {
  $$AvatarsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentXp => $composableBuilder(
    column: $table.currentXp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get strength => $composableBuilder(
    column: $table.strength,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get wisdom => $composableBuilder(
    column: $table.wisdom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get intelligence => $composableBuilder(
    column: $table.intelligence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get appearanceData => $composableBuilder(
    column: $table.appearanceData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unlockedItems => $composableBuilder(
    column: $table.unlockedItems,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AvatarsTableAnnotationComposer
    extends Composer<_$AtlasDatabase, $AvatarsTable> {
  $$AvatarsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<int> get currentXp =>
      $composableBuilder(column: $table.currentXp, builder: (column) => column);

  GeneratedColumn<int> get strength =>
      $composableBuilder(column: $table.strength, builder: (column) => column);

  GeneratedColumn<int> get wisdom =>
      $composableBuilder(column: $table.wisdom, builder: (column) => column);

  GeneratedColumn<int> get intelligence => $composableBuilder(
    column: $table.intelligence,
    builder: (column) => column,
  );

  GeneratedColumn<String> get appearanceData => $composableBuilder(
    column: $table.appearanceData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unlockedItems => $composableBuilder(
    column: $table.unlockedItems,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AvatarsTableTableManager
    extends
        RootTableManager<
          _$AtlasDatabase,
          $AvatarsTable,
          Avatar,
          $$AvatarsTableFilterComposer,
          $$AvatarsTableOrderingComposer,
          $$AvatarsTableAnnotationComposer,
          $$AvatarsTableCreateCompanionBuilder,
          $$AvatarsTableUpdateCompanionBuilder,
          (Avatar, BaseReferences<_$AtlasDatabase, $AvatarsTable, Avatar>),
          Avatar,
          PrefetchHooks Function()
        > {
  $$AvatarsTableTableManager(_$AtlasDatabase db, $AvatarsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AvatarsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AvatarsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AvatarsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> level = const Value.absent(),
                Value<int> currentXp = const Value.absent(),
                Value<int> strength = const Value.absent(),
                Value<int> wisdom = const Value.absent(),
                Value<int> intelligence = const Value.absent(),
                Value<String?> appearanceData = const Value.absent(),
                Value<String?> unlockedItems = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AvatarsCompanion(
                id: id,
                userId: userId,
                name: name,
                level: level,
                currentXp: currentXp,
                strength: strength,
                wisdom: wisdom,
                intelligence: intelligence,
                appearanceData: appearanceData,
                unlockedItems: unlockedItems,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                Value<int> level = const Value.absent(),
                Value<int> currentXp = const Value.absent(),
                Value<int> strength = const Value.absent(),
                Value<int> wisdom = const Value.absent(),
                Value<int> intelligence = const Value.absent(),
                Value<String?> appearanceData = const Value.absent(),
                Value<String?> unlockedItems = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AvatarsCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                level: level,
                currentXp: currentXp,
                strength: strength,
                wisdom: wisdom,
                intelligence: intelligence,
                appearanceData: appearanceData,
                unlockedItems: unlockedItems,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AvatarsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtlasDatabase,
      $AvatarsTable,
      Avatar,
      $$AvatarsTableFilterComposer,
      $$AvatarsTableOrderingComposer,
      $$AvatarsTableAnnotationComposer,
      $$AvatarsTableCreateCompanionBuilder,
      $$AvatarsTableUpdateCompanionBuilder,
      (Avatar, BaseReferences<_$AtlasDatabase, $AvatarsTable, Avatar>),
      Avatar,
      PrefetchHooks Function()
    >;
typedef $$AchievementsTableCreateCompanionBuilder =
    AchievementsCompanion Function({
      required String id,
      required String userId,
      required String title,
      Value<String?> description,
      Value<String?> iconPath,
      required String achievementType,
      Value<String?> criteria,
      Value<bool> isUnlocked,
      Value<double> progress,
      Value<DateTime?> unlockedAt,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AchievementsTableUpdateCompanionBuilder =
    AchievementsCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> title,
      Value<String?> description,
      Value<String?> iconPath,
      Value<String> achievementType,
      Value<String?> criteria,
      Value<bool> isUnlocked,
      Value<double> progress,
      Value<DateTime?> unlockedAt,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AchievementsTableFilterComposer
    extends Composer<_$AtlasDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get iconPath => $composableBuilder(
    column: $table.iconPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get achievementType => $composableBuilder(
    column: $table.achievementType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criteria => $composableBuilder(
    column: $table.criteria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AtlasDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get iconPath => $composableBuilder(
    column: $table.iconPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get achievementType => $composableBuilder(
    column: $table.achievementType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criteria => $composableBuilder(
    column: $table.criteria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get progress => $composableBuilder(
    column: $table.progress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AtlasDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get iconPath =>
      $composableBuilder(column: $table.iconPath, builder: (column) => column);

  GeneratedColumn<String> get achievementType => $composableBuilder(
    column: $table.achievementType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get criteria =>
      $composableBuilder(column: $table.criteria, builder: (column) => column);

  GeneratedColumn<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => column,
  );

  GeneratedColumn<double> get progress =>
      $composableBuilder(column: $table.progress, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AchievementsTableTableManager
    extends
        RootTableManager<
          _$AtlasDatabase,
          $AchievementsTable,
          Achievement,
          $$AchievementsTableFilterComposer,
          $$AchievementsTableOrderingComposer,
          $$AchievementsTableAnnotationComposer,
          $$AchievementsTableCreateCompanionBuilder,
          $$AchievementsTableUpdateCompanionBuilder,
          (
            Achievement,
            BaseReferences<_$AtlasDatabase, $AchievementsTable, Achievement>,
          ),
          Achievement,
          PrefetchHooks Function()
        > {
  $$AchievementsTableTableManager(_$AtlasDatabase db, $AchievementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> iconPath = const Value.absent(),
                Value<String> achievementType = const Value.absent(),
                Value<String?> criteria = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion(
                id: id,
                userId: userId,
                title: title,
                description: description,
                iconPath: iconPath,
                achievementType: achievementType,
                criteria: criteria,
                isUnlocked: isUnlocked,
                progress: progress,
                unlockedAt: unlockedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String?> iconPath = const Value.absent(),
                required String achievementType,
                Value<String?> criteria = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
                Value<double> progress = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion.insert(
                id: id,
                userId: userId,
                title: title,
                description: description,
                iconPath: iconPath,
                achievementType: achievementType,
                criteria: criteria,
                isUnlocked: isUnlocked,
                progress: progress,
                unlockedAt: unlockedAt,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtlasDatabase,
      $AchievementsTable,
      Achievement,
      $$AchievementsTableFilterComposer,
      $$AchievementsTableOrderingComposer,
      $$AchievementsTableAnnotationComposer,
      $$AchievementsTableCreateCompanionBuilder,
      $$AchievementsTableUpdateCompanionBuilder,
      (
        Achievement,
        BaseReferences<_$AtlasDatabase, $AchievementsTable, Achievement>,
      ),
      Achievement,
      PrefetchHooks Function()
    >;
typedef $$WorldTilesTableCreateCompanionBuilder =
    WorldTilesCompanion Function({
      required String id,
      required String userId,
      required String name,
      Value<String?> description,
      Value<String?> imagePath,
      required String tileType,
      Value<bool> isUnlocked,
      Value<int> unlockRequirement,
      Value<String?> unlockCategory,
      Value<int> positionX,
      Value<int> positionY,
      Value<DateTime?> unlockedAt,
      Value<String?> customProperties,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$WorldTilesTableUpdateCompanionBuilder =
    WorldTilesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<String> name,
      Value<String?> description,
      Value<String?> imagePath,
      Value<String> tileType,
      Value<bool> isUnlocked,
      Value<int> unlockRequirement,
      Value<String?> unlockCategory,
      Value<int> positionX,
      Value<int> positionY,
      Value<DateTime?> unlockedAt,
      Value<String?> customProperties,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$WorldTilesTableFilterComposer
    extends Composer<_$AtlasDatabase, $WorldTilesTable> {
  $$WorldTilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tileType => $composableBuilder(
    column: $table.tileType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get unlockRequirement => $composableBuilder(
    column: $table.unlockRequirement,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unlockCategory => $composableBuilder(
    column: $table.unlockCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionX => $composableBuilder(
    column: $table.positionX,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get positionY => $composableBuilder(
    column: $table.positionY,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customProperties => $composableBuilder(
    column: $table.customProperties,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WorldTilesTableOrderingComposer
    extends Composer<_$AtlasDatabase, $WorldTilesTable> {
  $$WorldTilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePath => $composableBuilder(
    column: $table.imagePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tileType => $composableBuilder(
    column: $table.tileType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get unlockRequirement => $composableBuilder(
    column: $table.unlockRequirement,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unlockCategory => $composableBuilder(
    column: $table.unlockCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionX => $composableBuilder(
    column: $table.positionX,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get positionY => $composableBuilder(
    column: $table.positionY,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customProperties => $composableBuilder(
    column: $table.customProperties,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorldTilesTableAnnotationComposer
    extends Composer<_$AtlasDatabase, $WorldTilesTable> {
  $$WorldTilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imagePath =>
      $composableBuilder(column: $table.imagePath, builder: (column) => column);

  GeneratedColumn<String> get tileType =>
      $composableBuilder(column: $table.tileType, builder: (column) => column);

  GeneratedColumn<bool> get isUnlocked => $composableBuilder(
    column: $table.isUnlocked,
    builder: (column) => column,
  );

  GeneratedColumn<int> get unlockRequirement => $composableBuilder(
    column: $table.unlockRequirement,
    builder: (column) => column,
  );

  GeneratedColumn<String> get unlockCategory => $composableBuilder(
    column: $table.unlockCategory,
    builder: (column) => column,
  );

  GeneratedColumn<int> get positionX =>
      $composableBuilder(column: $table.positionX, builder: (column) => column);

  GeneratedColumn<int> get positionY =>
      $composableBuilder(column: $table.positionY, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get customProperties => $composableBuilder(
    column: $table.customProperties,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$WorldTilesTableTableManager
    extends
        RootTableManager<
          _$AtlasDatabase,
          $WorldTilesTable,
          WorldTile,
          $$WorldTilesTableFilterComposer,
          $$WorldTilesTableOrderingComposer,
          $$WorldTilesTableAnnotationComposer,
          $$WorldTilesTableCreateCompanionBuilder,
          $$WorldTilesTableUpdateCompanionBuilder,
          (
            WorldTile,
            BaseReferences<_$AtlasDatabase, $WorldTilesTable, WorldTile>,
          ),
          WorldTile,
          PrefetchHooks Function()
        > {
  $$WorldTilesTableTableManager(_$AtlasDatabase db, $WorldTilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorldTilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorldTilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorldTilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                Value<String> tileType = const Value.absent(),
                Value<bool> isUnlocked = const Value.absent(),
                Value<int> unlockRequirement = const Value.absent(),
                Value<String?> unlockCategory = const Value.absent(),
                Value<int> positionX = const Value.absent(),
                Value<int> positionY = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                Value<String?> customProperties = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorldTilesCompanion(
                id: id,
                userId: userId,
                name: name,
                description: description,
                imagePath: imagePath,
                tileType: tileType,
                isUnlocked: isUnlocked,
                unlockRequirement: unlockRequirement,
                unlockCategory: unlockCategory,
                positionX: positionX,
                positionY: positionY,
                unlockedAt: unlockedAt,
                customProperties: customProperties,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String?> imagePath = const Value.absent(),
                required String tileType,
                Value<bool> isUnlocked = const Value.absent(),
                Value<int> unlockRequirement = const Value.absent(),
                Value<String?> unlockCategory = const Value.absent(),
                Value<int> positionX = const Value.absent(),
                Value<int> positionY = const Value.absent(),
                Value<DateTime?> unlockedAt = const Value.absent(),
                Value<String?> customProperties = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WorldTilesCompanion.insert(
                id: id,
                userId: userId,
                name: name,
                description: description,
                imagePath: imagePath,
                tileType: tileType,
                isUnlocked: isUnlocked,
                unlockRequirement: unlockRequirement,
                unlockCategory: unlockCategory,
                positionX: positionX,
                positionY: positionY,
                unlockedAt: unlockedAt,
                customProperties: customProperties,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WorldTilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AtlasDatabase,
      $WorldTilesTable,
      WorldTile,
      $$WorldTilesTableFilterComposer,
      $$WorldTilesTableOrderingComposer,
      $$WorldTilesTableAnnotationComposer,
      $$WorldTilesTableCreateCompanionBuilder,
      $$WorldTilesTableUpdateCompanionBuilder,
      (WorldTile, BaseReferences<_$AtlasDatabase, $WorldTilesTable, WorldTile>),
      WorldTile,
      PrefetchHooks Function()
    >;
typedef $$ProgressEntriesTableCreateCompanionBuilder =
    ProgressEntriesCompanion Function({
      required String id,
      required String userId,
      required DateTime date,
      Value<int> xpGained,
      Value<int> tasksCompleted,
      Value<String?> category,
      Value<String?> categoryBreakdown,
      Value<String?> taskTypeBreakdown,
      Value<int> streakCount,
      Value<int> levelAtTime,
      Value<String?> additionalMetrics,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ProgressEntriesTableUpdateCompanionBuilder =
    ProgressEntriesCompanion Function({
      Value<String> id,
      Value<String> userId,
      Value<DateTime> date,
      Value<int> xpGained,
      Value<int> tasksCompleted,
      Value<String?> category,
      Value<String?> categoryBreakdown,
      Value<String?> taskTypeBreakdown,
      Value<int> streakCount,
      Value<int> levelAtTime,
      Value<String?> additionalMetrics,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ProgressEntriesTableFilterComposer
    extends Composer<_$AtlasDatabase, $ProgressEntriesTable> {
  $$ProgressEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get xpGained => $composableBuilder(
    column: $table.xpGained,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tasksCompleted => $composableBuilder(
    column: $table.tasksCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get categoryBreakdown => $composableBuilder(
    column: $table.categoryBreakdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get taskTypeBreakdown => $composableBuilder(
    column: $table.taskTypeBreakdown,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get levelAtTime => $composableBuilder(
    column: $table.levelAtTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get additionalMetrics => $composableBuilder(
    column: $table.additionalMetrics,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgressEntriesTableOrderingComposer
    extends Composer<_$AtlasDatabase, $ProgressEntriesTable> {
  $$ProgressEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get date => $composableBuilder(
    column: $table.date,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get xpGained => $composableBuilder(
    column: $table.xpGained,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tasksCompleted => $composableBuilder(
    column: $table.tasksCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get categoryBreakdown => $composableBuilder(
    column: $table.categoryBreakdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get taskTypeBreakdown => $composableBuilder(
    column: $table.taskTypeBreakdown,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get levelAtTime => $composableBuilder(
    column: $table.levelAtTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get additionalMetrics => $composableBuilder(
    column: $table.additionalMetrics,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgressEntriesTableAnnotationComposer
    extends Composer<_$AtlasDatabase, $ProgressEntriesTable> {
  $$ProgressEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<DateTime> get date =>
      $composableBuilder(column: $table.date, builder: (column) => column);

  GeneratedColumn<int> get xpGained =>
      $composableBuilder(column: $table.xpGained, builder: (column) => column);

  GeneratedColumn<int> get tasksCompleted => $composableBuilder(
    column: $table.tasksCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get categoryBreakdown => $composableBuilder(
    column: $table.categoryBreakdown,
    builder: (column) => column,
  );

  GeneratedColumn<String> get taskTypeBreakdown => $composableBuilder(
    column: $table.taskTypeBreakdown,
    builder: (column) => column,
  );

  GeneratedColumn<int> get streakCount => $composableBuilder(
    column: $table.streakCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get levelAtTime => $composableBuilder(
    column: $table.levelAtTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get additionalMetrics => $composableBuilder(
    column: $table.additionalMetrics,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ProgressEntriesTableTableManager
    extends
        RootTableManager<
          _$AtlasDatabase,
          $ProgressEntriesTable,
          ProgressEntry,
          $$ProgressEntriesTableFilterComposer,
          $$ProgressEntriesTableOrderingComposer,
          $$ProgressEntriesTableAnnotationComposer,
          $$ProgressEntriesTableCreateCompanionBuilder,
          $$ProgressEntriesTableUpdateCompanionBuilder,
          (
            ProgressEntry,
            BaseReferences<
              _$AtlasDatabase,
              $ProgressEntriesTable,
              ProgressEntry
            >,
          ),
          ProgressEntry,
          PrefetchHooks Function()
        > {
  $$ProgressEntriesTableTableManager(
    _$AtlasDatabase db,
    $ProgressEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgressEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgressEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgressEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> userId = const Value.absent(),
                Value<DateTime> date = const Value.absent(),
                Value<int> xpGained = const Value.absent(),
                Value<int> tasksCompleted = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> categoryBreakdown = const Value.absent(),
                Value<String?> taskTypeBreakdown = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<int> levelAtTime = const Value.absent(),
                Value<String?> additionalMetrics = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgressEntriesCompanion(
                id: id,
                userId: userId,
                date: date,
                xpGained: xpGained,
                tasksCompleted: tasksCompleted,
                category: category,
                categoryBreakdown: categoryBreakdown,
                taskTypeBreakdown: taskTypeBreakdown,
                streakCount: streakCount,
                levelAtTime: levelAtTime,
                additionalMetrics: additionalMetrics,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String userId,
                required DateTime date,
                Value<int> xpGained = const Value.absent(),
                Value<int> tasksCompleted = const Value.absent(),
                Value<String?> category = const Value.absent(),
                Value<String?> categoryBreakdown = const Value.absent(),
                Value<String?> taskTypeBreakdown = const Value.absent(),
                Value<int> streakCount = const Value.absent(),
                Value<int> levelAtTime = const Value.absent(),
                Value<String?> additionalMetrics = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ProgressEntriesCompanion.insert(
                id: id,
                userId: userId,
                date: date,
                xpGained: xpGained,
                tasksCompleted: tasksCompleted,
                category: category,
                categoryBreakdown: categoryBreakdown,
                taskTypeBreakdown: taskTypeBreakdown,
                streakCount: streakCount,
                levelAtTime: levelAtTime,
                additionalMetrics: additionalMetrics,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgressEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AtlasDatabase,
      $ProgressEntriesTable,
      ProgressEntry,
      $$ProgressEntriesTableFilterComposer,
      $$ProgressEntriesTableOrderingComposer,
      $$ProgressEntriesTableAnnotationComposer,
      $$ProgressEntriesTableCreateCompanionBuilder,
      $$ProgressEntriesTableUpdateCompanionBuilder,
      (
        ProgressEntry,
        BaseReferences<_$AtlasDatabase, $ProgressEntriesTable, ProgressEntry>,
      ),
      ProgressEntry,
      PrefetchHooks Function()
    >;
typedef $$SyncOperationsTableCreateCompanionBuilder =
    SyncOperationsCompanion Function({
      required String id,
      required String operationType,
      required String entityType,
      required String entityId,
      Value<String?> data,
      required DateTime timestamp,
      Value<int> retryCount,
      Value<int> maxRetries,
      Value<int> rowid,
    });
typedef $$SyncOperationsTableUpdateCompanionBuilder =
    SyncOperationsCompanion Function({
      Value<String> id,
      Value<String> operationType,
      Value<String> entityType,
      Value<String> entityId,
      Value<String?> data,
      Value<DateTime> timestamp,
      Value<int> retryCount,
      Value<int> maxRetries,
      Value<int> rowid,
    });

class $$SyncOperationsTableFilterComposer
    extends Composer<_$AtlasDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOperationsTableOrderingComposer
    extends Composer<_$AtlasDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get data => $composableBuilder(
    column: $table.data,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOperationsTableAnnotationComposer
    extends Composer<_$AtlasDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get data =>
      $composableBuilder(column: $table.data, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => column,
  );
}

class $$SyncOperationsTableTableManager
    extends
        RootTableManager<
          _$AtlasDatabase,
          $SyncOperationsTable,
          SyncOperation,
          $$SyncOperationsTableFilterComposer,
          $$SyncOperationsTableOrderingComposer,
          $$SyncOperationsTableAnnotationComposer,
          $$SyncOperationsTableCreateCompanionBuilder,
          $$SyncOperationsTableUpdateCompanionBuilder,
          (
            SyncOperation,
            BaseReferences<
              _$AtlasDatabase,
              $SyncOperationsTable,
              SyncOperation
            >,
          ),
          SyncOperation,
          PrefetchHooks Function()
        > {
  $$SyncOperationsTableTableManager(
    _$AtlasDatabase db,
    $SyncOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String?> data = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> maxRetries = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationsCompanion(
                id: id,
                operationType: operationType,
                entityType: entityType,
                entityId: entityId,
                data: data,
                timestamp: timestamp,
                retryCount: retryCount,
                maxRetries: maxRetries,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String operationType,
                required String entityType,
                required String entityId,
                Value<String?> data = const Value.absent(),
                required DateTime timestamp,
                Value<int> retryCount = const Value.absent(),
                Value<int> maxRetries = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationsCompanion.insert(
                id: id,
                operationType: operationType,
                entityType: entityType,
                entityId: entityId,
                data: data,
                timestamp: timestamp,
                retryCount: retryCount,
                maxRetries: maxRetries,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AtlasDatabase,
      $SyncOperationsTable,
      SyncOperation,
      $$SyncOperationsTableFilterComposer,
      $$SyncOperationsTableOrderingComposer,
      $$SyncOperationsTableAnnotationComposer,
      $$SyncOperationsTableCreateCompanionBuilder,
      $$SyncOperationsTableUpdateCompanionBuilder,
      (
        SyncOperation,
        BaseReferences<_$AtlasDatabase, $SyncOperationsTable, SyncOperation>,
      ),
      SyncOperation,
      PrefetchHooks Function()
    >;

class $AtlasDatabaseManager {
  final _$AtlasDatabase _db;
  $AtlasDatabaseManager(this._db);
  $$UsersTableTableManager get users =>
      $$UsersTableTableManager(_db, _db.users);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$AvatarsTableTableManager get avatars =>
      $$AvatarsTableTableManager(_db, _db.avatars);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$WorldTilesTableTableManager get worldTiles =>
      $$WorldTilesTableTableManager(_db, _db.worldTiles);
  $$ProgressEntriesTableTableManager get progressEntries =>
      $$ProgressEntriesTableTableManager(_db, _db.progressEntries);
  $$SyncOperationsTableTableManager get syncOperations =>
      $$SyncOperationsTableTableManager(_db, _db.syncOperations);
}
