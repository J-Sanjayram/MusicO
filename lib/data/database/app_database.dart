// lib/data/database/app_database.dart
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('SongEntry')
class Songs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get artist => text().withLength(min: 1, max: 255)();
  TextColumn get genre => text().nullable()(); // Add more detailed metadata here
  TextColumn get mood => text().nullable()();
  TextColumn get tempo => text().nullable()();
  TextColumn get era => text().nullable()();
  TextColumn get vibe => text().nullable()();
  BoolColumn get isCreatedByAI => boolean().withDefault(const Constant(false))();
}

@DataClassName('PlaylistEntry')
class Playlists extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 255)();
  TextColumn get description => text().withLength(min: 1, max: 500)();
  TextColumn get category => text().nullable()(); // e.g., "For You", "Trending Now"
  TextColumn get relatedSongTitle => text().nullable()(); // For "Because You Listened to..."
  TextColumn get relatedSongArtist => text().nullable()(); // For "Because You Listoned to..."
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PlaylistSongEntry')
class PlaylistSongs extends Table {
  IntColumn get playlistId => integer().references(Playlists, #id)();
  IntColumn get songId => integer().references(Songs, #id)();

  @override
  Set<Column> get primaryKey => {playlistId, songId};
}

// For storing Charts and Categories (if they are fixed or AI-generated and need persistence)
@DataClassName('ChartCategoryEntry')
class ChartCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 255).unique()();
  TextColumn get type => text().withLength(min: 1, max: 50)(); // e.g., "Chart", "Category"
  TextColumn get description => text().nullable()();
}


@DriftDatabase(tables: [Songs, Playlists, PlaylistSongs, ChartCategories])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1; // Increment for migrations

  // You'll need to define _openConnection() for your platform (Flutter/Web/etc.)
  // Example for Flutter (mobile):
  static LazyDatabase _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, 'db.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  // Example functions for database interaction
  Future<List<PlaylistEntry>> getPlaylistsByCategory(String category) {
    return (select(playlists)..where((tbl) => tbl.category.equals(category))).get();
  }

  Future<List<SongEntry>> getSongsForPlaylist(int playlistId) {
    return (select(songs).join([
      innerJoin(playlistSongs, playlistSongs.songId.equalsExp(songs.id))
    ])..where(playlistSongs.playlistId.equals(playlistId))).map((row) => row.readTable(songs)).get();
  }

  Future<void> insertPlaylistWithSongs(PlaylistEntry playlist, List<SongEntry> songs) async {
    await transaction(() async {
      final playlistId = await into(playlists).insert(playlist);
      for (final song in songs) {
        final songId = await into(this.songs).insert(song, mode: InsertMode.insertOrIgnore); // Insert or ignore if song already exists
        await into(playlistSongs).insert(PlaylistSongEntry(playlistId: playlistId, songId: songId));
      }
    });
  }

  // Add methods to fetch/insert ChartCategories and their associated playlists/songs.
}