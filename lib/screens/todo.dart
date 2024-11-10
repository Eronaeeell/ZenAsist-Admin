import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ToDoApp());
}

class ToDoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ToDoPage(),
    );
  }
}

class ToDoPage extends StatefulWidget {
  @override
  _ToDoPageState createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final CollectionReference<Map<String, dynamic>> tasksCollection =
      FirebaseFirestore.instance.collection('tasks');
  DocumentReference? _currentSessionRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSession();
    logFeatureUsage('todo'); // Log feature utilization for ToDo feature
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _endSession(); // End session when app is backgrounded
    } else if (state == AppLifecycleState.resumed) {
      _startSession(); // Start new session when app resumes
    }
  }

  // Function to log feature usage in Firestore
  void logFeatureUsage(String featureName) {
    FirebaseFirestore.instance
        .collection('stats')
        .doc('featureUtilization')
        .update({
      featureName: FieldValue.increment(1),
    }).catchError((error) {
      print("Failed to log feature usage: $error");
    });
  }

  // Start a new session in Firestore
  void _startSession() async {
    _currentSessionRef =
        await FirebaseFirestore.instance.collection('sessions').add({
      'startTime': FieldValue.serverTimestamp(),
      'endTime': null,
    });
  }

  // End the current session in Firestore
  void _endSession() async {
    if (_currentSessionRef != null) {
      await _currentSessionRef
          ?.update({'endTime': FieldValue.serverTimestamp()});
      _currentSessionRef = null;
    }
  }

  void _addTask(String title) {
    tasksCollection.add({
      'title': title,
      'completed': false,
    });
    _controller.clear();
  }

  void _toggleTask(String id, bool currentStatus) {
    tasksCollection.doc(id).update({'completed': !currentStatus});

    // Update the completion count in Firestore when a task is completed
    if (!currentStatus) {
      FirebaseFirestore.instance
          .collection('stats')
          .doc('taskCompletion')
          .update({'count': FieldValue.increment(1)});
    } else {
      FirebaseFirestore.instance
          .collection('stats')
          .doc('taskCompletion')
          .update({'count': FieldValue.increment(-1)});
    }
  }

  void _deleteTask(String id) {
    tasksCollection.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('To-Do List'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Add a new task',
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (_controller.text.isNotEmpty) {
                      _addTask(_controller.text);
                    }
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: tasksCollection.snapshots(),
                builder: (context,
                    AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>>
                        snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text("Error: ${snapshot.error}"));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text("No tasks found"));
                  }

                  final tasks = snapshot.data!.docs;

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      final taskId = task.id;
                      final taskData = task.data();

                      bool completed = taskData['completed'] ?? false;
                      String title = taskData['title'] ?? '';

                      return ListTile(
                        leading: Checkbox(
                          value: completed,
                          onChanged: (_) => _toggleTask(taskId, completed),
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteTask(taskId),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
