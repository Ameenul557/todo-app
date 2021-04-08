
import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:todo/Screens/add_or_edit_notes.dart';

import 'package:todo/models/data_models.dart';
import 'package:todo/providers/task_provider.dart';
import 'package:todo/widgets/task_list.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;



class HomeScreen extends StatefulWidget{

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool isListening =false;

  stt.SpeechToText speech;

  TextEditingController taskTitleText = TextEditingController();
  
  Task newTask=Task(0,'',null,null,'Never',false,'Moderate','Default',false,false,[]);

  bool isTaskTitleValid=true;

  @override
  void initState() {
    super.initState();
    speech = stt.SpeechToText();
  }



  Widget buildHeadingContainer(String text,bool isWarning){
    return Container(
      padding: EdgeInsets.only(top: 15,bottom: 5,left: 5),
      child: Text(
        text,
        style: TextStyle(
            color: (isWarning)?Colors.red:Colors.purpleAccent,
            fontSize: 18,
            ),
      ),
    );
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

  void submitTask(){
    if(taskTitleText.text==''){
      setState(() {
        isTaskTitleValid= false;
      });
      return;
    }
    taskTitleText..text="";
    Provider.of<TaskProvider>(context,listen: false).addTask(newTask);
    FocusManager.instance.primaryFocus.unfocus();
    newTask.taskTitle="";
  }


  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<TaskProvider>(context);
    return WillPopScope(
      onWillPop: () async {
        if(tp.taskSelection) {
          tp.setTaskSelection();
          return  false;
        }
        return true;
      },
      child: Scaffold(
        appBar: (tp.taskSelection)? AppBar(
          backgroundColor: Colors.purple,
          title: Text(
            "Select Tasks",
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            IconButton(
              icon: FaIcon(FontAwesomeIcons.checkSquare,color: Colors.white,size: 20,),
              onPressed: (){
                tp.markAsCompleted();
              },
            ),
            IconButton(
              icon: FaIcon(FontAwesomeIcons.trash,size: 20,color: Colors.white,),
              onPressed: (){
                    tp.deleteSelected();
              },
            ),

          ],
        ):AppBar(
          title: Container(
            child: DropdownButton(
              hint: Padding(
                padding: const EdgeInsets.only(right: 5),
                child: Text(
                  tp.typeValue,
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              icon: FaIcon(
                FontAwesomeIcons.caretDown,
                color: Color.fromRGBO(196, 197, 197, 1),
              ),
              items: <String>['All Tasks', 'Default','Home','Personal', 'Shopping','Work','Others','Finished']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Row(
                    children: [
                      Text(
                        value,
                        style: TextStyle(color: Colors.black),
                      ),
                      Text(
                        "("+tp.getItemsCount(value).toString()+")"
                      )
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                  tp.setTypeValue(value);
              },
            ),
          ),
          backgroundColor: Colors.purple,
          actions: [
            Padding(
              padding: EdgeInsets.all(3),
              child: IconButton(
                icon: FaIcon(FontAwesomeIcons.plus),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context)=> AddTask()));
                },
              ),
            ),
          ],
        ),
        body:
           GestureDetector(
              onTap: () {
                FocusScope.of(context).requestFocus(new FocusNode());
                if(tp.taskSelection)
                   tp.setTaskSelection();
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if(tp.typeValue!="Finished")
                      Container(
                        padding: EdgeInsets.all(8),
                        child: Text(
                          "Sort By: ",
                          style: TextStyle(
                              fontSize: 18,

                              color: Colors.purpleAccent),
                        ),
                      ),
                      if(tp.typeValue!="Finished")
                      Container(
                        child: DropdownButton(
                          hint: Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: Text(
                              tp.sortValue,
                              style: TextStyle(color: Colors.black, fontSize: 18),
                            ),
                          ),
                          icon: FaIcon(
                            FontAwesomeIcons.caretDown,
                            color: Color.fromRGBO(196, 197, 197, 1),
                          ),
                          items: <String>[
                            'Date only',
                            'Date+Priority',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: TextStyle(color: Colors.black),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                              tp.setSortValue(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  if(tp.sortValue=='Date only')
                  Expanded(
                    child: Container(
                      width: MediaQuery.of(context).size.width*0.97,
                      child: Scrollbar(
                        child: (tp.typeValue!="Finished")?ListView(
                          children: [
                            if(tp.dueTaskList.isNotEmpty )
                            buildHeadingContainer("Overdue",true),
                            if(tp.dueTaskList.isNotEmpty )
                            TaskList(tp.dueTaskList),
                            if(tp.todayTaskList.isNotEmpty )
                            buildHeadingContainer("Today", false),
                            if(tp.todayTaskList.isNotEmpty )
                            TaskList(tp.todayTaskList),
                            if(tp.tomorrowTaskList.isNotEmpty )
                            buildHeadingContainer("Tomorrow", false),
                            if(tp.tomorrowTaskList.isNotEmpty )
                            TaskList(tp.tomorrowTaskList),
                            if(tp.thisWeekTaskList.isNotEmpty )
                            buildHeadingContainer("This Week", false),
                            if(tp.thisWeekTaskList.isNotEmpty )
                            TaskList(tp.thisWeekTaskList),
                            if(tp.nextWeekTaskList.isNotEmpty )
                            buildHeadingContainer("Next Week", false),
                            if(tp.nextWeekTaskList.isNotEmpty )
                            TaskList(tp.nextWeekTaskList),
                            if(tp.thisMonthTaskList.isNotEmpty )
                            buildHeadingContainer("This Month", false),
                            if(tp.thisMonthTaskList.isNotEmpty )
                            TaskList(tp.thisMonthTaskList),
                            if(tp.laterTaskList.isNotEmpty )
                            buildHeadingContainer("Later", false),
                            if(tp.laterTaskList.isNotEmpty )
                            TaskList(tp.laterTaskList),
                            if(tp.noDueTaskList.isNotEmpty )
                              buildHeadingContainer("No due", false),
                            if(tp.noDueTaskList.isNotEmpty )
                              TaskList(tp.noDueTaskList),
                          ],
                        ):(tp.completedTaskList.isNotEmpty)?SingleChildScrollView(child: TaskList(tp.completedTaskList)):Center(child: Container(child: Text("N0 task has been completed"),)),
                      ),
                    ),
                  ),
                  if(tp.sortValue=='Date+Priority')
                    Expanded(
                      child: Container(
                        child: Scrollbar(
                          child: (tp.typeValue!="Finished")?ListView(
                            children: [
                              if(tp.veryHighPriorityList.isNotEmpty )
                                Container(
                                  padding: EdgeInsets.only(top: 15,bottom: 5,left: 5),
                                  child: Text(
                                           "Very Important",
                                           style: TextStyle(
                                                     color: Colors.red,
                                           fontSize: 18,
                                                          ),
                                             ),
                                     ),
                              if(tp.veryHighPriorityList.isNotEmpty )
                                TaskList(tp.veryHighPriorityList),
                              if(tp.highPriorityList.isNotEmpty )
                                Container(
                                  padding: EdgeInsets.only(top: 15,bottom: 5,left: 5),
                                  child: Text(
                                    "Important",
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              if(tp.highPriorityList.isNotEmpty )
                                TaskList(tp.highPriorityList),
                              if(tp.moderatePriorityList.isNotEmpty )
                                Container(
                                  padding: EdgeInsets.only(top: 15,bottom: 5,left: 5),
                                  child: Text(
                                    "Moderate",
                                    style: TextStyle(
                                      color: Colors.blue,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              if(tp.moderatePriorityList.isNotEmpty )
                                TaskList(tp.moderatePriorityList),
                              if(tp.lowPriorityList.isNotEmpty )
                                Container(
                                  padding: EdgeInsets.only(top: 15,bottom: 5,left: 5),
                                  child: Text(
                                    "Less Important",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              if(tp.lowPriorityList.isNotEmpty )
                                TaskList(tp.lowPriorityList),
                            ],
                          ):(tp.completedTaskList.isNotEmpty)?SingleChildScrollView(child: TaskList(tp.completedTaskList)):Center(child: Container(child: Text("N0 task has been completed"),)),
                        ),
                      ),
                    ),

                  Container(
                    height: 80,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.purple,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Material(
                            color: Colors.purple,
                            child: AvatarGlow(
                              animate: isListening,
                              glowColor: Colors.white,
                              duration: Duration(milliseconds: 1000),
                              repeatPauseDuration: Duration(milliseconds: 100),
                              repeat: true,
                              endRadius: 25,
                              child: IconButton(
                                icon: FaIcon(FontAwesomeIcons.microphoneAlt,color: Colors.white),
                                onPressed: () {
                                  listen();
                                },
                              ),
                            ),
                          ),
                          Container(
                            height: 60,
                            width: MediaQuery.of(context).size.width * 0.65,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5),
                              color: Colors.white,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(1.0),
                              child: TextField(
                                controller: taskTitleText,
                                decoration:
                                    InputDecoration(labelText: "Add a Quick Task here",errorText: (isTaskTitleValid)?null:"Enter a valid task"),
                                onChanged: (value){
                                  setState(() {

                                    newTask.taskTitle=value;
                                    isTaskTitleValid= true;
                                  });
                                },
                                onSubmitted: (val){
                                  newTask.taskTitle=val;
                                },
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.purple,
                            child: IconButton(
                              icon: FaIcon(
                                FontAwesomeIcons.check,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                submitTask();
                              },
                            ),
                          ),
                        ],
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
