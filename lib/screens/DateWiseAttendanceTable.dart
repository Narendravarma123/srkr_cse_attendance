import 'package:attendance/Data/lists_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';

class DateWiseAttendanceTable extends StatefulWidget {
  final String department;
  final String year;
  final String section;
  final String course;
  final String academicYear;

  const DateWiseAttendanceTable({
    Key? key,
    required this.department,
    required this.year,
    required this.section,
    required this.course,
    required this.academicYear,
  }) : super(key: key);

  @override
  State<DateWiseAttendanceTable> createState() => _DateWiseAttendanceTableState();
}

class _DateWiseAttendanceTableState extends State<DateWiseAttendanceTable> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  List<String> rollNumbers = [];
  List<Map<String, dynamic>> attendanceData = [];
  List<DateTime> datesToShow = [];
  bool isLoading = true;
  String currentUserEmail = '';

  @override
  void initState() {
    super.initState();
    currentUserEmail = _auth.currentUser!.email!;
    loadData();
  }

  Future<void> loadData() async {
    try {
      // Step 1: Fetch roll numbers for the selected department, year, section
      await fetchRollNumbers();

      // Step 2: Fetch attendance data
      await fetchAttendanceData();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      print("Error loading data: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchRollNumbers() async {
    try {
      final fullDataSnapshot = await _firestore.collection('Full_Data').get();

      for (var doc in fullDataSnapshot.docs) {
        final data = doc.data();
        if (data.containsKey(widget.department) &&
            data[widget.department].containsKey(widget.year) &&
            data[widget.department][widget.year].containsKey(widget.section)) {

          var sectionData = data[widget.department][widget.year][widget.section];
          if (sectionData.containsKey('roll_numbers')) {
            setState(() {
              if (sectionData['roll_numbers'] is List) {
                rollNumbers = List<String>.from(sectionData['roll_numbers']);
              } else if (sectionData['roll_numbers'] is Map) {
                rollNumbers = List<String>.from(sectionData['roll_numbers'].keys);
              }
              rollNumbers.sort(); // Sort roll numbers
            });
          }
          break;
        }
      }
    } catch (e) {
      print("Error fetching roll numbers: $e");
    }
  }

  Future<void> fetchAttendanceData() async {
    try {
      final querySnapshot = await _firestore.collection('Absent_data')
          .where('Department', isEqualTo: widget.department)
          .where('Year', isEqualTo: widget.year)
          .where('Section', isEqualTo: widget.section)
          .where('Course_name', isEqualTo: widget.course)
          .where('Academic_year', isEqualTo: widget.academicYear)
          .where('Faculty', isEqualTo: currentUserEmail)
          .get();

      List<Map<String, dynamic>> tempData = [];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();

        // Convert the Timestamp or String date to DateTime
        DateTime attendanceDate;
        if (data['Date'] is Timestamp) {
          attendanceDate = (data['Date'] as Timestamp).toDate();
        } else if (data['Date'] is String) {
          attendanceDate = DateTime.parse(data['Date']);
        } else {
          continue; // Skip if date format is unknown
        }

        // Convert the Timestamp or String submission to DateTime for sorting
        DateTime submissionDate;
        if (data['Submmission'] is Timestamp) {
          submissionDate = (data['Submmission'] as Timestamp).toDate();
        } else if (data['Submmission'] is String) {
          submissionDate = DateTime.parse(data['Submmission']);
        } else {
          submissionDate = DateTime.now(); // Default if not available
        }

        List<String> absentStudents = [];
        if (data['Absentees'] is List) {
          absentStudents = List<String>.from(data['Absentees']);
        }

        tempData.add({
          'date': attendanceDate,
          'absentStudents': absentStudents,
          'submission': submissionDate,
          'timeSlot': data['Time_slot'] ?? '',
        });
      }

      // Sort by submission date
      tempData.sort((a, b) => a['submission'].compareTo(b['submission']));

      // Extract unique dates for table headers
      Set<DateTime> uniqueDates = {};
      for (var item in tempData) {
        // Only add date part (ignore time)
        DateTime dateOnly = DateTime(
          item['date'].year,
          item['date'].month,
          item['date'].day,
        );
        uniqueDates.add(dateOnly);
      }

      setState(() {
        attendanceData = tempData;
        datesToShow = uniqueDates.toList()..sort();
      });
    } catch (e) {
      print("Error fetching attendance data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(
        child: SpinKitDoubleBounce(
          color: Colors.blue,
          size: 50.0,
        ),
      );
    }

    if (rollNumbers.isEmpty) {
      return Center(
        child: Text('No roll numbers found for the selected criteria'),
      );
    }

    if (datesToShow.isEmpty) {
      return Center(
        child: Text('No attendance data found for the selected criteria'),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          columnSpacing: 20,
          headingRowHeight: 60,
          dataRowHeight: 48,
          border: TableBorder.all(
            color: Colors.grey.shade300,
            width: 1,
          ),
          columns: [
            DataColumn(
              label: Container(
                width: 100,
                child: Text(
                  'Roll Number',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ...datesToShow.map((date) {
              return DataColumn(
                label: Container(
                  width: 100,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('dd-MM-yyyy').format(date),
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      // Find the time slot if available
                      Text(
                        _getTimeSlotForDate(date) ?? '',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
          rows: rollNumbers.map((rollNumber) {
            return DataRow(
              cells: [
                DataCell(
                  Text(rollNumber, style: TextStyle(fontWeight: FontWeight.w500)),
                ),
                ...datesToShow.map((date) {
                  bool isAbsent = _isStudentAbsentOnDate(rollNumber, date);
                  return DataCell(
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isAbsent ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        isAbsent ? 'A' : 'P',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isAbsent ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  bool _isStudentAbsentOnDate(String rollNumber, DateTime date) {
    // Compare only the date part, not the time
    for (var record in attendanceData) {
      DateTime recordDate = DateTime(
        record['date'].year,
        record['date'].month,
        record['date'].day,
      );

      DateTime checkDate = DateTime(
        date.year,
        date.month,
        date.day,
      );

      if (recordDate.isAtSameMomentAs(checkDate)) {
        return record['absentStudents'].contains(rollNumber);
      }
    }
    return false;
  }

  String? _getTimeSlotForDate(DateTime date) {
    for (var record in attendanceData) {
      DateTime recordDate = DateTime(
        record['date'].year,
        record['date'].month,
        record['date'].day,
      );

      DateTime checkDate = DateTime(
        date.year,
        date.month,
        date.day,
      );

      if (recordDate.isAtSameMomentAs(checkDate)) {
        return record['timeSlot'];
      }
    }
    return null;
  }
}