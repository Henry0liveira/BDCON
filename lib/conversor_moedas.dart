import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';

// Classe para representar uma conversão
class Conversao {
  final int? id;
  final double valorReal;
  final double valorDolar;
  final double valorEuro;
  final String data;

  Conversao({
    this.id,
    required this.valorReal,
    required this.valorDolar,
    required this.valorEuro,
    required this.data,
  });

  // Converte um Map para um objeto Conversao
  factory Conversao.fromMap(Map<String, dynamic> map) {
    return Conversao(
      id: map['id'],
      valorReal: map['valorReal'],
      valorDolar: map['valorDolar'],
      valorEuro: map['valorEuro'],
      data: map['data'],
    );
  }

  // Converte um objeto Conversao para um Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'valorReal': valorReal,
      'valorDolar': valorDolar,
      'valorEuro': valorEuro,
      'data': data,
    };
  }
}

// Classe para gerenciar o banco de dados
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => _instance;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'conversoes_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE conversoes(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        valorReal REAL,
        valorDolar REAL,
        valorEuro REAL,
        data TEXT
      )
    ''');
  }

  // Método para salvar uma conversão
  Future<int> inserirConversao(Conversao conversao) async {
    Database db = await database;
    return await db.insert('conversoes', conversao.toMap());
  }

  // Método para obter todas as conversões
  Future<List<Conversao>> conversoes() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query('conversoes', orderBy: 'id DESC');
    return List.generate(maps.length, (i) {
      return Conversao.fromMap(maps[i]);
    });
  }

  // Método para limpar o histórico
  Future<int> limparHistorico() async {
    Database db = await database;
    return await db.delete('conversoes');
  }
}

// Classe principal do conversor de moedas
class TelaInicialConversor extends StatefulWidget {
  @override
  _TelaInicialConversorState createState() => _TelaInicialConversorState();
}

class _TelaInicialConversorState extends State<TelaInicialConversor> {
  final realController = TextEditingController();
  bool isLoading = false;
  final dbHelper = DatabaseHelper();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Conversor de Moeda"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.attach_money,
                size: 120.0,
                color: Colors.green,
              ),
              SizedBox(height: 40.0),
              TextField(
                controller: realController,
                decoration: InputDecoration(
                  labelText: "Valor em Reais",
                  labelStyle: TextStyle(color: Colors.green),
                  border: OutlineInputBorder(),
                  prefixText: "R\$ ",
                ),
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 25.0,
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 30.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
                  minimumSize: Size(double.infinity, 50),
                ),
                onPressed: isLoading ? null : () async {
                  if (realController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Por favor, insira um valor em Reais"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  setState(() {
                    isLoading = true;
                  });
                  
                  try {
                    final data = await getData();
                    final double valorReal = double.parse(realController.text);
                    final double dolar = data['results']['currencies']['USD']['buy'];
                    final double euro = data['results']['currencies']['EUR']['buy'];
                    
                    // Salvar a conversão no banco de dados
                    final conversao = Conversao(
                      valorReal: valorReal,
                      valorDolar: valorReal / dolar,
                      valorEuro: valorReal / euro,
                      data: DateTime.now().toString(),
                    );
                    
                    await dbHelper.inserirConversao(conversao);
                    
                    // Navegação para a tela de resultados
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TelaResultados(
                          valorReal: valorReal,
                          valorDolar: valorReal / dolar,
                          valorEuro: valorReal / euro,
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Erro ao converter: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    setState(() {
                      isLoading = false;
                    });
                  }
                },
                child: isLoading 
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text(
                      "CONVERTER",
                      style: TextStyle(
                        fontSize: 20.0,
                        color: Colors.white,
                      ),
                    ),
              ),
              SizedBox(height: 20.0),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(horizontal: 50.0, vertical: 15.0),
                  minimumSize: Size(double.infinity, 50),
                  side: BorderSide(color: Colors.green),
                ),
                onPressed: () {
                  Navigator.push(
                    context, 
                    MaterialPageRoute(
                      builder: (context) => HistoricoConversoes(),
                    ),
                  );
                },
                child: Text(
                  "CONVERSÕES ANTERIORES",
                  style: TextStyle(
                    fontSize: 15.0,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tela de resultados da conversão
class TelaResultados extends StatelessWidget {
  final double valorReal;
  final double valorDolar;
  final double valorEuro;
  
  TelaResultados({
    required this.valorReal,
    required this.valorDolar,
    required this.valorEuro,
  });
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Resultado da Conversão"),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.black,
              elevation: 4,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.green, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Valor em Reais",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      "R\$ ${valorReal.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Card(
              color: Colors.black,
              elevation: 4,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.green, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Valor em Dólares",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      "US\$ ${valorDolar.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.0),
            Card(
              color: Colors.black,
              elevation: 4,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.green, width: 1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      "Valor em Euros",
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 18.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Text(
                      "€ ${valorEuro.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15.0),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "NOVA CONVERSÃO",
                style: TextStyle(
                  fontSize: 18.0,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Tela de histórico de conversões
class HistoricoConversoes extends StatefulWidget {
  @override
  _HistoricoConversoesState createState() => _HistoricoConversoesState();
}

class _HistoricoConversoesState extends State<HistoricoConversoes> {
  final dbHelper = DatabaseHelper();
  late Future<List<Conversao>> _conversoes;

  @override
  void initState() {
    super.initState();
    _carregarConversoes();
  }

  void _carregarConversoes() {
    setState(() {
      _conversoes = dbHelper.conversoes();
    });
  }

  String _formatarData(String dataString) {
    DateTime data = DateTime.parse(dataString);
    return "${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year} ${data.hour.toString().padLeft(2, '0')}:${data.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          "Histórico de Conversões",
          style: TextStyle(
            fontSize: 18, // Ajuste o tamanho conforme necessário
          ),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.delete_sweep),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.black,
                  title: Text(
                    "Limpar Histórico",
                    style: TextStyle(color: Colors.green),
                  ),
                  content: Text(
                    "Deseja limpar todo o histórico de conversões?",
                    style: TextStyle(color: Colors.white),
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        "Cancelar",
                        style: TextStyle(color: Colors.grey),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: Text(
                        "Limpar",
                        style: TextStyle(color: Colors.red),
                      ),
                      onPressed: () async {
                        await dbHelper.limparHistorico();
                        Navigator.pop(context);
                        _carregarConversoes();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Histórico limpo com sucesso"),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: FutureBuilder<List<Conversao>>(
        future: _conversoes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                "Erro ao carregar o histórico",
                style: TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "Nenhuma conversão encontrada",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final conversao = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  color: Colors.black,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: Colors.green.withOpacity(0.5), width: 1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ExpansionTile(
                    iconColor: Colors.green,
                    collapsedIconColor: Colors.green,
                    title: Text(
                      "R\$ ${conversao.valorReal.toStringAsFixed(2)}",
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    subtitle: Text(
                      _formatarData(conversao.data),
                      style: TextStyle(color: Colors.grey),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Dólar: US\$ ${conversao.valorDolar.toStringAsFixed(2)}",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Euro: € ${conversao.valorEuro.toStringAsFixed(2)}",
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}

// Função para buscar dados da API
Future<Map<String, dynamic>> getData() async {
  var request = Uri.parse('https://api.hgbrasil.com/finance?format=json&key=d30d279e');
  http.Response response = await http.get(request);
  return json.decode(response.body);
}