import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(ToDoApp());
}

class ToDoApp extends StatefulWidget {
  const ToDoApp({super.key});

  @override
  State<ToDoApp> createState() => _ToDoAppState();
}

class _ToDoAppState extends State<ToDoApp> {
  int? selectedId;
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: textController,
          ),
        ),
        body: Center(
          child: FutureBuilder<List<Zadania>>(
            future: DatabaseHelper.instance.getZadania(),
            builder:
                (BuildContext context, AsyncSnapshot<List<Zadania>> snapshot) {
              if (!snapshot.hasData) {
                return Center(child: Text('Loading...'));
              }
              return snapshot.data!.isEmpty
                  ? Center(child: Text('Brak zadań'))
                  : ListView(
                      children: snapshot.data!.map((zadania) {
                        return Center(
                          child: ListTile(
                            title: Text(zadania.name),
                            onTap: () {
                              setState(() {
                                textController.text = zadania.name;
                                selectedId = zadania.id;
                              });
                            },
                            onLongPress: () {
                              setState(() {
                                DatabaseHelper.instance.remove(zadania.id!);
                              });
                            },
                          ),
                        );
                      }).toList(),
                    );
            },
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.save),
          onPressed: () async {
            selectedId != null
                ? await DatabaseHelper.instance.update(
                    Zadania(id: selectedId, name: textController.text),
                  )
                : await DatabaseHelper.instance
                    .add(Zadania(name: textController.text));
            setState(() {
              textController.clear();
            });
          },
        ),
      ),
    );
  }
}

class Zadania {
  final int? id;
  final String name;

  Zadania({this.id, required this.name});

  factory Zadania.fromMap(Map<String, dynamic> json) => new Zadania(
        id: json['id'],
        name: json['name'],
      );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'zadania.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
    CREATE TABLE zadania(
    id INTEGER PRIMARY KEY,
    name TEXT)
    ''');
  }

  Future<List<Zadania>> getZadania() async {
    Database db = await instance.database;
    var zadania = await db.query('zadania', orderBy: 'name');
    List<Zadania> zadaniaList = zadania.isNotEmpty
        ? zadania.map((c) => Zadania.fromMap(c)).toList()
        : [];
    return zadaniaList;
  }

  Future<int> add(Zadania zadania) async {
    Database db = await instance.database;
    return await db.insert('zadania', zadania.toMap());
  }

  Future<int> remove(int id) async {
    Database db = await instance.database;
    return await db.delete('zadania', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> update(Zadania zadania) async {
    Database db = await instance.database;
    return await db.update('zadania', zadania.toMap(),
        where: 'id = ?', whereArgs: [zadania.id]);
  }
}
