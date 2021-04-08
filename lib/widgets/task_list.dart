import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:todo/models/data_models.dart';
import 'package:todo/providers/task_provider.dart';
import 'package:todo/widgets/task_list_widget.dart';




class TaskList extends StatefulWidget {
  final List<Task> taskList;
  TaskList(this.taskList);

  @override
  _TaskListState createState() => _TaskListState();
}

class _TaskListState extends State<TaskList> {
  void onFinished(Task task,bool value,BuildContext context) {
    value=!value;
    final tp = Provider.of<TaskProvider>(context,listen: false);
    if(task.repeatTask=='No Repeat') {
      task.isCompleted = value;
      tp.updateTask(task);
      tp.updateGroupSubTask(task.taskId, value);
      Scaffold.of(context).showSnackBar(SnackBar(
        content: (value)?Text("Task Finished"):Text("Task moved back to unfinished"),
        action: SnackBarAction(
          label: "undo",
          onPressed: () async{
            task.isCompleted = !value;
            await tp.updateTask(task);
            await tp.updateGroupSubTask(task.taskId, !value);
          },
        ),
      ));
    }
    else {
      bool isRepeat = true;
      showDialog(
          context: context,
          builder: (context)=> AlertDialog(
            title: Text("Warning"),
            content: Text("This task is a repeating one. Do you want to repeat it again?"),
            actions: [
              FlatButton(
                child: Text("Yes"),
                onPressed: () async{
                  if(isRepeat && task.repeatTask!='No Repeat'){
                    if(!value){
                      task.isCompleted=value;
                    }
                    else if (task.repeatTask == 'Daily') {
                      task.dueDate=task.dueDate.add(Duration(days: 1));
                    } else if (task.repeatTask == 'Two Days Once') {
                      task.dueDate=task.dueDate.add(Duration(days: 2));
                    } else if (task.repeatTask == 'Weekly') {
                      task.dueDate=task.dueDate.add(Duration(days: 7));
                    } else if (task.repeatTask == 'Monthly') {
                      task.dueDate=task.dueDate.add(Duration(days: 30));
                    } else if (task.repeatTask == 'Yearly') {
                      task.dueDate=task.dueDate.add(Duration(days: 365));
                    }
                  }
                  await tp.updateTask(task);
                  Navigator.of(context).pop();

                },
              ),
              FlatButton(
                child: Text("No"),
                onPressed: () {
                  Navigator.of(context).pop();
                  isRepeat = false;
                  task.repeatTask="No Repeat";
                  task.isCompleted = value;
                  tp.updateTask(task);
                  tp.updateGroupSubTask(task.taskId, value);

                },
              )
            ],
          )
      ).then((val) {
        if(isRepeat){
          Scaffold.of(context).showSnackBar(SnackBar(
            content: (value)?Text("Task Finished and repeated"):Text("Task moved back to unfinished and repeated"),

          ));
        }
        else{
          Scaffold.of(context).showSnackBar(SnackBar(
            content: (value)?Text("Task Finished"):Text("Task moved back to unfinished"),
            action: SnackBarAction(
              label: "undo",
              onPressed: () async{
                task.isCompleted = !value;
                await tp.updateTask(task);
                await tp.updateGroupSubTask(task.taskId, !value);
              },
            ),
          ));
        }
      });

    }
  }
  @override
  Widget build(BuildContext context) {

    return ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: widget.taskList.length,
        itemBuilder: (context,index) {
          return  TaskListWidget(key: ObjectKey(widget.taskList[index]),index: index,task:widget.taskList[index],onFinish: () =>onFinished(widget.taskList[index],widget.taskList[index].isCompleted,context),);
        }
    );
  }
}
