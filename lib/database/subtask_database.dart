import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;

class SubTaskDbHelper {
  static Future<sql.Database> database () async{
    final dbPath = await sql.getDatabasesPath();
    return await sql.openDatabase(path.join(dbPath,"subTask.db"),onCreate: (db,version){
      return db.execute(
          "CREATE TABLE subTasks(subTaskId INTEGER PRIMARY KEY AUTOINCREMENT,subTaskTitle TEXT NOT NULL,mainTaskId INTEGER NOT NULL,isCompleted DECIMAL(1))"
      );
    },version: 1
    );
  }

  static Future<void> insert(String table,Map<String,Object> data) async {
    final db = await  SubTaskDbHelper
    .database();
    db.insert(table, data);
  }

  static Future<List<Map<String,Object>>> getDb (String table,int id) async {
    final db = await  SubTaskDbHelper
    .database();
    return await db.query(table,where: 'mainTaskId=?',whereArgs: [id]);
  }

  static Future<void> deleteRecord(String table,int id) async{
    final db = await  SubTaskDbHelper
    .database();
    return await db.delete(table,where: 'subTaskId=?',whereArgs: [id]);
  }


  static Future<void> updateRecord(String table,int id,Map<String,Object> data) async{
    final db = await  SubTaskDbHelper
        .database();
    return await db.update(table, data,where: 'subTaskId=?',whereArgs: [id]);
  }

  static Future<void> deleteGroupRecord(String table,int id) async{
    final db = await  SubTaskDbHelper
        .database();
    return await db.delete(table,where: 'mainTaskId=?',whereArgs: [id]);
  }

}