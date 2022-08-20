import 'dart:io';
import 'package:band_names/services/socket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart';
import 'package:provider/provider.dart';
import '../models/band.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Band> bands = [];

  @override
  void initState() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.on('active-bands', _handleActiveBands);
    super.initState();
  }

  _handleActiveBands(dynamic payload) {
    bands = (payload as List).map((band) => Band.fromMap(band)).toList();
    setState(() {});
  }

  @override
  void dispose() {
    final socketService = Provider.of<SocketService>(context, listen: false);
    socketService.socket.off('active-bands');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final socketService = Provider.of<SocketService>(context);

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Band Names', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: <Widget>[
          Container(
              margin: EdgeInsets.only(right: 10),
              child: (socketService.serverStatus == ServerStatus.Online)
                  ? Icon(Icons.check_circle, color: Colors.blue[300])
                  : Icon(Icons.offline_bolt, color: Colors.red))
        ],
      ),
      body: Column(
        children: <Widget>[
          if(bands.isNotEmpty) _showGraph(),
          Expanded(
            child: ListView.builder(
                itemCount: bands.length,
                itemBuilder: (context, i) => _bandTile(bands[i])),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          elevation: 1,
          onPressed: () => addNewBand()),
    );
  }

  Widget _bandTile(Band band) {
    final socketService = Provider.of<SocketService>(context, listen: false);

    return Dismissible(
        key: Key(band.id!),
        direction: DismissDirection.startToEnd,
        onDismissed: (_) {
          socketService.emit('delete-band', {'id': band.id});
        },
        background: Container(
          padding: const EdgeInsets.only(left: 8.0),
          color: Colors.red,
          child: const Align(
              alignment: Alignment.centerLeft,
              child:
                  Text('Delete Band', style: TextStyle(color: Colors.white))),
        ),
        child: ListTile(
          leading: CircleAvatar(
            child: Text(band.name!.substring(0, 2)),
            backgroundColor: Colors.blue[100],
          ),
          title: Text(band.name!),
          trailing: Text('${band.votes}', style: const TextStyle(fontSize: 20)),
          onTap: () {
            socketService.emit('vote-band', {'id': band.id});
          },
        ));
  }

  addNewBand() {
    final textController = TextEditingController();

    if (Platform.isAndroid) {
      return showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                title: const Text('New band name'),
                content: TextField(
                  controller: textController,
                ),
                actions: <Widget>[
                  MaterialButton(
                    elevation: 5,
                    textColor: Colors.blue,
                    onPressed: () => addBandToList(textController.text),
                    child: const Text('Add'),
                  )
                ]);
          });
    }

    showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: const Text('New band name'),
            content: CupertinoTextField(
              controller: textController,
            ),
            actions: <Widget>[
              CupertinoDialogAction(
                isDefaultAction: true,
                onPressed: () => addBandToList(textController.text),
                child: const Text('Add'),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                onPressed: () => Navigator.pop(context),
                child: const Text('Dismiss'),
              )
            ],
          );
        });
  }

  void addBandToList(String name) {
    if (name.isNotEmpty) {
      final socketService = Provider.of<SocketService>(context, listen: false);
      socketService.emit('create-band', {'name': name});
      setState(() {});
    }

    Navigator.pop(context);
  }

  Widget _showGraph() {
    Map<String, double> dataMap = new Map();
    bands.forEach((band) {
      dataMap.putIfAbsent(band.name!, () => band.votes!.toDouble());
    });
    return SizedBox(
      width: double.infinity,
      height: 200,
      child: PieChart(dataMap: dataMap),
    );
  }
}
