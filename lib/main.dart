import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main(){
  runApp(MaterialApp(
    home: Home(),
    debugShowCheckedModeBanner: false,
  ));
}

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _todoController = TextEditingController();

  List _todoList = [];

  Map<String, dynamic>? _lastRemoved;
  int? _lastRemovedPos;


  @override
  void initState() {
    super.initState();
    
    _readData().then((data) {
      setState(() {
        _todoList = json.decode(data);
      });
    });
  }

  void _addTodo() {
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo['title'] = _todoController.text;
      _todoController.text = "";
      newToDo['ok'] = false;
      _todoList.add(newToDo);

      _saveData();
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));

   setState(() {
     _todoList.sort((a, b) {
       if(a['ok'] && !b['ok'] ) return 1;
       else if(!a['ok'] && b['ok']) return -1;
       else return 0;
     });

     _saveData();
   });

   return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text('Lista de Tarefas'),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
            child: Row(
              children: [
                Expanded(child: TextField(
                  controller: _todoController,
                  decoration: InputDecoration(
                    labelText: 'Nova Tarefa',
                    labelStyle: TextStyle(color: Colors.blueAccent),
                  ),
                ),
                ),
                ElevatedButton(onPressed: () {
                  _addTodo();
                },
                  child: Text('Add'),
                  style: ButtonStyle(backgroundColor: MaterialStateProperty.all<Color>(Colors.blueAccent),
                    foregroundColor: MaterialStateProperty.all<Color>(Colors.white),

                       ),

                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(child: ListView.builder(
                  padding: EdgeInsets.only(top: 10),
                  itemCount: _todoList.length,
                  itemBuilder: buildItem),
                  onRefresh: _refresh),
          ) ],
      ),
    );
  }

  Widget buildItem (BuildContext context, int index){
    return Dismissible(
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white,),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        onChanged: (value) {
          setState(() {
            _todoList[index]['ok'] = value;
            _saveData();
          }
          );
        },
        title: Text(_todoList[index]['title']),
        value: _todoList[index]['ok'],
        secondary: CircleAvatar(
          child: Icon(_todoList[index]['ok'] ?
          Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction) {
        setState(() {
          _lastRemoved = Map.from(_todoList[index]);
          _lastRemovedPos = index;
          _todoList.removeAt(index);
          _saveData();
          
          final snack = SnackBar(
              content: Text('Tarefa ${_lastRemoved!['title']} removida!'),
              action: SnackBarAction(label: 'Desfazer', onPressed: () {
                setState(() {
                  _todoList.insert(_lastRemovedPos!, _lastRemoved);
                  _saveData();
                });
              }),
                  duration: Duration(seconds: 2),
            );
              ScaffoldMessenger.of(context).showSnackBar(snack);
           });
      },
    );
  }

  Future<File> _getFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}data.json');
  }


  Future<File> _saveData () async {
    String data = jsonEncode(_todoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async {
    try{
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return 'Erro';
    }
  }
}