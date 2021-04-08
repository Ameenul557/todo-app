
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:todo/database/subtask_database.dart';
import 'package:todo/database/task_database.dart';
import 'package:todo/models/data_models.dart';



class TaskProvider with ChangeNotifier{
  List<Task> _taskList=[];
  List<Task> dueTaskList=[];
  List<Task> todayTaskList=[];
  List<Task> tomorrowTaskList=[];
  List<Task> thisWeekTaskList=[];
  List<Task> nextWeekTaskList =[];
  List<Task> thisMonthTaskList =[];
  List<Task> laterTaskList =[];
  List<Task> completedTaskList=[];
  List<Task> noDueTaskList=[];

  List<Task> veryHighPriorityList =[];
  List<Task> highPriorityList =[];
  List<Task> moderatePriorityList =[];
  List<Task> lowPriorityList =[];
  List<Task> unsortedPriorityList =[];
  

  List<Type> typeList;

  String typeValue = "All Tasks";
  String sortValue = "Date only";
  


  int getItemsCount(String type) {
    int i=0;
    if(type=='Finished'){
      _taskList.forEach((element) {
        if(element.isCompleted)
          i++;
      });
      return i;
    }
    if(type=="All Tasks"){
      _taskList.forEach((element) {
        if(!element.isCompleted)
          i++;
      });
      return i;
    }
    _taskList.forEach((element) {
      if(element.typeName==type && !element.isCompleted)
        i++;
    }
    );
    return i;
  }

  setUnsortedPriorityList(){
    unsortedPriorityList = dueTaskList+todayTaskList+tomorrowTaskList+thisWeekTaskList+nextWeekTaskList+thisMonthTaskList+laterTaskList+noDueTaskList;
    initListBasedOnPriority(typeValue);
  }

  void setSortValue(String value){
    sortValue=value;

    if(sortValue=='Date+Priority'){
      initLists(typeValue);
      setUnsortedPriorityList();
    }
    notifyListeners();
  }

  void setTypeValue(String value){
    typeValue=value;
    initLists(value);
    if(sortValue=='Date+Priority'){
      initLists(typeValue);
      setUnsortedPriorityList();
    }
    notifyListeners();
  }

  Future<int> addTask(Task task) async{
      int id=await TaskDbHelper.insert('tasks',{
        'taskName' : task.taskTitle,
        'dueDate' : (task.dueDate!=null)?task.dueDate.toIso8601String():null,
        'dueTime' : (task.dueTime!=null)?task.dueTime.toString():null,
        'repeatTask' : task.repeatTask,
        'isAlarm' : (task.isAlarm)?1:0,
        'priorityName':task.priorityName,
        'typeName':task.typeName,
        'isCompleted' :(task.isCompleted)?1:0,
        'isOneHourMore':(task.isOneHourMore)?1:0,
      });
      if(task.subTaskList.isNotEmpty)
        await addSubTask(task.subTaskList,id);
      await fetchAndSetTask();
      return id;
  }

  Future<void> addSubTask(List<SubTask> subTask,int id) async{
    subTask.forEach((element) {
      SubTaskDbHelper.insert('subTasks', {
        'subTaskTitle':element.subTaskTitle,
        'mainTaskId':id,
        'isCompleted': (element.isCompleted)?1:0,
      });
    });
  }

  Future<void> updateTask(Task task) async{
      AwesomeNotifications().cancel(task.taskId);
      if(!task.isCompleted)
        showNotification(task, task.taskId, false);
    await TaskDbHelper.updateRecord('tasks',task.taskId,{
      'taskName' : task.taskTitle,
      'dueDate' : (task.dueDate!=null)?task.dueDate.toIso8601String():null,
      'dueTime' : (task.dueTime!=null)?task.dueTime.toString():null,
      'repeatTask' : task.repeatTask,
      'isAlarm' : (task.isAlarm)?1:0,
      'priorityName':task.priorityName,
      'typeName':task.typeName,
      'isCompleted' :(task.isCompleted)?1:0,
      'isOneHourMore':(task.isOneHourMore)?1:0,
    });
    if(task.subTaskList.isNotEmpty){
      task.subTaskList.forEach((element) async {
        if (element.subTaskId == 0) {
          addSubTask([element], task.taskId);
          await TaskDbHelper.updateRecord('tasks', task.taskId, {'isCompleted' : 0});
        }
        else{
          await updateSubTask(element);
        }
      });

    }
    await fetchAndSetTask();
  }

  Future<void> fetchAndSetTask() async{
    final data = await TaskDbHelper.getDb('tasks');
    final listData = data.map((e)  => Task(
        e['taskId'],
        e['taskName'],
        (e['dueDate']!=null)?DateTime.parse(e['dueDate']):null,
        (e['dueTime']!=null)?TimeOfDay(hour: int.parse(e['dueTime'].toString().substring(10,12)),minute: int.parse(e['dueTime'].toString().substring(13,15))):null,
        e['repeatTask'],
        (e['isAlarm']==1)?true:false,
        e['priorityName'],
        e['typeName'],
        (e['isCompleted']==1)?true:false,
        (e['isOneHourMore']==1)?true:false,
        [],
    )
    ).toList();
    _taskList=listData;
    _taskList.forEach((element) async{
      element.subTaskList=await getSubTask(element.taskId);
      notifyListeners();
    });
    initLists(typeValue);
    setUnsortedPriorityList();
    notifyListeners();
  }

  Future<void> updateSubTask(SubTask subTask) async{

    SubTaskDbHelper.updateRecord('subTasks', subTask.subTaskId, {
      'subTaskTitle':subTask.subTaskTitle,
      'isCompleted':(subTask.isCompleted)?1:0,
      'mainTaskId':subTask.mainTaskId
    }
    );
  }

  Future<void> updateGroupSubTask(int mainId,bool value)async{
   _taskList.forEach((element) {
     if(element.taskId==mainId){
       element.subTaskList.forEach((element) {
         element.isCompleted=value;
         updateSubTask(element);
       });
     }
   });
  }

  Future<void> deleteSubTask(int id) async{
    SubTaskDbHelper.deleteRecord('subTasks', id);
  }

  void initLists(String typeDropDownValue) {
    dueTaskList=[];
    todayTaskList=[];
    tomorrowTaskList=[];
    thisWeekTaskList=[];
    nextWeekTaskList=[];
    thisMonthTaskList=[];
    laterTaskList=[];
    completedTaskList=[];
    noDueTaskList=[];


    dueTaskList.addAll(_taskList.where((element) {
      if(element.typeName == typeDropDownValue || typeDropDownValue=="All Tasks"){
        if (element.dueDate == null) {
          return false;
        }
        if (element.isCompleted) return false;
        if (element.dueDate != null && element.dueTime == null) {
          if (element.dueDate.year==DateTime.now().year && element.dueDate.month==DateTime.now().month && element.dueDate.day==DateTime.now().day) {
            return false;
          }
        }
        if(element.dueTime!=null) {
          final fullDate = DateTime(
            element.dueDate.year,
            element.dueDate.month,
            element.dueDate.day,
            element.dueTime.hour,
            element.dueTime.minute,
          );
          if ( fullDate
              .isBefore(DateTime.now())) {
            return true;
          }
          return false;
        }

      }
      return false;
    }));

    todayTaskList.addAll(_taskList.where((element) => ( (element.typeName == typeDropDownValue || typeDropDownValue=="All Tasks") &&
        element.dueDate != null &&
        !element.isCompleted &&
        element.dueDate.year == DateTime.now().year &&
        element.dueDate.month == DateTime.now().month &&
        element.dueDate.day == DateTime.now().day &&
        !dueTaskList.contains(element))
        ? true
        : false));

    tomorrowTaskList.addAll(_taskList.where((element) => ( (element.typeName == typeDropDownValue || typeDropDownValue=="All Tasks") &&
        element.dueDate != null &&
        !element.isCompleted &&
        element.dueDate.year == DateTime.now().year &&
        element.dueDate.month == DateTime.now().month &&
        element.dueDate.day == DateTime.now().add(Duration(days: 1)).day &&
        !dueTaskList.contains(element))
        ? true
        : false));

    thisWeekTaskList.addAll(_taskList.where((element) => ( (element.typeName == typeDropDownValue || typeDropDownValue=="All Tasks") &&
        element.dueDate != null &&
        !element.isCompleted &&
        element.dueDate.isBefore((DateTime.now().add(Duration(days: 7-DateTime.now().weekday)))) &&
        element.dueDate.isAfter((DateTime.now().add(Duration(days: 1)))) &&
        !tomorrowTaskList.contains(element) &&
        !dueTaskList.contains(element))
        ? true
        : false));

    nextWeekTaskList.addAll(_taskList.where((element) => ( (element.typeName == typeDropDownValue || typeDropDownValue=="All Tasks") &&
        element.dueDate != null &&
        !element.isCompleted &&
        element.dueDate.isBefore(DateTime.now().add(Duration(days: 14-(DateTime.now().weekday)))) &&
        element.dueDate.isAfter(DateTime.now().add(Duration(days: 7-DateTime.now().weekday))) &&
        !tomorrowTaskList.contains(element) &&
        !dueTaskList.contains(element)) &&
        !thisWeekTaskList.contains(element)
        ? true
        : false));

    thisMonthTaskList.addAll(_taskList.where((element) => ( (element.typeName == typeDropDownValue || typeDropDownValue=="All Tasks") &&
        element.dueDate != null &&
        !element.isCompleted &&
        !tomorrowTaskList.contains(element) &&
        !dueTaskList.contains(element) &&
        !todayTaskList.contains(element) &&
        !thisWeekTaskList.contains(element) &&
        !nextWeekTaskList.contains(element) &&
        element.dueDate.year== DateTime.now().year&&
        element.dueDate.month == DateTime.now().month
    )
        ? true
        : false));

    laterTaskList.addAll(_taskList.where((element) =>
    (element.typeName == typeDropDownValue || typeDropDownValue=="All Tasks") &&
        element.dueDate != null &&
        !element.isCompleted &&
        !dueTaskList.contains(element) &&
        !todayTaskList.contains(element) &&
        !thisWeekTaskList.contains(element) &&
        !nextWeekTaskList.contains(element) &&
        !thisMonthTaskList.contains(element) &&
        !tomorrowTaskList.contains(element)
    )
    );

    noDueTaskList.addAll(_taskList.where((element) =>(element.typeName==typeDropDownValue || typeDropDownValue=="All Tasks") &&element.dueDate==null && !element.isCompleted));

    completedTaskList.addAll(_taskList.where((element) => element.isCompleted));
  }

  void initListBasedOnPriority(String type){
    veryHighPriorityList=[];
    highPriorityList=[];
    moderatePriorityList=[];
    lowPriorityList=[];
    veryHighPriorityList.addAll(unsortedPriorityList.where((element) => element.priorityName=='Very Important' && !element.isCompleted && (element.typeName==type || type=="All Tasks")));
    highPriorityList.addAll(unsortedPriorityList.where((element) => element.priorityName=='Important' && !element.isCompleted && (element.typeName==type || type=="All Tasks")));
    moderatePriorityList.addAll(unsortedPriorityList.where((element) => element.priorityName=='Moderate' && !element.isCompleted && (element.typeName==type || type=="All Tasks")));
    lowPriorityList.addAll(unsortedPriorityList.where((element) => element.priorityName=='Less Important' && !element.isCompleted && (element.typeName==type || type=="All Tasks")));
  }

  bool taskSelection = false;
  List selectedList=[];
  void setTaskSelection(){
    taskSelection = !taskSelection;
    if(!taskSelection){
      selectedList=[];
    }
    notifyListeners();
  }
  
  void selectedListIndexInsert(int index){
    selectedList.add(index);
  }
  
  void selectedListIndexRemove(int index){
    selectedList.remove(index);
    if(selectedList.isEmpty){
      setTaskSelection();
    }
  }
  
  Future<void> deleteSelected() async{
     selectedList.forEach((element) async {
      await TaskDbHelper.deleteRecord('tasks', element);
      await SubTaskDbHelper.deleteGroupRecord('subTasks', element);
    });
     taskSelection=false;
     selectedList=[];
     await fetchAndSetTask();
  }

  Future<void> markAsCompleted() async{
    selectedList.forEach((element) async{
      await TaskDbHelper.updateRecord('tasks', element, {'isCompleted':1});
      await updateGroupSubTask(element, true);
    });
    taskSelection=false;
    selectedList=[];
    await fetchAndSetTask();
  }
  
  Future<List<SubTask>> getSubTask(int id)  async{
    final data = await SubTaskDbHelper.getDb('subTasks', id);
    var subTaskList=[];
    subTaskList = data.map((element) => SubTask(
      element['subTaskTitle'],
      element['subTaskId'],
      element['mainTaskId'],
      (element['isCompleted']==1)?true:false
    )
    ).toList();
    return subTaskList;
  }



  List<Type> get getTypeList{
    typeList=[
      Type('Default',1,0),Type('Home',1,0),Type('Personal',2,0),Type('Shopping',3,0),Type('Work',1,0),Type('Others',4,0),
    ];
    return typeList;
  }
  

  Future<void> showNotification(Task task,int id,bool isEdit) async{

    DateTime dateTime;
    if(isEdit){
      AwesomeNotifications().cancel(task.taskId);
    }
    if(task.dueTime!=null){
      dateTime=DateTime(task.dueDate.year,task.dueDate.month,task.dueDate.day,task.dueTime.hour,task.dueTime.minute);
    }
    else{
      dateTime=DateTime(task.dueDate.year,task.dueDate.month,task.dueDate.day,23,59);
    }

    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        // Insert here your friendly dialog box before call the request method
        // This is very important to not harm the user experience
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: task.taskTitle,
        body: 'Task Over Due.Click to view',
      ),
      schedule: NotificationSchedule(
        allowWhileIdle: true,
        crontabSchedule: CronHelper.instance.atDate(dateTime.toUtc(),initialSecond: 0),
      ),
    );

  }

}
