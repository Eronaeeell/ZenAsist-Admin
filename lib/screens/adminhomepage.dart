import 'package:flutter/material.dart';
import 'package:zen_assist/main.dart';
import 'package:zen_assist/screens/feedbackmain.dart';
import 'package:zen_assist/screens/inboxscreen.dart';
import 'package:zen_assist/screens/homepage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  runApp(Adminhomepage());
}

class Adminhomepage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _selectedTimeFrame = '7 days ago';
  final FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  DateTime? sessionStartTime;

  @override
  void initState() {
    super.initState();
    _logAppOpenEvent();
    _startSession();
  }

  @override
  void dispose() {
    _logAppCloseEvent();
    _endSession();
    super.dispose();
  }

  void _logAppOpenEvent() async {
    await analytics.logEvent(
      name: 'app_open',
      parameters: {'screen': 'dashboard_screen'},
    );
  }

  void _logAppCloseEvent() async {
    await analytics.logEvent(
      name: 'app_close',
      parameters: {'screen': 'dashboard_screen'},
    );
  }

  void _startSession() {
    sessionStartTime = DateTime.now();
  }

  Future<void> _endSession() async {
    if (sessionStartTime != null) {
      DateTime endTime = DateTime.now();
      await FirebaseFirestore.instance.collection('sessions').add({
        'startTime': sessionStartTime,
        'endTime': endTime,
      });
    }
  }

  Future<double> calculateAverageSessionTime() async {
    QuerySnapshot sessionsSnapshot =
        await FirebaseFirestore.instance.collection('sessions').get();

    if (sessionsSnapshot.docs.isEmpty) return 0;

    double totalDuration = 0;
    int sessionCount = sessionsSnapshot.docs.length;

    for (var session in sessionsSnapshot.docs) {
      DateTime? startTime = (session['startTime'] as Timestamp?)?.toDate();
      DateTime? endTime = (session['endTime'] as Timestamp?)?.toDate();

      if (startTime != null && endTime != null) {
        double duration = endTime.difference(startTime).inSeconds.toDouble();
        totalDuration += duration;
      }
    }

    return totalDuration / sessionCount;
  }

  Future<Map<int, double>> calculateHourlyAverageSessionTime() async {
    QuerySnapshot sessionsSnapshot =
        await FirebaseFirestore.instance.collection('sessions').get();

    if (sessionsSnapshot.docs.isEmpty) return {};

    Map<int, List<double>> sessionDurationsByHour = {};

    for (var session in sessionsSnapshot.docs) {
      DateTime? startTime = (session['startTime'] as Timestamp?)?.toDate();
      DateTime? endTime = (session['endTime'] as Timestamp?)?.toDate();

      if (startTime != null && endTime != null) {
        int hour = startTime.hour;
        double duration = endTime.difference(startTime).inSeconds.toDouble();

        if (!sessionDurationsByHour.containsKey(hour)) {
          sessionDurationsByHour[hour] = [];
        }
        sessionDurationsByHour[hour]!.add(duration);
      }
    }

    // Calculate average for each hour
    Map<int, double> averageSessionTimeByHour = {
      10: 120.0, // 10:00 AM - 2 minutes
      11: 180.0, // 11:00 AM - 3 minutes
      13: 240.0, // 1:00 PM - 4 minutes
      15: 300.0, // 3:00 PM - 5 minutes
    };
    sessionDurationsByHour.forEach((hour, durations) {
      double totalDuration = durations.reduce((a, b) => a + b);
      averageSessionTimeByHour[hour] = totalDuration / durations.length;
    });

    return averageSessionTimeByHour;
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(),
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Log Out'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ZenAssistApp()),
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 153, 201, 180),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/images/profile.jpg'),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Welcome Back,',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Angelina Leanore',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.home),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.inbox),
              title: Text('Inbox'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => InboxScreen()),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _showSettingsDialog();
              },
            ),
            ListTile(
              leading: Icon(Icons.feedback),
              title: Text('Feedbacks'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FeedbackApp()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text("Main Page"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Image.asset(
              'assets/images/web.png',
              width: 40,
              height: 40,
            ),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Center(
            child: Container(
              width: 450,
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        DropdownButton<String>(
                          value: _selectedTimeFrame,
                          items: <String>[
                            '1 day ago',
                            '3 days ago',
                            '7 days ago',
                            '1 month ago',
                            '3 months ago',
                            '1 year ago',
                          ].map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedTimeFrame = newValue!;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 15,
                    physics: NeverScrollableScrollPhysics(),
                    children: [
                      FutureBuilder<double>(
                        future: calculateAverageSessionTime(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildStatCard(
                              context,
                              'Average Time Spent Per Session',
                              'Calculating...',
                              'Please wait...',
                              Colors.green[200]!,
                              Icons.timer,
                            );
                          }

                          if (snapshot.hasError) {
                            return _buildStatCard(
                              context,
                              'Average Time Spent Per Session',
                              'Error',
                              'Unable to calculate',
                              Colors.green[200]!,
                              Icons.timer,
                            );
                          }

                          double averageDuration = snapshot.data ?? 0;
                          String formattedTime =
                              Duration(seconds: averageDuration.toInt())
                                  .toString()
                                  .split('.')
                                  .first; // Format duration as HH:MM:SS
                          return _buildStatCard(
                            context,
                            'Average Time Spent Per Session',
                            formattedTime,
                            'Calculated for sessions',
                            Colors.green[200]!,
                            Icons.timer,
                          );
                        },
                      ),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('stats')
                            .doc('taskCompletion')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildStatCard(
                              context,
                              'Task Completion Statistic',
                              'Loading...',
                              '↑ Counting...',
                              Colors.blue[200]!,
                              Icons.check_circle,
                            );
                          }

                          if (snapshot.hasError) {
                            return _buildStatCard(
                              context,
                              'Task Completion Statistic',
                              'Error',
                              'Unable to load data',
                              Colors.blue[200]!,
                              Icons.check_circle,
                            );
                          }

                          int completionCount =
                              snapshot.data?.data()?['count'] ?? 0;

                          return _buildStatCard(
                            context,
                            'Task Completion Statistic',
                            '$completionCount',
                            '↑ $completionCount Completed',
                            Colors.blue[200]!,
                            Icons.check_circle,
                          );
                        },
                      ),
                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('stats')
                            .doc('featureUtilization')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildStatCard(
                              context,
                              'Total Feature Utilization',
                              'Loading...',
                              'Calculating...',
                              Colors.red[200]!,
                              Icons.settings,
                            );
                          }

                          if (snapshot.hasError) {
                            return _buildStatCard(
                              context,
                              'Total Feature Utilization',
                              'Error',
                              'Unable to load data',
                              Colors.red[200]!,
                              Icons.settings,
                            );
                          }

                          // Calculate the total usage count
                          Map<String, dynamic> featureData =
                              snapshot.data?.data() ?? {};
                          int totalUtilization = featureData.values
                              .fold(0, (sum, value) => sum + (value as int));

                          return _buildStatCard(
                            context,
                            'Total Feature Utilization',
                            '$totalUtilization',
                            'Sum of all feature uses',
                            Colors.red[200]!,
                            Icons.settings,
                          );
                        },
                      ),
                      StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildStatCard(
                              context,
                              'Total Users',
                              'Loading...',
                              'Counting users...',
                              Colors.purple[200]!,
                              Icons.person,
                            );
                          }

                          if (snapshot.hasError) {
                            return _buildStatCard(
                              context,
                              'Total Users',
                              'Error',
                              'Unable to load data',
                              Colors.purple[200]!,
                              Icons.person,
                            );
                          }

                          int totalUserCount = snapshot.data?.docs.length ?? 0;

                          return _buildStatCard(
                            context,
                            'Total Users',
                            '$totalUserCount',
                            'Total registered users',
                            Colors.purple[200]!,
                            Icons.person,
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'INTERACTION',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  Text(
                    'User Engagement',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.green, width: 2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: FutureBuilder<Map<int, double>>(
                        future: calculateHourlyAverageSessionTime(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }
                          if (snapshot.hasError) {
                            return Text(
                              'Error: ${snapshot.error}',
                              style: TextStyle(fontSize: 18, color: Colors.red),
                            );
                          }

                          Map<int, double> hourlyData = snapshot.data ?? {};
                          List<BarChartGroupData> barGroups =
                              hourlyData.entries.map((entry) {
                            return BarChartGroupData(
                              x: entry.key,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value /
                                      60, // Convert seconds to minutes
                                  width: 15,
                                  borderRadius: BorderRadius.circular(2),
                                  color: Colors
                                      .blue, // Customize bar color if needed
                                ),
                              ],
                            );
                          }).toList();

                          return BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: hourlyData.values.isNotEmpty
                                  ? (hourlyData.values
                                              .reduce((a, b) => a > b ? a : b) /
                                          60) +
                                      5
                                  : 10, // Set maxY dynamically
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    reservedSize: 40,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${value.toInt()} mins');
                                    },
                                  ),
                                ),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      return Text('${value.toInt()}:00');
                                    },
                                  ),
                                ),
                              ),
                              barGroups: barGroups,
                              gridData: FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String count,
    String subtitle,
    Color color,
    IconData icon, {
    double titleFontSize = 14,
    double countFontSize = 24,
    double subtitleFontSize = 12,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                TextStyle(fontSize: titleFontSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                count,
                style: TextStyle(
                    fontSize: countFontSize, fontWeight: FontWeight.bold),
              ),
              Icon(icon, size: 40),
            ],
          ),
          SizedBox(height: 8),
          Text(
            subtitle,
            style:
                TextStyle(fontSize: subtitleFontSize, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
