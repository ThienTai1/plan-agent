// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  // Try to find the database file. On macOS support dir is usually:
  // ~/Library/Application Support/powersync-app.db
  final home = Platform.environment['HOME'];
  final dbPath = '$home/Library/Application Support/powersync-app.db';

  if (!File(dbPath).existsSync()) {
    print('Database not found at $dbPath');
    return;
  }

  print('Opening database at $dbPath');
  // We can't easily use sqflite in a pure dart script without flutter.
  // But we can use the 'sqlite3' command line tool via Process.run.

  final result = await Process.run('sqlite3', [
    dbPath,
    'SELECT id, user_id, title, status, is_completed FROM tasks;',
  ]);

  if (result.exitCode != 0) {
    print('Error running sqlite3: ${result.stderr}');
  } else {
    print('Tasks in database:');
    print(result.stdout);
  }
}
