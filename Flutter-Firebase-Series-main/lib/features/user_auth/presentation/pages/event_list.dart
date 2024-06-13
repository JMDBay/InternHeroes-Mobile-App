import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EventList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentDate = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Events',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('events').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }

          final events = snapshot.data!.docs;

          if (events.isEmpty) {
            return Center(
              child: Text('No events available.'),
            );
          }

          events.sort((a, b) {
            final aDate = (a['eventDateTime'] as Timestamp).toDate();
            final bDate = (b['eventDateTime'] as Timestamp).toDate();
            return aDate.compareTo(bDate);
          });

          final upcomingEvents = events.where((event) {
            final eventDateTime = (event['eventDateTime'] as Timestamp).toDate();
            return eventDateTime.isAfter(currentDate) && (event['isPublic'] || event['createdBy'] == FirebaseAuth.instance.currentUser!.uid);
          }).toList();

          if (upcomingEvents.isEmpty) {
            return Center(
              child: Text('No upcoming events.'),
            );
          }

          return GroupedListView<dynamic, DateTime>(
            elements: upcomingEvents,
            groupBy: (element) {
              final eventDateTime = (element['eventDateTime'] as Timestamp).toDate();
              return DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);
            },
            groupSeparatorBuilder: (DateTime date) {
              return ListTile(
                title: Text(
                  '${_formatDate(date)}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            },itemBuilder: (context, dynamic element) {
            final createdBy = element['createdBy'];
            final eventDateTime = (element['eventDateTime'] as Timestamp).toDate();
            final eventDescription = element['eventDescription'];
            final eventName = element['eventName'];
            final eventDate = DateTime(eventDateTime.year, eventDateTime.month, eventDateTime.day);
            final eventTime = TimeOfDay.fromDateTime(eventDateTime);
            final isPublic = element['isPublic'];

            return Card(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isPublic)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Personal Event',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange, // Customize color as needed
                          ),
                        ),
                      ),
                    Text(
                      '$eventName',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('$eventDescription'),
                    Text('${_formatDate(eventDate)}'),
                    Text('${_formatTime(eventTime)}'),
                    FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance.collection('users').doc(createdBy).get(),
                      builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot<Map<String, dynamic>>> snapshot) {
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }

                        if (snapshot.connectionState == ConnectionState.done) {
                          Map<String, dynamic>? userData = snapshot.data?.data();
                          String userName = userData?['name'] ?? 'Unknown';
                          return Text('$userName');
                        }

                        return Text('Loading...');
                      },
                    ),
                  ],
                ),
              ),
            );
          },


          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${_getDayOfWeek(date.weekday)} ${_getMonth(date.month)} ${date.day}, ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  String _getDayOfWeek(int day) {
    switch (day) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return '';
    }
  }

  String _getMonth(int month) {
    switch (month) {
      case 1:
        return 'January';
      case 2:
        return 'February';
      case 3:
        return 'March';
      case 4:
        return 'April';
      case 5:
        return 'May';
      case 6:
        return 'June';
      case 7:
        return 'July';
      case 8:
        return 'August';
      case 9:
        return 'September';
      case 10:
        return 'October';
      case 11:
        return 'November';
      case 12:
        return 'December';
      default:
        return '';
    }
  }
}
