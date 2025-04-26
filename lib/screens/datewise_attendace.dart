import 'package:attendance/Data/lists_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

import 'DateWiseAttendanceTable.dart';

class Date_wise_attendace extends StatelessWidget {
  final GlobalKey<_AttendanceCalState_date_wise> _attendanceCalKey_date = GlobalKey<_AttendanceCalState_date_wise>();
  Date_wise_attendace({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffEEF5FF),
      appBar: AppBar(
        backgroundColor: Color(0xff8db4e7),
        title: Text('Date-wise Attendance'),
      ),
      body: AttendanceCal_date(key: _attendanceCalKey_date),
    );
  }
}

class AttendanceCal_date extends StatefulWidget {
  final GlobalKey<_AttendanceCalState_date_wise> key;
  AttendanceCal_date({required this.key}) : super(key: key);

  @override
  State<AttendanceCal_date> createState() => _AttendanceCalState_date_wise();
}

class _AttendanceCalState_date_wise extends State<AttendanceCal_date> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool isLoading = true;
  bool showTable = false;

  String fetched_Academic_year = "";
  String deptvalue = "Select";
  String yearvalue = "Select";
  String deptback = "";
  String sectionvalue = "Select";
  String coursevalue = "Select";

  List<dynamic> rollNumber = [];
  String curr = "";
  String? role;

  List<dynamic> Sections = ["Select"];
  List<dynamic> branches = ["Select"];
  List<dynamic> courses = ["Select"];

  @override
  void initState() {
    curr = _auth.currentUser!.email!;
    func();
    super.initState();
  }

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
          if(role != "admin"){
            deptback = userDoc['department'];
          }
        });
      }
    } catch (error) {
      print("Error loading faculty data: $error");
    }

    final messages = await _firestore.collection('Dept_data').get();
    for (var message in messages.docs){
      final data = message.data();
      setState(() {
        if (role == "admin") {
          branches = ["Select"] + List<String>.from(data['Branches']);
        } else {
          branches = ["Select", deptback];
        }
        isLoading = false;
      });
    }
  }

  void func1(String deptvalue, String yearvalue) async {
    setState(() {
      showTable = false; // Hide table when changing selections
      Sections = ["Select"];
      courses = ["Select"];
    });

    final messages = await _firestore.collection('Full_Data').get();
    for (var message in messages.docs) {
      var data = message.data();
      if(data.containsKey(deptvalue) && data[deptvalue].containsKey(yearvalue)){
        setState(() {
          Sections = ["Select"] + List<String>.from(data[deptvalue][yearvalue]['section']);
          courses = ["Select"] + List<String>.from(data[deptvalue][yearvalue]['classes']);
          fetched_Academic_year = data[deptvalue][yearvalue]['Academic_year_begins'];
        });
        break;
      }
    }
  }

  void func2(String deptvalue, String yearvalue, String sectionvalue) async {
    setState(() {
      showTable = false; // Hide table when changing selections
    });

    final messages = await _firestore.collection('Full_Data').get();
    for (var message in messages.docs) {
      var data = message.data();
      if(data.containsKey(deptvalue) && data[deptvalue].containsKey(yearvalue)){
        if (data[deptvalue][yearvalue].containsKey(sectionvalue) &&
            data[deptvalue][yearvalue][sectionvalue].containsKey('roll_numbers')) {
          setState(() {
            var rollData = data[deptvalue][yearvalue][sectionvalue]['roll_numbers'];
            rollNumber = rollData is List ? rollData : rollData.keys.toList();
          });
        }
        break;
      }
    }
  }

  bool isValidSelection() {
    return deptvalue != "Select" &&
        yearvalue != "Select" &&
        sectionvalue != "Select" &&
        coursevalue != "Select" &&
        fetched_Academic_year.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SafeArea(
          child: Column(
            children: [
              SizedBox(height: 20.0),
              Container(
                // padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                      DropdownMenu<dynamic>(
                        label: Text("Department"),
                        onSelected: (dynamic? value) {
                          if (value != null && value != "Select") {
                            setState(() {
                              deptvalue = value;
                              yearvalue = "Select";
                              sectionvalue = "Select";
                              coursevalue = "Select";
                              showTable = false;
                            });
                          }
                        },
                        dropdownMenuEntries: branches.map<DropdownMenuEntry<String>>((dynamic value) {
                          return DropdownMenuEntry<String>(value: value, label: value);
                        }).toList(),
                        initialSelection: branches.first,
                        width: 150,
                      ),


                      DropdownMenu<String>(
                        initialSelection: Year.first,
                        label: Text("Year"),
                        onSelected: (String? value) {
                          if (value != null && value != "Select" && deptvalue != "Select") {
                            setState(() {
                              yearvalue = value;
                              sectionvalue = "Select";
                              coursevalue = "Select";
                              showTable = false;
                            });
                            func1(deptvalue, yearvalue);
                          }
                        },
                        dropdownMenuEntries: Year.map<DropdownMenuEntry<String>>((String value) {
                          return DropdownMenuEntry<String>(value: value, label: value);
                        }).toList(),
                        width: 150,
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20.0),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [

                      DropdownMenu<dynamic>(
                        initialSelection: Sections.first,
                        label: Text("Section"),
                        onSelected: (dynamic? value) {
                          if (value != null && value != "Select" &&
                              deptvalue != "Select" && yearvalue != "Select") {
                            setState(() {
                              sectionvalue = value;
                              showTable = false;
                            });
                            func2(deptvalue, yearvalue, sectionvalue);
                          }
                        },
                        dropdownMenuEntries: Sections.map<DropdownMenuEntry<String>>((dynamic value) {
                          return DropdownMenuEntry<String>(value: value, label: value);
                        }).toList(),
                        width: 150,
                      ),

                      DropdownMenu<dynamic>(
                        initialSelection: courses.first,
                        label: Text("Course"),
                        onSelected: (dynamic? value) {
                          if (value != null && value != "Select") {
                            setState(() {
                              coursevalue = value;
                              showTable = false;
                            });
                          }
                        },
                        dropdownMenuEntries: courses.map<DropdownMenuEntry<String>>((dynamic value) {
                          return DropdownMenuEntry<String>(value: value, label: value);
                        }).toList(),
                        width: 150,
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                onPressed: isValidSelection() ? () {
                  setState(() {
                    showTable = true;
                  });
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xff8db4e7),
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                ),
                child: Text(
                  "Generate Attendance Table",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 10.0),
              Expanded(
                child: showTable ?
                DateWiseAttendanceTable(
                  department: deptvalue,
                  year: yearvalue,
                  section: sectionvalue,
                  course: coursevalue,
                  academicYear: fetched_Academic_year,
                ) :
                Center(
                  child: Text(
                    isValidSelection() ?
                    'Click Generate to view attendance data' :
                    'Please select all parameters to view attendance',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
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