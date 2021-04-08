import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:todo/models/data_models.dart';
import 'package:todo/widgets/subtask_widget.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../providers/task_provider.dart';

class AddTask extends StatefulWidget {
  
  final Task task;
  AddTask({Key key,this.task}) : super(key:key);

  @override
  _AddTaskState createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  
  Task newTask = new Task(0,'',null,null,"No Repeat",false,'Moderate','Default',false,false,[]);

  bool isListening =false;

  stt.SpeechToText speech;

  TextEditingController taskTitleText = TextEditingController();

  bool isTaskTitleValid=true;
  
  String typeDropDownValue = "Default";

  Priority priorityDropDownValue = Priority.getPriorityList()[2];

  String repeatDropDownValue='No Repeat';

  bool isEdit=false;


  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
    if(widget.task!=null) {
       if (widget.task.taskTitle != '') {
           newTask = widget.task;
           isEdit = true;
           taskTitleText..text = newTask.taskTitle;
           typeDropDownValue = newTask.typeName;
           repeatDropDownValue = newTask.repeatTask;
           priorityDropDownValue = Priority.getPriorityList().firstWhere((element) => element.priorityName == newTask.priorityName);
      }
    }
  }


  void listen() async {
    if (!isListening) {
      bool available = await speech.initialize(
        onStatus: (val) {
          if(val=="notListening"){
            setState(() => isListening = false);
            speech.stop();
          }
        },
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => isListening = true);
        speech.listen(
          onResult: (val) => setState(() {
            taskTitleText..text=val.recognizedWords;
            taskTitleText..selection = TextSelection.collapsed(offset: taskTitleText.text.length);
            newTask.taskTitle=val.recognizedWords;
          }),
          listenFor: Duration(seconds: 20),
        );

      }

    } else {
      setState(() => isListening = false);
      speech.stop();
    }

  }

  void updateList(){
    for(int i=0;i<newTask.subTaskList.length;i++){
      if(newTask.subTaskList[i].subTaskTitle==''){
        newTask.subTaskList.removeAt(i);
      }
    }
  }

  void submitTask() async{
    if(taskTitleText.text==''){
      setState(() {
        isTaskTitleValid= false;
      });
      return;
    }
    if(isEdit)
    widget.task.taskTitle=taskTitleText.text;
    setState(() {
      isTaskTitleValid= true;
      updateList();
    });
    if(isEdit){
      Provider.of<TaskProvider>(context,listen: false).updateTask(newTask);
      if(newTask.dueDate!=null){
        await Provider.of<TaskProvider>(context,listen: false).showNotification(newTask, newTask.taskId, true);
      }
      Navigator.of(context).pop();
    }else {
      int id= await Provider.of<TaskProvider>(context, listen: false).addTask(newTask);
      if(newTask.dueDate!=null){
        await Provider.of<TaskProvider>(context,listen: false).showNotification(newTask, id, false);
      }
      Navigator.of(context).pop();
    }

  }

  void removeSubTask(SubTask item){
    newTask.subTaskList.remove(item);
    if(isEdit){
      Provider.of<TaskProvider>(context,listen: false).deleteSubTask(item.subTaskId);
    }
    setState(() {});
  }

  Widget defaultHeadingContainer(String text){
    return Container(
      margin: EdgeInsets.only(top: 10),
      child: Text(
        text,
        style: TextStyle(color: Colors.purple,fontSize: 15),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TaskProvider>(context,listen: false);
    var typeList = tp.getTypeList.map((e) => e.typeName).toList();
    return WillPopScope(
      onWillPop: () async =>true,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          leading: IconButton(
              icon: FaIcon(FontAwesomeIcons.arrowLeft,color: Colors.white,),
              onPressed: () =>Navigator.of(context).pop(),
                  
          ),
          title: Text(
            (isEdit)?"Edit Task":"Add a Task",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Container(
                  width: MediaQuery.of(context).size.width*0.95,
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            //title field
                            defaultHeadingContainer("What is to be done?"),
                            Row(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width*0.7,
                                  child: TextField(
                                    cursorColor: Colors.purpleAccent,
                                    controller: taskTitleText,
                                    decoration: InputDecoration(
                                      labelText: "Enter the Task e.g: go to party",
                                      errorText: (isTaskTitleValid)?null:"Task cannot be empty",
                                      labelStyle: TextStyle(fontSize: 15),
                                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.purpleAccent))
                                    ),
                                    onChanged: (value){
                                      setState(() {

                                            isTaskTitleValid= true;
                                            if(!isEdit){
                                              newTask.taskTitle=value;
                                            }
                                      });
                                    },
                                    onSubmitted: (val){
                                      newTask.taskTitle=val;
                                    },
                                  ),
                                ),
                                AvatarGlow(
                                  animate: isListening,
                                  glowColor: (isListening)?Colors.purple:Colors.black,
                                  duration: Duration(milliseconds: 1000),
                                  repeatPauseDuration: Duration(milliseconds: 100),
                                  repeat: true,
                                  endRadius: 25,
                                  child: IconButton(
                                    icon: FaIcon(FontAwesomeIcons.microphoneAlt,color: (isListening)?Colors.purple:Colors.black,),
                                    onPressed: () {
                                      listen();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            //date field
                            defaultHeadingContainer("Select Due Date"),
                            Row(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width*0.7,
                                  child: TextField(
                                    enabled: false,
                                    decoration: InputDecoration(
                                        labelText: (newTask.dueDate==null)?"Due Date":DateFormat.yMMMd().format(newTask.dueDate),
                                      labelStyle: TextStyle(fontSize: 15,color: Colors.black),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: FaIcon(FontAwesomeIcons.calendarCheck),
                                  onPressed: () =>showDatePicker(
                                      context: context,
                                      initialDate: DateTime.now(),
                                      firstDate: DateTime.now(),
                                      lastDate: DateTime.now().add(Duration(days: 365)),
                                  ).then((value) {
                                    setState(() {
                                      newTask.dueDate=(value!=null)?value:null;
                                      newTask.dueTime=(value!=null)?TimeOfDay(hour: 23,minute: 59):null;
                                    });
                                  }
                                  )
                                ),
                              ],
                            ),
                            //time field
                            if(newTask.dueDate != null)
                            defaultHeadingContainer("Select time"),
                            if(newTask.dueDate != null)
                            Row(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width*0.7,
                                  child: TextField(
                                    enabled: false,
                                    decoration: InputDecoration(
                                        labelText: (newTask.dueTime==null)?"Due Time":newTask.dueTime.format(context),
                                      labelStyle: TextStyle(fontSize: 15,color: Colors.black),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: FaIcon(FontAwesomeIcons.clock),
                                  onPressed: () =>showTimePicker(
                                      context: context,
                                      initialTime: TimeOfDay.now(),
                                      cancelText: "Back",
                                      confirmText: "Ok"
                                  ).then((value) {
                                    setState(() {
                                      newTask.dueTime= (value!=null)?value:TimeOfDay(hour: 23,minute: 59);
                                    });
                                  }
                                  )
                                ),
                              ],
                            ),
                            defaultHeadingContainer("Set it's type"),
                            Row(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width*0.7,
                                  child: DropdownButton(
                                    hint: Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: Container(
                                        width: MediaQuery.of(context).size.width*0.6,
                                        child: Text(
                                          typeDropDownValue,
                                          style: TextStyle(color: Colors.black, fontSize: 15),
                                        ),
                                      ),
                                    ),
                                    icon: FaIcon(
                                      FontAwesomeIcons.caretDown,
                                      color: Color.fromRGBO(196, 197, 197, 1),
                                    ),
                                    items: typeList.map<DropdownMenuItem<String>>((String val) {
                                      return DropdownMenuItem(
                                        value: val,
                                        child: Container(
                                          child: Text(
                                            val,
                                            style: TextStyle(color: Colors.black),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        typeDropDownValue = value;
                                        newTask.typeName = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            defaultHeadingContainer("Set Priority"),
                            Row(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width*0.7,
                                  child: DropdownButton(
                                    hint: Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: Container(
                                        width: MediaQuery.of(context).size.width*0.6,
                                        child: Row(
                                          children: [
                                            FaIcon(FontAwesomeIcons.solidFlag,color: priorityDropDownValue.color,size: 20,),
                                            SizedBox(width: 10),
                                            Text(
                                              priorityDropDownValue.priorityName,
                                              style: TextStyle(color: Colors.black, fontSize: 15),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    icon: FaIcon(
                                      FontAwesomeIcons.caretDown,
                                      color: Color.fromRGBO(196, 197, 197, 1),
                                    ),
                                    items: Priority.getPriorityList().map<DropdownMenuItem<Priority>>((Priority val) {
                                      return DropdownMenuItem(
                                        value: val,
                                        child: Container(
                                          child: Row(
                                            children: [
                                              FaIcon(FontAwesomeIcons.solidFlag,color: val.color,size: 20,),
                                              SizedBox(width: 10),
                                              Text(
                                                val.priorityName,
                                                style: TextStyle(color: Colors.black),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        priorityDropDownValue = value;
                                        newTask.priorityName=value.priorityName;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            defaultHeadingContainer("Repeat"),
                            Row(
                              children: [
                                Container(
                                  width: MediaQuery.of(context).size.width*0.7,
                                  child: DropdownButton(
                                    hint: Padding(
                                      padding: const EdgeInsets.only(right: 5),
                                      child: Container(
                                        width: MediaQuery.of(context).size.width*0.6,
                                        child: Text(
                                          repeatDropDownValue,
                                          style: TextStyle(color: Colors.black, fontSize: 15),
                                        ),
                                      ),
                                    ),
                                    icon: FaIcon(
                                      FontAwesomeIcons.caretDown,
                                      color: Color.fromRGBO(196, 197, 197, 1),
                                    ),
                                    items: ["No Repeat","Daily","Two Days Once","Weekly","Monthly","Yearly"].map<DropdownMenuItem<String>>((String val) {
                                      return DropdownMenuItem(
                                        value: val,
                                        child: Container(
                                          child: Text(
                                            val,
                                            style: TextStyle(color: Colors.black),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        repeatDropDownValue = value;
                                        newTask.repeatTask = value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if(newTask.subTaskList.length!=0)
                            Container(
                              child: ListView.builder(
                                shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  itemCount: newTask.subTaskList.length,
                                  itemBuilder: (context,index) {
                                  final item = newTask.subTaskList[index];
                                  return SubTaskWidget(
                                      key:ObjectKey(item),
                                      newTask:item,
                                      index:index,
                                      removeTask:()=>removeSubTask(item)
                                  );
                                  },
                              ),
                            ),
                            Center(
                              child: Container(
                                child: FlatButton(
                                  child: Text(
                                    "Add a sub task",
                                    style: TextStyle(decoration: TextDecoration.underline,color: Colors.purple),
                                  ),
                                  onPressed: (){
                                    setState(() {
                                      var newSubTask = new SubTask("",0,newTask.taskId,false);
                                      newTask.subTaskList.add(newSubTask);
                                    });
                                  },
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                ),
              ),
              Center(
                child: Container(
                  child: RaisedButton(
                    color: Colors.purple,
                    child: Text((isEdit)?"Update Task":"Add Task",style: TextStyle(color: Colors.white),),
                    onPressed: () {
                      submitTask();
                    },
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
