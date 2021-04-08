import 'package:flutter/material.dart';

class Task {
  int taskId;
  String taskTitle;
  DateTime dueDate;
  TimeOfDay dueTime;
  String repeatTask;
  bool isAlarm;
  String priorityName;
  String typeName;
  bool isCompleted;
  bool isOneHourMore;
  List<SubTask> subTaskList;

  Task(
      this.taskId,
      this.taskTitle,
      this.dueDate,
      this.dueTime,
      this.repeatTask,
      this.isAlarm,
      this.priorityName,
      this.typeName,
      this.isCompleted,
      this.isOneHourMore,
      this.subTaskList);
}

class SubTask {
  String subTaskTitle;
  int mainTaskId;
  int subTaskId;
  bool isCompleted;

  SubTask(
      this.subTaskTitle, this.subTaskId, this.mainTaskId, this.isCompleted);
}

class Type {
  String typeName;
  int taskTypeId;
  int tasksCount;

  Type(this.typeName, this.taskTypeId, this.tasksCount);
}


class Priority {
  String priorityName;
  Color color;
  int priority;

  Priority(this.priorityName, this.color, this.priority);


  static List<Priority> getPriorityList(){
    return [Priority('Very Important',Colors.red,3),
      Priority('Important',Colors.purple,2),
      Priority('Moderate',Colors.blue,1),
      Priority('Less Important',Colors.green,0),];
  }

  static Color getColorForPriority(String name){
       if(name=="Very Important")
         return Colors.red;
       else if(name=="Important")
         return Colors.purple;
       else if(name=="Moderate")
         return Colors.blue;
       else
         return Colors.green;
  }
}


