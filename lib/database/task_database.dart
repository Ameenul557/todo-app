import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as path;


class TaskDbHelper {
  static Future<sql.Database> database () async{
    final dbPath = await sql.getDatabasesPath();
    return await sql.openDatabase(path.join(dbPath,"task.db"),onCreate: (db,version){
       return db.execute(
         "CREATE TABLE tasks(taskId INTEGER PRIMARY KEY AUTOINCREMENT,taskName TEXT NOT NULL,dueDate TEXT,dueTime Text,repeatTask VARCHAR(14),isAlarm DECIMAL(1),priorityName VARCHAR(15),typeName TEXT,isCompleted DECIMAL(1),isOneHourMore Decimal(1))"
       );
    },version: 1
    );
  }

  static Future<int> insert(String table,Map<String,Object> data) async {
    final db = await TaskDbHelper.database();
    return db.insert(table, data);
  }

  static Future<List<Map<String,Object>>> getDb (String table) async {
    final db = await TaskDbHelper.database();
    return await db.query(table);
  }

  static Future<List<Map<String,Object>>> getRecordAtIndex (String table,int id) async {
    final db = await TaskDbHelper.database();
    return await db.query(table,where: 'taskId=?',whereArgs: [id]);
  }

  static Future<void> deleteRecord(String table,int id) async{
    final db = await TaskDbHelper.database();
    return await db.delete(table,where: 'taskId=?',whereArgs: [id]);
  }

  static Future<void> updateRecord(String table,int id,Map<String,Object> data) async{
    final db = await TaskDbHelper.database();
    return await db.update(table, data,where: 'taskId=?',whereArgs: [id]);
  }



}


