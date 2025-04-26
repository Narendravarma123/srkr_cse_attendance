import 'package:attendance/Data/lists_data.dart';
import 'package:attendance/screens/Event_absent_history.dart';
import 'package:attendance/screens/Faculty_History.dart';
import 'package:attendance/screens/createCredentials.dart';
import 'package:attendance/screens/faculty_registration.dart';
import 'package:attendance/screens/loginpage.dart';
import 'package:attendance/screens/search_by_number.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'Attendace_history.dart';
import 'Displaymembers.dart';
import 'EditBranches.dart';
import 'EditCourses.dart';
import 'Edit_Sections.dart';
import 'Edit_roll_numbers.dart';
import 'Overall_attendance.dart';
// import 'Sending_message.dart';
import 'Timeslots.dart';
import 'admin_home_Screen.dart';
import 'admin_student_numbersearch.dart';
import 'changepassword.dart';
import 'datewise_attendace.dart';

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  State<AdminProfile> createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  String? curr;
  bool isLoading = true; // To track loading state
  String role="";
  final _auth = FirebaseAuth.instance;
  Future<void> fetchUserRole() async {
    try {
      final QuerySnapshot userDocs = await FirebaseFirestore.instance
          .collection('Faculty_Data')
          .where('email', isEqualTo: curr)
          .get();

      if (userDocs.docs.isNotEmpty) {
        final DocumentSnapshot userDoc = userDocs.docs[0];
        setState(() {
          role = userDoc['faculty_status']; // Example field name
          isLoading = false; // Stop loading after role is fetched
        });
      } else {
        setState(() {
          isLoading = false; // Stop loading if no user found
        });
      }
    } catch (error) {
      // Handle any errors here
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    curr = _auth.currentUser!.email;
    fetchUserRole();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xffEEF5FF),
      body: Stack(
        children: [
          SafeArea(
          child: SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topRight: Radius.circular(50.0),topLeft: Radius.circular(50.0),),
              ),
              width: double.infinity,
              margin: EdgeInsets.only(top: 30.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(top: 35.0,left: 25.0),
                    child: TextButton(
                      onPressed: (){
                        Navigator.pop(context);
                      },
                      child: Icon(Icons.arrow_back_ios_rounded, size: 18.0,),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.white),
                        elevation: MaterialStateProperty.all(5.0),
                        shape: MaterialStateProperty.all<CircleBorder>(
                          CircleBorder(),
                        ),
                        shadowColor: MaterialStateProperty.all(Colors.black),
                      ),
                    ),
                  ),

                  Center(
                    child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(26.0), // Set your desired border radius
                            child: Image.network(role==""?"https://www.ecreativeim.com/blog/wp-content/uploads/2011/05/image-not-found.jpg":
                              (role == 'admin'
                                  ? 'https://5.imimg.com/data5/SELLER/Default/2023/3/294997220/ZX/OC/BE/3365461/acrylic-admin-office-door-sign-board.jpg'
                                  : (displayimageURL == ""
                                  ? 'https://images.unsplash.com/photo-1529665253569-6d01c0eaf7b6?q=80&w=1000&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8cHJvZmlsZXxlbnwwfHwwfHx8MA%3D%3D'
                                  : displayimageURL)),
                              width: 140.0,
                              height: 140.0,
                              fit: BoxFit.cover,
                            ),
                          ),
                          SizedBox(height: 20.0,),
                          Text(curr!,
                            style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold,
                            ),),
                          SizedBox(height: 8.0,),
                          Text("$role"),
                          SizedBox(height: 25.0,),
                          Container(
                              margin: EdgeInsets.symmetric(horizontal: 15.0),
                              padding: EdgeInsets.symmetric(vertical: 20.0,horizontal: 15.0),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                                  color: Colors.white,
                                  boxShadow: [BoxShadow(
                                    color: Colors.grey.withOpacity(0.3), // Set the shadow color
                                    spreadRadius: 2, // Set the spread radius of the shadow
                                    blurRadius: 4, // Set the blur radius of the shadow
                                    offset: Offset(0, 3), // Set the offset of the shadow
                                  ),]
                              ),
                              child: Column(
                                children: [
                                  if (role == 'admin' || role == 'HOD') ...[
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return RegPage();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.login_rounded),
                                      title: Text("Faculty Registration"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),
                                    GestureDetector(
                                      onTap: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context){
                                          return DisplayMembers();
                                        }));
                                      },
                                      child: ListTile(
                                        leading: Icon(Icons.login_rounded),
                                        title: Text("Faculty Details"),
                                        trailing: Icon(Icons.arrow_forward_ios_sharp),
                                      ),
                                    ),
                                    Container(
                                      height: 1, // Adjust the height of the line
                                      color: Colors.black.withOpacity(0.2), // Set the color of the line
                                      margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                    ),
                                  ],
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return ChangePassword();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.login_rounded),
                                      title: Text("Change Password"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),
                                  // GestureDetector(
                                  //   onTap: (){
                                  //     Navigator.push(context, MaterialPageRoute(builder: (context){
                                  //       return Admin_History();
                                  //     }));
                                  //   },
                                  //   child: ListTile(
                                  //     leading: Icon(Icons.account_circle),
                                  //     title: Text("Attendance History"),
                                  //     trailing: Icon(Icons.arrow_forward_ios_sharp),
                                  //   ),
                                  // ),
                                  // Container(
                                  //   height: 1, // Adjust the height of the line
                                  //   color: Colors.black.withOpacity(0.2), // Set the color of the line
                                  //   margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  // ),
                                  if (role != 'admin' && role != 'HOD') ...[
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return Faculty_History_Number();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.login_rounded),
                                      title: Text("Search By Number"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),],
                                  if (role != 'admin') ...[
                                    GestureDetector(
                                      onTap: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context){
                                          return Date_wise_attendace();
                                        }));
                                      },
                                      child: ListTile(
                                        leading: Icon(Icons.login_rounded),
                                        title: Text("Date Wise Attendace"),
                                        trailing: Icon(Icons.arrow_forward_ios_sharp),
                                      ),
                                    ),
                                    Container(
                                      height: 1, // Adjust the height of the line
                                      color: Colors.black.withOpacity(0.2), // Set the color of the line
                                      margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                    ),],
                                  if (role == 'HOD') ...[
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return Faculty_History();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.search),
                                      title: Text("Attendance History"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),
                                    GestureDetector(
                                      onTap: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context){
                                          return AdminPage();
                                        }));
                                      },
                                      child: ListTile(
                                        leading: Icon(Icons.search),
                                        title: Text("Today Attendance"),
                                        trailing: Icon(Icons.arrow_forward_ios_sharp),
                                      ),
                                    ),
                                    Container(
                                      height: 1, // Adjust the height of the line
                                      color: Colors.black.withOpacity(0.2), // Set the color of the line
                                      margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                    ),
                                  ],
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        if (role == 'admin' || role == 'HOD') {
                                          return AttendanceHistory(); // or the appropriate widget for admin/hod
                                        } else {
                                          return Faculty_History(); // or the default widget
                                        }
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.search),
                                      title: Text(role=="HOD"?"Department Attendance":"Attendance History"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),
                                  if (role == 'HOD') ...[
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return CreateUserPage();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.account_circle),
                                      title: Text("Create Crendentials"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),],
                                  if (role == 'admin' || role == 'HOD') ...[
                                    GestureDetector(
                                      onTap: (){
                                        Navigator.push(context, MaterialPageRoute(builder: (context){
                                          return EventAttendance();
                                        }));
                                      },
                                      child: ListTile(
                                        leading: Icon(Icons.login_rounded),
                                        title: Text("Events Attendance"),
                                        trailing: Icon(Icons.arrow_forward_ios_sharp),
                                      ),
                                    ),
                                    Container(
                                      height: 1, // Adjust the height of the line
                                      color: Colors.black.withOpacity(0.2), // Set the color of the line
                                      margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                    ),
                                  ],
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return Overall_Attendance();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.login_rounded),
                                      title: Text("OverAll Attendance"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),
    if (role == 'admin' || role == 'HOD') ...[
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return Student_Overall_Attendance();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.login_rounded),
                                      title: Text("Student OverAll Attendance"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),],
    if (role == 'admin' ) ...[
      GestureDetector(
        onTap: (){
          Navigator.push(context, MaterialPageRoute(builder: (context){
            return EditTimeSlots();
          }));
        },
        child: ListTile(
          leading: Icon(Icons.account_circle),
          title: Text("Edit Time Slots"),
          trailing: Icon(Icons.arrow_forward_ios_sharp),
        ),
      ),
      Container(
        height: 1, // Adjust the height of the line
        color: Colors.black.withOpacity(0.2), // Set the color of the line
        margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
      ),
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return EditRollnumbers();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.account_circle),
                                      title: Text("Edit RollNumbers"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return EditCourses();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.account_circle),
                                      title: Text("Edit Courses"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return EditSection();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.account_circle),
                                      title: Text("Edit Sections"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),
                                  GestureDetector(
                                    onTap: (){
                                      Navigator.push(context, MaterialPageRoute(builder: (context){
                                        return EditBranches();
                                      }));
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.account_circle),
                                      title: Text("Edit Branches"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),
                                  Container(
                                    height: 1, // Adjust the height of the line
                                    color: Colors.black.withOpacity(0.2), // Set the color of the line
                                    margin: EdgeInsets.symmetric(vertical: 20), // Adjust the margin if needed
                                  ),],
                                  GestureDetector(
                                    onTap: () async{
                                      SharedPreferences prefs = await SharedPreferences.getInstance();
                                      await prefs.setBool('isLoggedIn', false);
                                      _auth.signOut();
                                      Navigator.of(context).pushAndRemoveUntil(
                                        MaterialPageRoute(builder: (context) => LoginPage()),
                                            (Route<dynamic> route) => false,
                                      );
                                    },
                                    child: ListTile(
                                      leading: Icon(Icons.logout_outlined),
                                      title: Text("Logout"),
                                      trailing: Icon(Icons.arrow_forward_ios_sharp),
                                    ),
                                  ),

                                ],
                              )
                          ),
                          SizedBox(height: 40.0,),
                        ]
                    ),
                  ),

                ],
              ),
            ),
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
        ]
      ),
    );
  }
}
