// 1.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TimeTable App',
      theme: ThemeData(
        primaryColor: const Color(0xFF215A8E),
        scaffoldBackgroundColor: const Color(0xFFEAEAEA),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? currentUser;
  Stream<QuerySnapshot>? timetableStream;

  @override
  void initState() {
    super.initState();
    currentUser = _auth.currentUser;

    if (currentUser != null) {
      print("Logged-in UID: ${currentUser!.uid}");

      // ✅ FIX: point to subcollection 'timetable' inside the user's document
      timetableStream = _firestore
          .collection('student')           // top-level collection
          .doc(currentUser!.uid)           // document ID = UID
          .collection('timetable')         // subcollection
          .snapshots();

      // Debug: probe first document
      _firestore
          .collection('student')
          .doc(currentUser!.uid)
          .collection('timetable')
          .limit(1)
          .get()
          .then((snap) {
        if (snap.docs.isNotEmpty) {
          print("Probe Success: Found ${snap.docs.length} doc in timetable");
          print("Probe Doc Data: ${snap.docs.first.data()}");
        } else {
          print("Probe Result: timetable is empty");
        }
      }).catchError((e) {
        print("Probe Error: $e");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF215A8E),
        title: const Text('Welcome User'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.person, color: const Color(0xFF215A8E)),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: const [
            DrawerHeader(
              child:
                  Text('Menu', style: TextStyle(color: Colors.white, fontSize: 20)),
              decoration: BoxDecoration(color: Color(0xFF215A8E)),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'TimeTable',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: currentUser == null || timetableStream == null
                  ? const Center(child: Text("Please log in to see your timetable."))
                  : StreamBuilder<QuerySnapshot>(
                      stream: timetableStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          print("Stream Error: ${snapshot.error}");
                          return Center(
                            child: SelectableText("Error: ${snapshot.error}"),
                          );
                        }
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          print("No timetable fetched.");
                          return const Center(child: Text("No timetable found."));
                        }

                        // Group by Day
                        Map<String, List<QueryDocumentSnapshot>> dayWise = {};
                        for (var doc in snapshot.data!.docs) {
                          String day = doc.get('Day') ?? 'Unknown';
                          if (!dayWise.containsKey(day)) dayWise[day] = [];
                          dayWise[day]!.add(doc);
                        }

                        return ListView(
                          children: dayWise.entries.map((entry) {
                            String day = entry.key;
                            List<QueryDocumentSnapshot> classes = entry.value;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  day.toUpperCase(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                Table(
                                  border: TableBorder.all(color: Colors.grey.shade300),
                                  columnWidths: const {
                                    0: FlexColumnWidth(2),
                                    1: FlexColumnWidth(4),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(3),
                                  },
                                  children: [
                                    TableRow(
                                      decoration:
                                          BoxDecoration(color: Colors.grey.shade200),
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Time',
                                              style:
                                                  TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Course',
                                              style:
                                                  TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Room',
                                              style:
                                                  TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Professor',
                                              style:
                                                  TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    ...classes.map((c) {
                                      return TableRow(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(c.get('time') ?? ''),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(c.get('course') ?? ''),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(c.get('Room') ?? ''),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text(c.get('Professor') ?? ''),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ],
                                ),
                                const SizedBox(height: 20),
                              ],
                            );
                          }).toList(),
                        );
                      },
                    ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF215A8E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {},
                child: const Text(
                  'WHOLE WEEK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
