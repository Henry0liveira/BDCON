import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'database_helper.dart' as db; // Usando alias para evitar conflito de nomes

class FormularioContato extends StatefulWidget {
  final Map<String, dynamic>? contato;

  FormularioContato({this.contato});

  @override
  _FormularioContatoState createState() => _FormularioContatoState();
}

class _FormularioContatoState extends State<FormularioContato> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  String? _categoriaValue;
  File? _imagemSelecionada;
  String? _fotoPath;
  bool _isLoading = false;

  final List<String> _categorias = ['Família', 'Amigos', 'Trabalho', 'Outros'];
  
  @override
  void initState() {
    super.initState();
    if (widget.contato != null) {
      _nomeController.text = widget.contato!['nome'];
      _telefoneController.text = widget.contato!['telefone'] ?? '';
      _emailController.text = widget.contato!['email'] ?? '';
      _categoriaValue = widget.contato!['categoria'];
      _fotoPath = widget.contato!['foto'];
    }
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selecionarImagem() async {
    final ImagePicker picker = ImagePicker();
    final XFile? imagem = await picker.pickImage(source: ImageSource.gallery);

    if (imagem != null) {
      setState(() {
        _imagemSelecionada = File(imagem.path);
      });
    }
  }

  Future<String?> _salvarImagem() async {
    if (_imagemSelecionada == null) return _fotoPath;
    
    final diretorio = await getApplicationDocumentsDirectory();
    final nomeArquivo = 'contato_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final caminhoSalvar = path.join(diretorio.path, nomeArquivo);
    
    await _imagemSelecionada!.copy(caminhoSalvar);
    return caminhoSalvar;
  }

  Future<void> _salvarContato() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      final fotoPath = await _salvarImagem();
      
      final contato = {
        'nome': _nomeController.text,
        'telefone': _telefoneController.text,
        'email': _emailController.text,
        'categoria': _categoriaValue,
        'foto': fotoPath,
        'data_criacao': DateTime.now().toIso8601String(),
      };

      if (widget.contato != null) {
        contato['id'] = widget.contato!['id'];
      }

      final dbHelper = db.DatabaseHelper(); // Usando o alias definido na importação
      
      if (widget.contato == null) {
        await dbHelper.insertContato(contato);
      } else {
        await dbHelper.updateContato(contato);
      }

      setState(() {
        _isLoading = false;
      });
      
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.contato == null ? 'Novo Contato' : 'Editar Contato'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _selecionarImagem,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            shape: BoxShape.circle,
                          ),
                          child: _imagemSelecionada != null
                              ? ClipOval(
                                  child: Image.file(
                                    _imagemSelecionada!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _fotoPath != null
                                  ? ClipOval(
                                      child: Image.file(
                                        File(_fotoPath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        icon: Icon(Icons.photo_library),
                        label: Text('Selecionar Foto'),
                        onPressed: _selecionarImagem,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      controller: _nomeController,
                      decoration: InputDecoration(
                        labelText: 'Nome',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Por favor, digite o nome';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _telefoneController,
                      decoration: InputDecoration(
                        labelText: 'Telefone',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _categoriaValue,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      items: _categorias.map((String categoria) {
                        return DropdownMenuItem<String>(
                          value: categoria,
                          child: Text(categoria),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _categoriaValue = newValue;
                        });
                      },
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _salvarContato,
                      child: Text(
                        'SALVAR',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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