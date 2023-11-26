import 'package:flutter/material.dart';
import 'package:parse_server_sdk/parse_server_sdk.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Parse().initialize(
    'ce2bMndbLHH5sxrghs2MAFbuazxseEL0bvLgXvnF',
    'https://parseapi.back4app.com/parse',
    clientKey: 'yfU3yvKA2lk0NcsKAFM3gKzXoahiWW9I2iCF09Cr',
    autoSendSessionId: true,
    debug: true,
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: YourHomePage(),
    );
  }
}

class YourHomePage extends StatefulWidget {
  @override
  _YourHomePageState createState() => _YourHomePageState();
}

class _YourHomePageState extends State<YourHomePage> {
  List<ParseObject> vehicles = [];
  final _nameController = TextEditingController();
  final _regionController = TextEditingController();
  final _timeRequiredController = TextEditingController();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDataFromParse();
  }

  Future<void> fetchDataFromParse() async {
    try {
      setState(() {
        isLoading = true;
      });

      final ParseResponse response = await ParseObject('B4aVehicle').getAll();

      if (response.success && response.results != null) {
        setState(() {
          vehicles = response.results!.cast<ParseObject>();
        });

        for (final ParseObject vehicle in vehicles) {
          print('Vehicle: ${vehicle.toJson()}');
        }
      } else {
        print('Error fetching data from Parse: ${response.error?.message}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addDataToParse() async {
    final ParseObject newVehicle = ParseObject('B4aVehicle')
      ..set('Task', _nameController.text)
      ..set('Region', _regionController.text)
      ..set('TimeRequired', int.tryParse(_timeRequiredController.text) ?? 0);

    try {
      final ParseResponse response = await newVehicle.save();

      if (response.success) {
        print('Data added successfully: ${newVehicle.toJson()}');
        fetchDataFromParse();
        _nameController.clear();
        _regionController.clear();
        _timeRequiredController.clear();
      } else {
        print('Error adding data to Parse: ${response.error?.message}');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> deleteDataFromParse(String? objectId) async {
    try {
      if (objectId != null) {
        final ParseObject objectToDelete = ParseObject('B4aVehicle')..objectId = objectId;
        final ParseResponse response = await objectToDelete.delete();

        if (response.success) {
          print('Data deleted successfully: $objectId');
        }
        fetchDataFromParse(); // Refresh the data after deleting
      } else {
        print('Error: objectId is null');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> showDeleteConfirmationDialog(String objectId) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Completion'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you have completed this task?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(primary: Colors.green),
              child: Text('Completed'),
              onPressed: () {
                deleteDataFromParse(objectId);
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
      appBar: AppBar(
        title: Text('Task editor'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Add Task:'),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Task'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _regionController,
                keyboardType: TextInputType.text, // Change to TextInputType.text
                decoration: InputDecoration(labelText: 'Region'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _timeRequiredController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Time Required'),
              ),
            ),
            ElevatedButton(
              onPressed: addDataToParse,
              child: Text('Add Data'),
            ),
            SizedBox(height: 20),
            isLoading
                ? CircularProgressIndicator() // Show a loading indicator while fetching data
                : vehicles.isNotEmpty
                    ? DataTable(
                        columns: [
                          DataColumn(label: Text('Region')),
                          DataColumn(label: Text('Task')),
                          DataColumn(label: Text('Time Required')),
                          DataColumn(label: Text('Complete')),
                        ],
                        rows: vehicles.map((vehicle) {
                          return DataRow(
                            cells: [
                              DataCell(Text(vehicle.get<String>('Region') ?? '')),
                              DataCell(Text(vehicle.get<String>('Task') ?? '')),
                              DataCell(Text(vehicle.get<int>('TimeRequired').toString() ?? '')),
                              DataCell(
                                Icon(Icons.check, color: Colors.green),
                                onTap: () {
                                  showDeleteConfirmationDialog(vehicle.objectId!);
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      )
                    : Text('No data available from Parse'),
          ],
        ),
      ),
    );
  }
}
