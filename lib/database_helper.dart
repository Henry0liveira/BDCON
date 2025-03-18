import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'contatos.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE contatos('
          'id INTEGER PRIMARY KEY AUTOINCREMENT, '
          'nome TEXT NOT NULL, '
          'telefone TEXT, '
          'email TEXT, '
          'foto TEXT, '
          'data_criacao TEXT, '
          'categoria TEXT)',
        );
      },
    );
  }

  Future<int> insertContato(Map<String, dynamic> contato) async {
    // Se data_criacao não foi fornecida, adicione a data atual
    if (contato['data_criacao'] == null) {
      contato['data_criacao'] = DateTime.now().toIso8601String();
    }
    
    final db = await database;
    return await db.insert(
      'contatos',
      contato,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Map<String, dynamic>>> getContatos() async {
    final db = await database;
    return await db.query('contatos', orderBy: 'nome');
  }

  Future<int> updateContato(Map<String, dynamic> contatoAtualizado) async {
    final db = await database;
    return await db.update(
      'contatos',
      contatoAtualizado,
      where: 'id = ?',
      whereArgs: [contatoAtualizado['id']],
    );
  }

  Future<int> deleteContato(int id) async {
    final db = await database;
    return await db.delete(
      'contatos',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}