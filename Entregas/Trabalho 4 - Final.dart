import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String?> fazerLogin(String email, String senha) async {
  // URL do endpoint
  final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/fazer_login');

  // Headers da requisição
  final Map<String, String> headers = {
    'accept': 'application/json',
    'Content-Type': 'application/json',
  };

  // Corpo da requisição (JSON)
  final Map<String, String> body = {
    'email': email,
    'senha': senha,
  };

  // Converte o body para JSON
  final String jsonBody = json.encode(body);

  try {
    // Realiza a requisição POST
    final response = await http.post(url, headers: headers, body: jsonBody);

    // Verifica o código de status da resposta
    if (response.statusCode == 200) {
      // Sucesso na requisição
      final responseData = json.decode(response.body);
      final String token = responseData['token'];
      return token;
    } else {
      // Erro na requisição
      print('Erro: ${response.statusCode} - ${response.body}');
      return null; // Retorna null em caso de erro
    }
  } catch (e) {
    // Tratamento de exceções
    print('Ocorreu um erro: ${e.toString()}');
    return null; // Retorna null em caso de erro
  }
}

Future<void> criarListaTarefas(String token, String email) async {
  // URL do endpoint para criar a lista de tarefas
  final url = Uri.https('barra.cos.ufrj.br:443', '/rest/tarefas');

  // Headers da requisição com o token de autenticação
  final Map<String, String> headers = {
    'accept': 'application/json',
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token', // Token de autenticação JWT
  };

  // Corpo da requisição (JSON), com a lista de tarefas vazia
  final Map<String, dynamic> body = {
    'email': email,
    'valor': [], // Lista de tarefas vazia
  };

  // Converte o body para JSON
  final String jsonBody = json.encode(body);

  try {
    // Realiza a requisição POST para criar a tarefa
    final response = await http.post(url, headers: headers, body: jsonBody);

    // Verifica o código de status da resposta
    if (response.statusCode == 201 || response.statusCode == 200) {
      print('Lista de tarefas criada com sucesso!');
    } else {
      print(
          'Erro ao criar a lista de tarefas: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Ocorreu um erro ao criar a lista de tarefas: ${e.toString()}');
  }
}

void main() async {
  // Realiza o login e armazena o token
  String? token = await fazerLogin('wpfaltz@poli.ufrj.br', 'teste123');

  print(token);

  if (token != null) {
    // Caso o login seja bem-sucedido, cria a lista de tarefas vazia
    await criarListaTarefas(token, 'wpfaltz@poli.ufrj.br');
  } else {
    print('Erro ao realizar o login.');
  }
}
