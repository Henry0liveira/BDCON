import 'package:flutter/material.dart';
import 'dart:io'; // Adicionando import para a classe File
import 'conversor_moedas.dart'; // Importando a tela de conversão de moedas
import 'database_helper.dart' as db; // Usando alias para evitar conflito de nomes
import 'form.dart'; // Importando o formulário de contatos

void main() {
  runApp(MaterialApp(
    home: TelaInicial(),
    theme: ThemeData(
      primaryColor: Colors.white,
      hintColor: Colors.green,
    ),
    debugShowCheckedModeBanner: false,
  ));
}

class TelaInicial extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Gestão de Contatos e Cambio"),
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Primeiro bloco - Gestão de Contatos (metade superior da tela)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 0, 0, 0),
                border: Border(
                  bottom: BorderSide(color: Colors.green, width: 2.0),
                ),
              ),
              child: Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.contacts, color: const Color.fromARGB(255, 0, 247, 255)),
                  label: Text(
                    "Gestão de Contatos",
                    style: TextStyle(
                      fontSize: 20.0,
                      color: const Color.fromARGB(255, 0, 204, 255),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                    backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    // Navegação para a tela de gestão de contatos
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GestaoContatos()),
                    );
                  },
                ),
              ),
            ),
          ),
          
          // Segundo bloco - Conversor de Moedas (metade inferior da tela)
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              child: Center(
                child: ElevatedButton.icon(
                  icon: Icon(Icons.attach_money, color: Colors.black),
                  label: Text(
                    "Conversor de Moedas",
                    style: TextStyle(
                      fontSize: 20.0,
                      color: Colors.black,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  onPressed: () {
                    // Navegação para a tela de conversão de moedas
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => TelaInicialConversor()),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Implementação completa da tela de gestão de contatos
class GestaoContatos extends StatefulWidget {
  @override
  _GestaoContatosState createState() => _GestaoContatosState();
}

class _GestaoContatosState extends State<GestaoContatos> {
  final _dbHelper = db.DatabaseHelper(); // Usando o alias definido na importação
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

  String _formatarData(String dataString) {
  DateTime data = DateTime.parse(dataString);
  return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";
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
                                    File(contato['foto']), // Usando corretamente a classe File
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
                            if (contato['data_criacao'] != null && contato['data_criacao'].isNotEmpty)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Text(_formatarData(contato['data_criacao'])),
                              ),
                            if (contato['categoria'] != null)
                              Padding(
                                padding: EdgeInsets.only(top: 4),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    contato['categoria'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[800],
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
        backgroundColor: Colors.blue,
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