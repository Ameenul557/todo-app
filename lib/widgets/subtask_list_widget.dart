import 'package:flutter/material.dart';
import 'package:todo/models/data_models.dart';
import 'package:todo/providers/task_provider.dart';
import 'package:provider/provider.dart';

class SubTaskListWidget extends StatefulWidget {
  final Task task;
  SubTaskListWidget(this.task);

  @override
  _SubTaskListWidgetState createState() => _SubTaskListWidgetState();
}

class _SubTaskListWidgetState extends State<SubTaskListWidget> {
  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TaskProvider>(context);
    return ListView.builder(
        physics: NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: widget.task.subTaskList.length,
        itemBuilder: (context, index) {
          return Container(
            width: MediaQuery.of(context).size.width * 0.4,
            child: Row(
              children: [
                Checkbox(
                  value: widget.task.subTaskList[index].isCompleted,
                  onChanged: (value) {
                    if(widget.task.isCompleted) {
                      if (!value) {
                        widget.task.isCompleted = false;
                        tp.updateTask(widget.task);
                      }
                    }
                    widget.task.subTaskList[index].isCompleted=value;
                    setState(() {

                    });
                    tp.updateSubTask(widget.task.subTaskList[index]);
                  },
                ),
                Text(widget.task.subTaskList[index].subTaskTitle)
              ],
            ),
          );
        });
  }
}
