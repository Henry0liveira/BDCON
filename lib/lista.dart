import 'package:flutter/material.dart';
import 'dart:io';
import 'database_helper.dart';
import 'form.dart';

class GestaoContatos extends StatefulWidget {
  @override
  _GestaoContatosState createState() => _GestaoContatosState();
}

class _GestaoContatosState extends State<GestaoContatos> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _contatos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _carregarContatos();
  }

  Future<void> _carregarContatos() async {
    setState(() {
      _isLoading = true;
    });

    final contatos = await _dbHelper.getContatos();
    
    setState(() {
      _contatos = contatos;
      _isLoading = false;
    });
  }

  Future<void> _excluirContato(int id) async {
    await _dbHelper.deleteContato(id);
    _carregarContatos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Gestão de Contatos"),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _contatos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 80,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Nenhum contato encontrado",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _contatos.length,
                  itemBuilder: (context, index) {
                    final contato = _contatos[index];
                    return Card(
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey[200],
                          child: contato['foto'] != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(contato['foto']),
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 30,
                                  color: Colors.grey[400],
                                ),
                        ),
                        title: Text(
                          contato['nome'],
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (contato['telefone'] != null && contato['telefone'].isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(contato['telefone']),
                              ),
                            if (contato['email'] != null && contato['email'].isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(contato['email']),
                              ),
                            if (contato['categoria'] != null)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    contato['categoria'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FormularioContato(contato: contato),
                                  ),
                                );
                                if (result == true) {
                                  _carregarContatos();
                                }
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Excluir Contato'),
                                    content: Text('Tem certeza que deseja excluir este contato?'),
                                    actions: [
                                      TextButton(
                                        child: Text('Cancelar'),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                        },
                                      ),
                                      TextButton(
                                        child: Text('Excluir'),
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          _excluirContato(contato['id']);
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        child: Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => FormularioContato()),
          );
          if (result == true) {
            _carregarContatos();
          }
        },
      ),
    );
  }
}