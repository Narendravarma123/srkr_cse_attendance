import 'package:attendance/Data/lists_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../Data/attendance.dart';

class Overall_Attendance extends StatelessWidget {
  final GlobalKey<_AttendanceCalState> _attendanceCalKey = GlobalKey<_AttendanceCalState>();
  Overall_Attendance({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffEEF5FF),
      appBar: AppBar(
        backgroundColor: Color(0xff8db4e7),
        title: Text('Attendance'),
      ),
      body:AttendanceCal(key: _attendanceCalKey),
      floatingActionButton:FloatingActionButton(onPressed: () async{
        final attendanceCalState = _attendanceCalKey.currentState;
        if (attendanceCalState != null) {
          final pdfFile = await PdfApi.generatePDF(attendanceCalState.deptvalue,attendanceCalState.yearvalue,attendanceCalState.sectionvalue);
          await PdfApi.openFile(pdfFile);
        }

      },
        child: Icon(Icons.download),
      ),
    );
  }
}


class AttendanceCal extends StatefulWidget {
  final GlobalKey<_AttendanceCalState> key;
  AttendanceCal({required this.key}) : super(key: key);

  @override
  State<AttendanceCal> createState() => _AttendanceCalState();
}

class _AttendanceCalState extends State<AttendanceCal> {
  final _firestore = FirebaseFirestore.instance;
  bool isFlag = false;
  String fetched_Academic_year = "";
  String deptvalue = "";
  String yearvalue="";
  String deptback = "";
  String sectionvalue = "";
  List<dynamic> class_list = [];
  String curr="";
  int counter = 0;
  double loader = 0.0;
  int percentageloader = 0;
  List<dynamic> Sections = ["Select"];
  List<dynamic> branches = ["Select"];
  bool isLoading = true; // To track loading state
  String? role;
  final _auth = FirebaseAuth.instance;
  void func() async {
    try {
      final QuerySnapshot userDocs = await FirebaseFirestore.instance
          .collection('Faculty_Data')
          .where('email', isEqualTo: curr)
          .get();

      if (userDocs.docs.isNotEmpty) {
        final DocumentSnapshot userDoc = userDocs.docs[0];
        setState(() {
          role = userDoc['faculty_status'];
          if(role!="admin"){
            deptback = userDoc['department'];
          }
          // Example field name
          // Stop loading after role is fetched
        });
      } else {
        setState(() {
          isLoading = true; // Stop loading if no user found
        });
      }
    } catch (error) {
      // Handle any errors here
      setState(() {
        isLoading = true;
      });
    }
    final messages = await _firestore.collection('Dept_data').get();
    for (var message in messages.docs){
      final data = message.data();
      setState(() {
        role=="admin"?branches =  branches + data['Branches']:branches.add(deptback);
        isLoading = false;
      });
    }
  }


  void func1(String deptvalue, String yearvalue) async {
    final messages = await _firestore.collection('Full_Data').get();
    for (var message in messages.docs) {
      var data = message.data();
      if(data.containsKey(deptvalue) && data[deptvalue].containsKey(yearvalue)){
        setState(() {
          Sections = ["Select"];
          Sections = Sections+ data[deptvalue][yearvalue]['section'];
          fetched_Academic_year = data[deptvalue][yearvalue]['Academic_year_begins'];
        });
        break;
      }
      else{
        continue;
      }
    }
  }
  late Future<List<Datawidget>> lis = Future.value([]);
  Future<List<Datawidget>> gettingClassList(String deptValue, String yearValue, String sectionValue) async {
    List<dynamic> rollNumber = [];
    Map<String, dynamic> full_data = {};
    int totalclassesAttended = 0;
    int? total_classes_completed = 0;
    double total_percentage = 0;

    // Fetch class list and roll numbers
    final messages = await _firestore.collection('Full_Data').get();
    for (var message in messages.docs) {
      if (!isFlag) break;

      var data = message.data();
      if (data.containsKey(deptValue) && data[deptValue].containsKey(yearValue)) {
        setState(() {
          full_data = data;
          class_list = [];
          class_list = class_list + data[deptValue][yearValue]['classes'];
          PdfHeader.clear();
          PdfHeader.add("Roll Numbers");
          PdfHeader = PdfHeader + class_list;
          PdfHeader.add("T.A");
          PdfHeader.add("T.C");
          PdfHeader.add("Total %");
        });
        rollNumber = rollNumber + data[deptValue][yearValue][sectionValue]['roll_numbers'];
        break;
      }
    }

    Map<String, dynamic> courses_details = full_data[deptValue][yearValue][sectionValue]['courses_count'];
    List<Datawidget> messageWidgets = [];
    String AbyCpercentageString = '';

    // Calculate total classes completed
    for (var j in class_list) {
      if (!isFlag) break;
      total_classes_completed = (total_classes_completed! + courses_details[j]['count']) as int?;
    }

    // Process each roll number
    for (var rolls in rollNumber) {
      if (!isFlag) break;

      List<String> AbyClist = [];
      List<String> Percentage = [];
      List<dynamic> StudentStat = [];
      List<String> AbyCwithPercentage = [];
      totalclassesAttended = 0;

      // Fetch student data from student_data_fire collection
      DocumentSnapshot studentDoc = await _firestore.collection('student_data_fire').doc(rolls).get();

      if (studentDoc.exists) {
        Map<String, dynamic> studentData = studentDoc.data() as Map<String, dynamic>;

        // Process each class
        for (var j in class_list) {
          if (!isFlag) break;

          int attended = 0;
          int classcount = courses_details[j]['count'];

          // If this course exists in student data, get the absences
          if (studentData.containsKey(j)) {
            // The value in student data represents absences, so subtract from total
            int absences = studentData[j];
            attended = classcount - absences;
          } else {
            // If no data exists for this course, assume full attendance
            attended = classcount;
          }

          // Ensure attended doesn't go below 0
          attended = attended < 0 ? 0 : attended;

          totalclassesAttended += attended;
          String classesAttended = attended.toString();
          String classesStrcount = classcount.toString();
          String AbyC = "$classesAttended/$classesStrcount";
          AbyClist.add(AbyC);

          if (attended == 0 && classcount == 0) {
            String AbyCpercentage = '0.0';
            Percentage.add(AbyCpercentage);
            AbyCpercentageString = "$AbyC ($AbyCpercentage%)";
          } else {
            double AbyCpercentage = (attended / classcount) * 100;
            String result = AbyCpercentage.toStringAsFixed(2);
            Percentage.add(result);
            AbyCpercentageString = "$AbyC ($result%)";
          }

          AbyCwithPercentage.add(AbyCpercentageString);
        }
      } else {
        // If student document doesn't exist, assume full attendance for all classes
        for (var j in class_list) {
          if (!isFlag) break;

          int classcount = courses_details[j]['count'];
          int attended = classcount; // Full attendance

          totalclassesAttended += attended;
          String classesAttended = attended.toString();
          String classesStrcount = classcount.toString();
          String AbyC = "$classesAttended/$classesStrcount";
          AbyClist.add(AbyC);

          String result = "100.00";
          Percentage.add(result);
          AbyCpercentageString = "$AbyC ($result%)";
          AbyCwithPercentage.add(AbyCpercentageString);
        }
      }

      counter = counter + 1;
      setState(() {
        loader = counter / (rollNumber.length);
        percentageloader = (loader * 100).toInt();
      });

      total_percentage = (totalclassesAttended / total_classes_completed!) * 100;
      String total_percentage_result = total_percentage.toStringAsFixed(2);

      StudentStat.add(rolls);
      StudentStat = StudentStat + AbyCwithPercentage;
      StudentStat.add(totalclassesAttended);
      StudentStat.add(total_classes_completed);
      StudentStat.add(total_percentage_result);
      StudentsData.add(StudentStat);

      final studentdet = Datawidget(
          rolls,
          class_list,
          AbyClist,
          Percentage,
          totalclassesAttended,
          total_classes_completed,
          total_percentage_result
      );
      messageWidgets.add(studentdet);

      if (rollNumber.length == counter) {
        setState(() {
          isFlag = false;
        });
      } else {
        setState(() {
          isFlag = true;
        });
      }
    }

    return messageWidgets;
  }
  // Future<List<Datawidget>> gettingClassList(String deptValue,String YearValue,String sectionvalue) async {
  //   List<dynamic> rollNumber = [];
  //   Map<String, dynamic> full_data = {};
  //   int len=0;
  //   int totalclassesAttended=0;
  //   int attended=0;
  //   int? total_classes_completed=0;
  //   double total_percentage = 0;
  //     final messages = await _firestore.collection('Full_Data').get();
  //     for (var message in messages.docs) {
  //       if(!isFlag){
  //         break;
  //       }
  //       var data = message.data();
  //       if(data.containsKey(deptvalue) && data[deptvalue].containsKey(yearvalue)){
  //         setState(() {
  //           full_data=data;
  //           class_list = [];
  //           class_list = class_list+ data[deptvalue][yearvalue]['classes'];
  //           PdfHeader.clear();
  //           PdfHeader.add("Roll Numbers");
  //           PdfHeader = PdfHeader+class_list;
  //           PdfHeader.add("T.A");
  //           PdfHeader.add("T.C");
  //           PdfHeader.add("Total %");
  //         });
  //         rollNumber = rollNumber+ data[deptvalue][yearvalue][sectionvalue]['roll_numbers'];
  //         break;
  //       }
  //       else{
  //         continue;
  //       }
  //     }
  //     Map<String, dynamic> courses_details = full_data[deptvalue][yearvalue][sectionvalue]['courses_count'];
  //     List<Datawidget> messageWidgets = [];
  //     String AbyCpercentageString ='';
  //     for(var j in class_list){
  //       if(!isFlag){
  //         break;
  //       }
  //       total_classes_completed = (total_classes_completed!+courses_details[j]['count']) as int?;
  //     }
  //     for(var rolls in rollNumber){
  //       if(!isFlag){
  //         break;
  //       }
  //       List<String> AbyClist = [];
  //       List<String> Percentage = [];
  //       List<dynamic> StudentStat = [];
  //       List<String> AbyCwithPercentage = [];
  //       print(rolls);
  //       for(var j in class_list){
  //         len=0;
  //         if(!isFlag){
  //           break;
  //         }
  //         QuerySnapshot querySnapshot = await _firestore.collection('Absent_data')
  //             .where('Department', isEqualTo: deptvalue)
  //             .where('Year',isEqualTo: yearvalue)
  //             .where('Section',isEqualTo: sectionvalue)
  //             .where('Course_name',isEqualTo: j)
  //             .where('Entities',whereIn: [1, 2, 4])
  //             .where('Academic_year',isEqualTo:fetched_Academic_year)
  //             .where('Absentees', arrayContains: rolls)
  //             .get();
  //         for (var doc in querySnapshot.docs) {
  //           // Get the entity value for this document
  //           int entityValue = doc['Entities'];
  //
  //           // Update the length based on the entity value
  //           if (entityValue == 1) {
  //             len += 1;  // Add 1 to len for entity 1
  //           } else if (entityValue == 2) {
  //             len += 2;  // Add 2 to len for entity 2
  //           } else if (entityValue == 4) {
  //             len += 4;  // Add 4 to len for entity 4
  //           }
  //         }
  //         attended = courses_details[j]['count']-len;
  //         totalclassesAttended = totalclassesAttended+attended;
  //         int classcount = courses_details[j]['count'];
  //         String classesAttended = attended.toString();
  //         String classesStrcount = classcount.toString();
  //         String AbyC = classesAttended+"/"+classesStrcount;
  //         AbyClist.add(AbyC);
  //         if(attended==0 && classcount==0){
  //           String AbyCpercentage = '0.0';
  //           Percentage.add(AbyCpercentage);
  //           AbyCpercentageString = AbyC+" ("+AbyCpercentage+"%)";
  //         }
  //         else{
  //           double AbyCpercentage = (attended/classcount)*100;
  //           String result = AbyCpercentage.toStringAsFixed(2);
  //           Percentage.add(result);
  //           AbyCpercentageString = AbyC+" ("+result+"%)";
  //         }
  //         AbyCwithPercentage.add(AbyCpercentageString);
  //       }
  //       if(!isFlag){
  //         break;
  //       }
  //       counter = counter+1;
  //       setState(() {
  //         loader = counter/(rollNumber.length);
  //         percentageloader = (loader*100).toInt();
  //       });
  //       total_percentage = (totalclassesAttended/total_classes_completed!)*100;
  //       String total_percentage_result = total_percentage.toStringAsFixed(2);
  //       StudentStat.add(rolls);
  //       StudentStat=StudentStat+AbyCwithPercentage;
  //       StudentStat.add(totalclassesAttended);
  //       StudentStat.add(total_classes_completed);
  //       StudentStat.add(total_percentage_result);
  //       StudentsData.add(StudentStat);
  //
  //       final studentdet = Datawidget(rolls,class_list,AbyClist,Percentage,totalclassesAttended,total_classes_completed,total_percentage_result);
  //       messageWidgets.add(studentdet);
  //       totalclassesAttended=0;
  //
  //       if(rollNumber.length == counter){
  //         print(counter);
  //         setState(() {
  //           isFlag = false;
  //         });
  //       }
  //       else{
  //         setState(() {
  //           isFlag = true;
  //         });
  //       }
  //     }
  //     return messageWidgets;
  // }
  @override
  void initState() {
    curr = _auth.currentUser!.email!;
    func();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [SafeArea(
        child: Column(
          children: [
            SizedBox(height: 30.0),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownMenu<dynamic>(
                    label: Text("Department"),
                    onSelected: (dynamic? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        deptvalue = value!;
                      });
                    },
                    dropdownMenuEntries: branches.map<DropdownMenuEntry<String>>((dynamic value) {
                      return DropdownMenuEntry<String>(value: value, label: value);
                    }).toList(),
                    initialSelection: branches.first,
                  ),
                  DropdownMenu<String>(
                    initialSelection: Year.first,
                    label: Text("Year"),
                    onSelected: (String? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        yearvalue = value!;

                        func1(deptvalue,yearvalue);
                      });
                    },
                    dropdownMenuEntries: Year.map<DropdownMenuEntry<String>>((String value) {
                      return DropdownMenuEntry<String>(value: value, label: value);
                    }).toList(),
                  ),

                ],
              ),
            ),
            SizedBox(height: 20.0),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownMenu<dynamic>(
                    initialSelection: Sections.first,
                    label: Text("Section"),
                    onSelected: (dynamic? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        sectionvalue = value!;
                      });
                    },
                    dropdownMenuEntries: Sections.map<DropdownMenuEntry<String>>((dynamic value) {
                      return DropdownMenuEntry<String>(value: value, label: value);
                    }).toList(),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextButton(
                      onPressed: (){
                        setState(() {
                          loader = 0.0;
                          percentageloader = 0;
                          counter = 0;
                          PdfHeader.clear();
                          StudentsData.clear();
                          if(isFlag){
                            isFlag = false;
                          }
                          else{
                            isFlag = true;
                          }
                          lis = gettingClassList(deptvalue,yearvalue,sectionvalue);

                        });
                       },
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            isFlag?Icon(Icons.cancel):Icon(Icons.search),
                            SizedBox(width: 10.0,),
                            isFlag?Text("Cancel",):Text("Search",),
                          ]
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Color(0xff2D3250)),
                        minimumSize: MaterialStateProperty.all(Size(150.0, 65.0)),
                        foregroundColor: MaterialStateProperty.all(Colors.white),
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10.0,),
            Expanded(
              child: FutureBuilder<List<Datawidget>>(
                future: lis,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    // Return a loading indicator while waiting for the future
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [CircularProgressIndicator(
                          value: loader,
                          backgroundColor: Colors.grey,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                          SizedBox(height: 10.0,),
                          Text('Fetched: $percentageloader%'),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    // Return an error message if the future fails
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else {
                    // Return the ListView once the future completes
                    List<Datawidget>? data = snapshot.data;
                    if (data != null && data.isNotEmpty) {
                      return ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return data[index];
                        },
                      );
                    } else {
                      // Return a message if there's no data
                      return Center(
                        child: Text('No data available'),
                      );
                    }
                  }
                },
              ),
            ),

          ],
        ),
      ),
        if (isLoading) ...[
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.5),
          ),
          Center(
            child: SpinKitDoubleBounce(
              color: Colors.white,
              size: 50.0,
            ),
          ),
        ],
      ],
    );
  }
}

class Datawidget extends StatelessWidget {
  final String rolls;
  final List<dynamic> class_list;
  final List<String> AbyClist1; // Changed from AbyClist
  final List<String> Percentage1; // Changed from Percentage
  final int totalclassesAttended;
  final int total_classes_completed;
  final String total_percentage;
  Datawidget(this.rolls,this.class_list,this.AbyClist1,this.Percentage1,this.totalclassesAttended,this.total_classes_completed,this.total_percentage);
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10.0,horizontal: 23.0),
      padding: EdgeInsets.symmetric(vertical: 20.0,horizontal: 25.0),
      decoration: BoxDecoration(
        color: Color(0xffb9cdef),
        borderRadius: BorderRadius.all(Radius.circular(20.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 5.0),
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.user, color: Colors.blueAccent,size: 16.0,),
                    SizedBox(width: 4.0,),
                    Text('Roll number: $rolls',
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),]
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(5.0)),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: class_list.map((classes) => Text(classes,style: TextStyle(
                  fontSize: 16.0,
                ),)).toList(),
              ),
              Column(
                children: AbyClist1.map((classes) => Text(classes,style: TextStyle(
                  fontSize: 16.0,
                ),)).toList(),
              ),
              Column(
                children: Percentage1.map((classes) => Text(classes.toString(),style: TextStyle(
                  fontSize: 16.0,
                ),)).toList(),
              ),
            ],
          ),
          SizedBox(height: 40.0,),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Column(
                children: [

                  Container(
                    padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 5.0),

                    child: Text(totalclassesAttended.toString(),
                      style: TextStyle(
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                  ),
                  Text("Attended"),
                ],
              ),
              Column(
                children: [

                  Container(
                    padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 5.0),
                    child: Text(total_classes_completed.toString(),style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.all(Radius.circular(5.0)),
                    ),
                  ),
                  Text("Conducted"),
                ],
              ),
              Column(
                children: [
                  CircularPercentIndicator(
                      radius: 55.0,
                      lineWidth: 12.0,
                    percent: double.parse(total_percentage)/100,
                    progressColor: Color(0xff8db4e7),
                    backgroundColor: Color(0xffEEF5FF),
                    circularStrokeCap: CircularStrokeCap.round,
                    center: Text('$total_percentage %',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12.0),),

                  ),
                  SizedBox(height: 15.0,),
                  // Container(
                  //   padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 5.0),
                  //   child: Text(total_percentage.toString(),style: TextStyle(
                  //       fontWeight: FontWeight.bold
                  //   ),),
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.all(Radius.circular(5.0)),
                  //   ),
                  // ),
                  Text("Percentage"),
                ],
              ),

            ],
          ),

        ],
      ),
    );
  }
}
