import 'package:InternHeroes/features/user_auth/presentation/pages/ChooseTypePage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/addpost.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/knowledgeresourcepage.dart';
import 'package:InternHeroes/features/user_auth/presentation/pages/userlistpage.dart';
import 'package:InternHeroes/features/user_auth/presentation/widgets/bottom_navbar.dart';
import 'event_list.dart'; // Import the event_list.dart file
import 'package:intl/intl.dart';


void main() {
  runApp(Calendar());
}

class Calendar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CalendarPage(title: 'Calendar');
  }
}


class CalendarPage extends StatefulWidget {
  final String title;

  CalendarPage({required this.title});

  @override
  _CalendarPageState createState() => _CalendarPageState();


}

class Event {
  final String id;
  final String eventName;
  final String eventDescription;
  final DateTime eventDateTime;
  final String createdBy;
  final bool isPublic;

  Event(this.id, this.eventName, this.eventDescription, this.eventDateTime, this.createdBy, this.isPublic);

  @override
  String toString() {
    return eventName;
  }
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  late Map<DateTime, List<Event>> _events;
  late TextEditingController _eventController;
  late ValueNotifier<List<Event>> _selectedEvents;
  late DateTime _focusedDay = DateTime.now();
  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _events = {};
    _eventController = TextEditingController();
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay));
    _loadEvents(); // Load events on init
  }

  @override
  void dispose() {
    _eventController.dispose();
    _selectedEvents.dispose();
    super.dispose();
  }

  void _updateSelectedEvents(DateTime selectedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _selectedEvents.value = _getEventsForDay(_selectedDay);
    });
  }

  void _loadEvents() {
    FirebaseFirestore.instance.collection('events').snapshots().listen((QuerySnapshot eventsSnapshot) {
      eventsSnapshot.docChanges.forEach((change) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> eventData = change.doc.data() as Map<String, dynamic>;
          DateTime eventDateTime = (eventData['eventDateTime'] as Timestamp).toDate();
          Event event = Event(
            change.doc.id,
            eventData['eventName'],
            eventData['eventDescription'],
            eventDateTime,
            eventData['createdBy'],
            eventData['isPublic'],
          );

          if (_events.containsKey(eventDateTime)) {
            // Check if the event already exists in the list to avoid duplicates
            if (!_events[eventDateTime]!.any((e) => e.id == event.id)) {
              _events[eventDateTime]!.add(event);
            }
          } else {
            _events[eventDateTime] = [event];
          }
          setState(() {
            _events = Map.from(_events);
          });
        }
      });
    }, onError: (error) {
      print('Error listening to events: $error');
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    List<Event> selectedDayEvents = [];
    _events.forEach((key, value) {
      if (isSameDay(key, day)) {
        value.forEach((event) {
          if (event.eventDateTime.isAfter(DateTime.now()) && event.id.isNotEmpty &&
              (event.isPublic || event.createdBy == FirebaseAuth.instance.currentUser!.uid)) {
            selectedDayEvents.add(event);
          }
        });
      }
    });
    return selectedDayEvents;
  }

  void _addLocalEvent(Event event) {
    try {
      DateTime key = DateTime(event.eventDateTime.year, event.eventDateTime.month, event.eventDateTime.day);
      if (_events.containsKey(key)) {
        // Check if the event already exists in the list to avoid duplicates
        if (!_events[key]!.any((e) => e.id == event.id)) {
          _events[key]!.add(event);
        }
      } else {
        _events[key] = [event];
      }
      _selectedEvents.value = _getEventsForDay(_selectedDay);
    } catch (e) {
      print('Error adding local event: $e');
    }
  }

  void _addEventToFirestore(Event event) {
    try {
      FirebaseFirestore.instance.collection('events').add({
        'eventName': event.eventName,
        'eventDescription': event.eventDescription,
        'eventDateTime': event.eventDateTime,
        'createdBy': event.createdBy,
        'isPublic': event.isPublic, // Set visibility flag
      });
    } catch (e) {
      print('Error adding event to Firestore: $e');
    }
  }

  void _addEvent() async {
    String eventName = '';
    String eventDescription = '';
    TimeOfDay selectedTime = TimeOfDay.now();

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );

    if (pickedTime != null) {
      selectedTime = pickedTime;
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDay = pickedDate;
        _selectedEvents.value = _getEventsForDay(_selectedDay);
      });
    }

    if (pickedDate != null && pickedTime != null) {
      showDialog(
        context: context,
        builder: (context) {
          bool? isPublic = true; // Default visibility is public

          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                scrollable: true,
                title: const Text("Add Event"),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      onChanged: (value) {
                        eventName = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Event Name',
                      ),
                    ),
                    TextField(
                      onChanged: (value) {
                        eventDescription = value;
                      },
                      decoration: InputDecoration(
                        labelText: 'Event Descripton',
                      ),
                    ),
                    Row(
                      children: [
                        Radio(
                          value: true,
                          groupValue: isPublic,
                          onChanged: (value) {
                            setState(() {
                              isPublic = value;
                            });
                          },
                        ),
                        Text('Public'),
                        Radio(
                          value: false,
                          groupValue: isPublic,
                          onChanged: (value) {
                            setState(() {
                              isPublic = value;
                            });
                          },
                        ),
                        Text('Private'),
                      ],
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        DateTime eventDateTime = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );

                        String userId = FirebaseAuth.instance.currentUser!.uid;
                        Event newEvent = Event('', eventName, eventDescription, eventDateTime, userId, isPublic ?? true);
                        _addLocalEvent(newEvent);
                        _addEventToFirestore(newEvent);
                      });
                      Navigator.of(context).pop();
                    },
                    child: const Text("Submit"),
                  ),
                ],
              );
            },
          );
        },
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          textAlign: TextAlign.center,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEvent,
        child: const Icon(Icons.add),
        backgroundColor: Colors.yellow[800]!,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.all(10),
              height: 450, // Reduced height for the calendar card
              child: Card(
                elevation: 2, // Adjust elevation as needed
                shadowColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side: BorderSide(color: Colors.grey[50]!),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 10, bottom: 10), // Adjust padding values here
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('MMMM y').format(_focusedDay),
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(Icons.arrow_back_ios, size: 20, color: Colors.grey), // Adjust size and color here
                                  onPressed: () {
                                    setState(() {
                                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1);
                                      _selectedEvents.value = _getEventsForDay(_focusedDay);
                                    });
                                  },
                                ),
                                IconButton(
                                  icon: Icon(Icons.arrow_forward_ios, size: 20, color: Colors.grey), // Adjust size and color here
                                  onPressed: () {
                                    setState(() {
                                      _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1);
                                      _selectedEvents.value = _getEventsForDay(_focusedDay);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      TableCalendar(
                        rowHeight: 50,
                        headerVisible: false, // Hide default header
                        selectedDayPredicate: (day) => isSameDay(_focusedDay, day),
                        focusedDay: _focusedDay,
                        firstDay: DateTime.now().subtract(const Duration(days: 365)),
                        lastDay: DateTime.now().add(const Duration(days: 365)),
                        onDaySelected: (selectedDay, focusedDay) {
                          setState(() {
                            _focusedDay = selectedDay;
                            _selectedEvents.value = _getEventsForDay(selectedDay);
                          });
                        },
                        eventLoader: _getEventsForDay,
                        calendarStyle: CalendarStyle(
                          todayDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          selectedDecoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 20),
                  child: Text(
                    'Events',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
                  ),
                ),
                Spacer(), // Use Spacer to occupy remaining space
                Padding(
                  padding: const EdgeInsets.only(right: 20),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EventList()),
                      );
                    },
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.yellow[800]!), // Change background color
                    ),
                    child: Text(
                      'See all events',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 100,
              child: ValueListenableBuilder<List<Event>>(
                valueListenable: _selectedEvents,
                builder: (context, events, _) {
                  if (events.isEmpty) {
                    return Center(child: Text('No events for this day'));
                  }
                  return ListView.builder(
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (index == 0 || events[index - 1].eventDateTime.day != event.eventDateTime.day)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                              child: Text(
                                DateFormat('EEEE, MMM d').format(event.eventDateTime),
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            child: ListTile(
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (!event.isPublic)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 4.0),
                                      child: Text(
                                        'Personal Event',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange, // Customize color as needed
                                        ),
                                      ),
                                    ),
                                  Text(
                                    event.eventName,
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.eventDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 4), // Add some space between description and time
                                  Text(
                                    'Time: ${DateFormat('hh:mm a').format(event.eventDateTime)}',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),


      bottomNavigationBar: BottomNavBar(
        selectedIndex: 3,
        onItemTapped: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => KnowledgeResource()),
              );
              break;
            case 1:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserListPage()),
              );
              break;
            case 2:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ChooseTypePage()),
              );
              break;
            case 3:
            // Stay on the current page (Calendar)
              break;
            case 4:
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfileScreen(uid: FirebaseAuth.instance.currentUser!.uid)),
              );
              break;
          }
        },
      ),
    );
  }
}
