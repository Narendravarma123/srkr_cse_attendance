
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../Data/lists_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:quickalert/quickalert.dart';

import 'faculty_main_screen.dart';
class Topsection extends StatefulWidget {
  const Topsection({super.key});

  @override
  State<Topsection> createState() => _TopsectionState();
}
class _TopsectionState extends State<Topsection> {
  final _firestore = FirebaseFirestore.instance;

  int? parse_time;
  String? Curr;
  String deptvalue = "";
  String yearvalue="";
  String fetched_Academic_year = "";
  String sectionvalue = "";
  String course_value = "";
  String Timeslot_value = "";
  String today_Date = "";
  bool checked = false;
  Map<String, dynamic> fulldata = {};
  List<dynamic> courses = ["Select"];
  late DocumentReference ref;
  List<dynamic> Sections = ["Select"];
  List<dynamic> branches = ["Select"];
  List<dynamic> register_no = [];
  List<dynamic> Timeslots = ["Select"];
  String greeting='';
  String username='';
  List<Register_format> reg_with_check = [];
  void func() async {
    setState(() {
      final _auth = FirebaseAuth.instance;
      Curr = _auth.currentUser!.email;
      today_Date = DateFormat('dd-MM-yyyy').format(DateTime.now());
      int hour = DateTime.now().hour;
      if (hour < 12) {
        greeting = 'Good Morning...';
      } else if (hour < 17) {
        greeting = 'Good Afternoon...';
      } else {
        greeting = 'Good Evening...';
      }
    });
    if (Curr != null) {
      // Fetch the username from another collection using the current user's email
      final querySnapshot = await _firestore
          .collection('Faculty_Data')
          .where('email', isEqualTo: Curr)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          username = querySnapshot.docs.first.data()['Username'] ?? 'No Username';
        });
      }
    }
    final messages = await _firestore.collection('Dept_data').get();
    for (var message in messages.docs){
      final data = message.data();
      setState(() {
        branches =  branches + data['Branches'];
      });
    }
  }
  int calculateEntities(String timeSlot, int parsingTime) {

    List<String> times = timeSlot.split(' - '); // Split the time slot string

    // // Parse the start and end times
    DateFormat customFormat = DateFormat("HH:mm");
    DateTime startTime = customFormat.parse(times[0].trim());
    DateTime endTime = customFormat.parse(times[1].trim());
    //
    // // Calculate the duration in minutes
    int durationInMinutes = endTime.difference(startTime).inMinutes;

    // Calculate the number of entities by dividing the duration by the parsing time
    int entities = (durationInMinutes / parsingTime).floor();
    // return entities;
    return entities;
  }


  void func1(String deptvalue, String yearvalue) async {
    final messages = await _firestore.collection('Full_Data').get();
    for (var message in messages.docs) {
       var data = message.data();

       if(data.containsKey(deptvalue) && data[deptvalue].containsKey(yearvalue)){
         setState(() {
           ref = message.reference;
           courses = ["Select"];
           Sections = ["Select"];
           fulldata = data;
           courses = courses+ fulldata[deptvalue][yearvalue]['classes'];
           Sections = Sections+ fulldata[deptvalue][yearvalue]['section'];
           fetched_Academic_year = data[deptvalue][yearvalue]['Academic_year_begins'];
         });
         break;
       }
       else{
         continue;
       }
    }
  }
  void func2 (String deptvalue,String yearvalue,String sectionvalue) async {
      setState(() {
         register_no = fulldata[deptvalue][yearvalue][sectionvalue]['roll_numbers'];
      });
      final messages = await _firestore.collection('Dept_data').get();
      for (var message in messages.docs){
        final data = message.data();
        setState(() {
          Timeslots = ["Select"];
          Timeslots =  Timeslots + data['Time-Slots'];
          parse_time = data['parsing_time'];
        });
      }
  }
  void calling_numbers(){
    reg_with_check.clear();
    for(var i=0;i<register_no.length;i++){
      reg_with_check.add(Register_format(register_no[i]));
    }
  }

  List<String> checkOverlappingSlots(List<dynamic> timeSlots, String selectedSlot) {
    List<String> selectedTimes = selectedSlot.split(' - ');
    DateTime selectedStartTime = _parseTime(selectedTimes[0]);
    DateTime selectedEndTime = _parseTime(selectedTimes[1]);

    List<String> overlappingSlots = [];

    for (String slot in timeSlots) {
      List<String> times = slot.split(' - ');
      DateTime startTime = _parseTime(times[0]);
      DateTime endTime = _parseTime(times[1]);

      // Check if the slot is within the selected time range
      // Check if the slot is within the selected time range
      if (startTime.isAfter(selectedStartTime) && endTime.isBefore(selectedEndTime) ||
          startTime.isAtSameMomentAs(selectedStartTime) && endTime.isBefore(selectedEndTime) ||
          startTime.isAfter(selectedStartTime) && endTime.isAtSameMomentAs(selectedEndTime) ||
          startTime.isAtSameMomentAs(selectedStartTime) && endTime.isAtSameMomentAs(selectedEndTime)) {
        overlappingSlots.add(slot);
      }

      // Check if the selected slot is within the current slot (encompassing case)
      if (startTime.isBefore(selectedStartTime) && endTime.isAfter(selectedEndTime) ||
          startTime.isAtSameMomentAs(selectedStartTime) && endTime.isAfter(selectedEndTime) ||
          startTime.isBefore(selectedStartTime) && endTime.isAtSameMomentAs(selectedEndTime)) {
        overlappingSlots.add(slot);
      }
    }
    return overlappingSlots;
  }

  DateTime _parseTime(String time) {
    List<String> parts = time.split(':');
    int hour = int.parse(parts[0]);
    int minute = int.parse(parts[1]);
    int currentYear = DateTime.now().year;
    return DateTime(currentYear, 1, 1, hour, minute); // You can ignore the date, it's just a placeholder.
  }


  @override
  void initState() {
    func();
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double padding = screenWidth * 0.05; // Adjust as needed
    double fontSize = screenWidth * 0.05; // Adjust as needed
    return SafeArea(
      child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.fromLTRB(padding, padding, 0.0, 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: Color(0xffffffff),
                      ),
                    ),
                    SizedBox(height: 8.0), // Add space between the texts
                    Text(
                      username, // Replace with your desired text
                      style: TextStyle(
                        fontWeight:FontWeight.bold,
                        fontSize: fontSize * 1.25,
                        color: Color(0xffffffff),
                      ),
                    ),
                  ],
                ),
              ),
            ),


            SizedBox(height: 30.0),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text("Date:- $today_Date",),
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
                ],
              ),
            ),
            SizedBox(height: 20.0),
            Container(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
                  DropdownMenu<dynamic>(
                    initialSelection: Sections.first,
                    label: Text("Section"),
                    onSelected: (dynamic? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        sectionvalue = value!;

                        func2(deptvalue,yearvalue,sectionvalue);

                      });
                    },
                    dropdownMenuEntries: Sections.map<DropdownMenuEntry<String>>((dynamic value) {
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
                  DropdownMenu <dynamic> (
                    initialSelection: Year.first,
                    label: Text("Courses"),
                    onSelected: (dynamic? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        course_value = value!;
                      });
                    },
                    dropdownMenuEntries: courses.map<DropdownMenuEntry<dynamic>>((dynamic value) {
                      return DropdownMenuEntry<String>(value: value, label: value);
                    }).toList(),
                  ),
                  DropdownMenu<dynamic>(
                    menuHeight: 250.0,
                    initialSelection: Timeslots.first,
                    label: Text(
                      "Time-Slot"
                    ),
                    onSelected: (dynamic? value) {
                      // This is called when the user selects an item.
                      setState(() {
                        Timeslot_value = value!;
                        calling_numbers();
                      });
                    },
                    dropdownMenuEntries: Timeslots.map<DropdownMenuEntry<dynamic>>((dynamic value) {
                      return DropdownMenuEntry<String>(value: value, label: value);
                    }).toList(),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.0),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 30.0,top: 10.0,right: 37.0,bottom: 0.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30.0),topRight: Radius.circular(30.0)),
                  color: Colors.white,
                ),
                child: Register_numbers(reg_with_check),
              ),
            ),
            GestureDetector(
              onTap: ()=> showDialog(
                context: context,
                builder: (BuildContext context)=> AlertDialog(
                  title: Text("Attendance"),
                  content: Text("Are you sure you want to submit"),
                  actions: [
                    TextButton(onPressed: (){
                      Navigator.pop(context);
                    },
                        child: Text("Cancel")
                    ),
                    TextButton(onPressed: ()async{
                      List<String> overlappingSlots = checkOverlappingSlots(Timeslots.sublist(1),Timeslot_value);
                      DateTime date = DateFormat('dd-MM-yyyy').parse(today_Date);
                      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
                      final normalquerySnapshot = await FirebaseFirestore.instance
                          .collection('Absent_data')
                          .where('Date', isEqualTo: formattedDate)
                          .where('Department', isEqualTo: deptvalue)
                          .where('Year', isEqualTo: yearvalue)
                          .where('Section', isEqualTo: sectionvalue)
                          .where('Time_slot', isEqualTo: Timeslot_value)
                          .get();
                      if (normalquerySnapshot.docs.isEmpty){
                        for(var i in overlappingSlots){
                          final querySnapshot = await FirebaseFirestore.instance
                              .collection('event_attendance')
                              .where('Date', isEqualTo: formattedDate)
                              .where('Department', isEqualTo: deptvalue)
                              .where('Year', isEqualTo: yearvalue)
                              .where('Section', isEqualTo: sectionvalue)
                              .where('Time_slot', isEqualTo: i)
                              .get();
                          if (querySnapshot.docs.isNotEmpty){

                            for (var doc in querySnapshot.docs) {
                              // Retrieve the 'Present' list from the document
                              List<dynamic> presentList = doc['Present'];

                              // Remove the present roll numbers from the absent list
                              absent_numbers.removeWhere((absentRoll) => presentList.contains(absentRoll));

                              // Optional: If you need to update the 'Absent' list in Firestore
                            }
                          }
                        }
                        absent_numbers.sort();
                        int entities = calculateEntities(Timeslot_value,parse_time!);
                        await _firestore.collection("Absent_data").add({
                          'Submission':FieldValue.serverTimestamp(),
                          'Department': deptvalue,
                          'Year':yearvalue,
                          "Section":sectionvalue,
                          'Date':formattedDate,
                          'Time_slot':Timeslot_value,
                          'Faculty':'$Curr',
                          'Course_name':course_value,
                          'Absentees':absent_numbers,
                          'checked':checked,
                          'edited':false,
                          'Academic_year':fetched_Academic_year,
                          'Entities':entities,
                        });
                        // Update student_data_fire for each absentee
                        for (String roll in absent_numbers) {
                          final studentRef = FirebaseFirestore.instance.collection('student_data_fire').doc(roll);
                          final studentSnap = await studentRef.get();

                          if (studentSnap.exists) {
                            final studentData = studentSnap.data() as Map<String, dynamic>;

                            // Get current entity count for the course or set to 0
                            int current = studentData[course_value] ?? 0;
                            print(roll);
                            print(current);
                            print(entities);
                            // Add new entities to existing value
                            await studentRef.update({
                              course_value: current + entities,
                            });
                          } else {
                            // If doc doesn't exist, create it
                            await studentRef.set({
                              course_value: entities,
                            });
                          }
                        }

                        final count = fulldata[deptvalue][yearvalue][sectionvalue]['courses_count'][course_value]['count'];
                        final entity_list = fulldata[deptvalue][yearvalue][sectionvalue]['courses_count'][course_value]['entity_list'];
                        if(!entity_list.contains(entities)){
                          entity_list.add(entities);
                        }
                        await ref.update({
                          '$deptvalue.$yearvalue.$sectionvalue.courses_count.$course_value': {
                            'count': count+entities,
                            'entity_list': entity_list,
                          }
                        }).then((_) {
                          print("$count added successfully!");
                        }).catchError((error) {
                          print("Failed to add $count: $error");
                        });
                        setState(() {
                          absent_numbers.clear();
                        });
                        QuickAlert.show(
                          context: context,
                          type: QuickAlertType.success,
                          text: 'Attendance Submitted Successfully!',
                          onConfirmBtnTap: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
                              return Faculty_main();
                            }));
                          },
                        );
                      }
                      else{
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Attendance already given',style: TextStyle(
                            color: Colors.red,
                          ),)),
                        );
                        Navigator.pop(context);
                      }




      },  child: Text("Submit")),
                  ],
                )
              ),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 20.0),
                child: Text("Submit Attendance",
                style: TextStyle(
                  fontSize: 22.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),),
              ),
            ),
          ],
        ),
    );
  }
}


class Register_numbers extends StatefulWidget {
  final List<Register_format> registers;
  Register_numbers(this.registers);

  @override
  State<Register_numbers> createState() => _Register_numbersState();
}

class _Register_numbersState extends State<Register_numbers> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context,index){
        return RegisterTile(widget.registers[index].rollno,widget.registers[index].isDone,(checkstate){
          // print();
          // print(checkstate);
          setState(() {
            widget.registers[index].toggleDone();
            if(checkstate==true){
              absent_numbers.add(widget.registers[index].rollno);
            }
            else{
              absent_numbers.remove(widget.registers[index].rollno);
            }

          });
        },
        );
      },
      itemCount: widget.registers.length,
    );
  }
}

class RegisterTile extends StatelessWidget {

  final String register_number;
  final bool isChecked;
  final void Function(bool?)? checkboxcallback;
  RegisterTile(this.register_number,this.isChecked,this.checkboxcallback);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Container(

        child: Text(
          register_number,
          style: TextStyle(
            decoration: isChecked? TextDecoration.lineThrough:null,
            fontSize: 18.0,
          ),
        ),
      ),
      trailing: Checkbox(
        activeColor: Colors.lightBlueAccent,
        value: isChecked,
        onChanged:checkboxcallback,
      ),

    );
  }
}






