import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
      ),
      initialRoute: '/home',
      routes: {
        '/home': (context) => HomeScreen(),
        '/login': (context) => LoginScreen(),
        '/signup': (context) => SignUpScreen(),
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Bem-vindo ao ToDo',
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        backgroundColor: Colors.orange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Já possui uma conta?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Text(
                'Novo por aqui?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Roboto',
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signup');
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.orangeAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Cadastre-se',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
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

Future<String?> signIn(String email, String password) async {
  final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/fazer_login');

  try {
    final response = await http.post(
      url, 
      headers:  {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'senha': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final String token = responseData['token'];
      return token;
    
    } else {
      return response.body;
    }
  } catch (e) {
    print('Ocorreu um erro: ${e.toString()}');
    return null;
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;
  String _errorMessage = '';
  bool showSignupButton = false;

  Future<void> _login() async {
    setState(() {
      isLoading = true;
      _errorMessage = '';
      showSignupButton = false;
    });

    final String email = _emailController.text;
    final String password = _passwordController.text;

    final response = await signIn(email, password);

    setState(() {
      isLoading = false;
    });

    if (response != null && response.startsWith('{')) {
      // Erro na autenticação
      final Map<String, dynamic> errorResponse = json.decode(response);
      final String message = errorResponse['message'];

      setState(() {
        if (message == "Senha inválida!") {
          _errorMessage = 'Senha incorreta! Tente novamente.';
        } else if (message == "Usuário não encontrado!") {
          _errorMessage =
              'Não foi encontrado nenhum usuário com o e-mail fornecido.';
          showSignupButton = true;
        } else {
          _errorMessage = 'Ocorreu um erro desconhecido. Tente novamente.';
        }
      });
    } else if (response != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => UserTaskList(
              title: 'Tarefas do Usuário', token: response, email: email),
        ),
      );
    } else {
      setState(() {
        _errorMessage = 'Erro na conexão. Tente novamente mais tarde.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (isLoading) CircularProgressIndicator(),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : _login,
              child: const Text('Login'),
            ),
            const SizedBox(height: 10),
            Visibility(
              visible: showSignupButton,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/signupScreen');
                },
                child: const Text('Cadastre-se aqui'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> signUp(
    String name, String email, String password, String? phoneNumber) async {
  final url = Uri.https('barra.cos.ufrj.br:443', '/rest/rpc/registra_usuario');

  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'nome': name,
      'email': email,
      'senha': password,
      'celular': phoneNumber
    }),
  );

  if (response.statusCode == 200) {
    return 'ok'; // Sucesso
  } else if (response.statusCode == 400) {
    final errorResponse = jsonDecode(response.body);
    return errorResponse['message'] ?? 'Erro desconhecido';
  } else {
    return 'Erro no servidor. Tente novamente mais tarde.';
  }
}

class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController(); // Campo para celular
  String _errorMessage = '';

  // Função que faz o cadastro
  Future<void> _signup() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.length < 3) {
      setState(() {
        _errorMessage = 'O nome deve ter no mínimo 3 caracteres';
      });
      return;
    }

    if (!RegExp(
            r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(email)) {
      setState(() {
        _errorMessage = 'O email está em um formato inválido';
      });
      return;
    }

    if (password.length < 8) {
      setState(() {
        _errorMessage = 'A senha deve ter no mínimo 8 caracteres';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = 'As senhas não coincidem';
      });
      return;
    }

    // Chama a função signUp com o nome, email e senha
    final result = await signUp(name, email, password, phone);

    if (result == 'ok') {
      // Exibe a mensagem de sucesso com SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Usuário cadastrado com sucesso!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } else {
      setState(() {
        _errorMessage = result; // Exibe a mensagem de erro da API
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cadastro')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _phoneController, // Campo para celular
              decoration:
                  const InputDecoration(labelText: 'Celular (opcional)'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Senha'),
              obscureText: true,
            ),
            TextField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(labelText: 'Confirmar senha'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            if (_errorMessage.isNotEmpty)
              Text(_errorMessage, style: TextStyle(color: Colors.red)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _signup,
              child: const Text('Cadastrar'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<String> createEmptyTaskList(String email, String token) async {
    final url = Uri.https('barra.cos.ufrj.br:443', '/rest/tarefas');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${token}'
      },
      body: jsonEncode({
        'email': email,
        'valor': [],
      }),
    );

    if (response.statusCode == 200) {
      return 'ok'; // Sucesso
    } else {
      return 'Erro ao criar lista de tarefas';
    }
  }

class UserTaskList extends StatefulWidget {
  final String title;
  final String token;
  final String email;

  const UserTaskList({
    super.key,
    required this.title,
    required this.token,
    required this.email,
  });

  @override
  State<UserTaskList> createState() => _UserTaskListState();
}

class _UserTaskListState extends State<UserTaskList> {
  final url = Uri.https('barra.cos.ufrj.br:443', '/rest/tarefas');
  bool isLoading = true;

  final List<String> pendingTasks = [];
  final List<String> completedTasks = [];
  final Set<String> scheduledToExclude = {};
  final Map<String, int> remainingTime = {};
  final _textController = TextEditingController();
  Map<String, Timer?> activeTimers = {};
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _loadUserTasks(); // Carregar as tarefas ao inicializar o widget
  }

  // Função para carregar as tarefas do servidor
  Future<void> _loadUserTasks() async {
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
      },
    );
    
    if (response.statusCode == 200) {
      setState(() {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          final userTasks = data[0]['valor'][0]; 
          pendingTasks.addAll(List<String>.from(userTasks['pendingTasks']));
          completedTasks.addAll(List<String>.from(userTasks['completedTasks']));
        }
        else {
          createEmptyTaskList(widget.email, widget.token);
        }
      
      isLoading = false;
      _showSnackBarWithCountdown('Tarefas carregadas com sucesso!', 2);
      });
    } else if (response.statusCode == 401) {
      _handleTokenExpired();
    } else {
      _showSnackBarWithCountdown('Erro ao carregar tarefas!', 2);
    }
  }

  Future<void> _handleTokenExpired() async {
    _showSnackBarWithCountdown('Sessão expirada, faça login novamente!', 2);
    Navigator.pushReplacementNamed(context, '/login');    
  }

  Future<void> _updateTasksOnServer() async {
    final taskData = {
      'pendingTasks': pendingTasks,
      'completedTasks': completedTasks,
    };

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
        //'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbWFpbCI6ImJyZW5vdmFsZW50ZTEwQGdtYWlsLmNvbSIsInJvbGUiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzI5MjU4ODM3fQ.qJwK8Lhylpc7lJUQlX5ZhBgV_XkKxIhF4oi7PmDRkK0',
      },
      body: jsonEncode({
        'email': widget.email,
        'valor': [taskData],
      }),
    );

    if (response.statusCode == 401) {
      _handleTokenExpired();
    }
  }

  void _addTask(String st) {
    setState(() {
      if (st.trim().isEmpty) {
        _showSnackBarWithCountdown(
            'Não é possível inserir tarefa com título vazio!', 2);
      } else if (pendingTasks.contains(st.trim()) ||
          completedTasks.contains(st.trim())) {
        _showSnackBarWithCountdown(
            'Já existe uma tarefa com este mesmo título na lista!', 2);
      } else {
        pendingTasks.insert(0, st.trim());
        _textController.clear();
        _updateTasksOnServer();
      }
    });
  }

  void _deletePendingTask(String task) {
    _scheduleTaskDeletion(task, true);
  }

  void _deleteCompletedTask(String task) {
    _scheduleTaskDeletion(task, false);
  }

  void _scheduleTaskDeletion(String task, bool isPending) {
    setState(() {
      scheduledToExclude.add(task);
      remainingTime[task] = 3;

      // Cancela o timer ativo antes de iniciar um novo
      activeTimers[task]?.cancel();

      // Cria um novo timer
      activeTimers[task] = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (remainingTime[task]! > 0) {
            remainingTime[task] = remainingTime[task]! - 1;
          } else {
            timer.cancel();
            if (scheduledToExclude.contains(task)) {
              _finalizeDeletion(task, isPending);
            }
            activeTimers
                .remove(task); // Remove o timer após finalizar a exclusão
          }
        });
      });
    });
  }

  void _finalizeDeletion(String task, bool isPending) {
    setState(() {
      scheduledToExclude.remove(task);
      remainingTime.remove(task);
      if (isPending) {
        pendingTasks.remove(task);
        _showSnackBarWithCountdown('Tarefa "$task" excluída das pendentes', 2);
        _updateTasksOnServer();
      } else {
        completedTasks.remove(task);
        _showSnackBarWithCountdown('Tarefa "$task" excluída das concluídas', 2);
        _updateTasksOnServer();
      }
    });
  }

  void _undoDeletion(String task, bool isPending) {
    setState(() {
      scheduledToExclude.remove(task);
      activeTimers[task]?.cancel(); // Cancelar o timer ativo
      activeTimers.remove(task); // Remove o timer da lista

      // Adiciona a tarefa apenas se não estiver na lista
      if (isPending) {
        if (!pendingTasks.contains(task)) {
          pendingTasks.insert(0, task);
        }
      } else {
        if (!completedTasks.contains(task)) {
          completedTasks.insert(0, task);
        }
      }
    });
  }

  void _completeTask(String task) {
    setState(() {
      pendingTasks.remove(task);
      completedTasks.insert(0, task);
      _updateTasksOnServer();
    });
  }

  void _undoCompleteTask(String task) {
    setState(() {
      completedTasks.remove(task);
      pendingTasks.insert(0, task);
      _updateTasksOnServer();
    });
  }

  ////// NÃO MEXER DAQUI EM DIANTE

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allTasks = [...pendingTasks, ...completedTasks];

    return Scaffold(
      appBar: AppBar(
        foregroundColor: Colors.white,
        backgroundColor: Colors.orange,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Adicionar uma nova tarefa',
                      ),
                      onSubmitted: _addTask,
                    ),
                  ),
                  const SizedBox(width: 10),
                  FloatingActionButton(
                    onPressed: () => _addTask(_textController.text),
                    tooltip: 'Adicionar Tarefa',
                    child: const Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildTaskBox(
              "Tarefas",
              allTasks,
              onComplete: (task) {
                if (pendingTasks.contains(task)) {
                  _completeTask(task);
                } else {
                  _undoCompleteTask(task);
                }
              },
              onDelete: (task) {
                if (pendingTasks.contains(task)) {
                  _deletePendingTask(task);
                } else {
                  _deleteCompletedTask(task);
                }
              },
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.deepOrange),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskBox(
    String title,
    List<String> tasks, {
    required Function(String) onDelete,
    required Function(String) onComplete,
    required BoxDecoration decoration,
  }) {
    return Expanded(
      child: Container(
        decoration: decoration,
        margin: const EdgeInsets.all(10.0),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: tasks.isEmpty
                  ? const Center(child: Text('Nenhuma tarefa'))
                  : ListView.builder(
                      itemCount: tasks.length,
                      itemBuilder: (context, index) {
                        final task = tasks[index];
                        final isPending = index < pendingTasks.length;
                        final isScheduledForDeletion =
                            scheduledToExclude.contains(task);
                        final remainingSecs =
                            remainingTime[task]?.toString() ?? '';
                        final isCompleted = index >= pendingTasks.length;

                        return Dismissible(
                          background: Container(
                            color: isCompleted ? Colors.blue : Colors.green,
                          ),
                          secondaryBackground: Container(
                            color: Colors.red,
                          ),
                          key: Key('${_counter++}'),
                          onDismissed: (direction) {
                            if (direction == DismissDirection.startToEnd) {
                              if (isCompleted) {
                                _undoCompleteTask(task);
                                _showSnackBarWithCountdown(
                                    'Tarefa "$task" movida de volta para pendentes!',
                                    2);
                              } else {
                                _completeTask(task);
                                _showSnackBarWithCountdown(
                                    'Tarefa "$task" concluída!', 2);
                              }
                            } else if (direction ==
                                DismissDirection.endToStart) {
                              onDelete(task);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 4.0, horizontal: 8.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isScheduledForDeletion
                                    ? Colors.red[300]
                                    : isPending
                                        ? _getPendingTaskColor(index)
                                        : _getCompletedTaskColor(index),
                                borderRadius: BorderRadius.circular(8.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.5),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Tooltip(
                                  message: isCompleted
                                      ? 'Mover de volta para pendentes'
                                      : 'Concluir tarefa',
                                  child: Checkbox(
                                    value: isCompleted,
                                    onChanged: (value) {
                                      if (value == true) {
                                        _completeTask(task);
                                        _showSnackBarWithCountdown(
                                            'Tarefa "$task" concluída!', 2);
                                      } else {
                                        _undoCompleteTask(task);
                                        _showSnackBarWithCountdown(
                                            'Tarefa "$task" movida de volta para pendentes!',
                                            2);
                                      }
                                    },
                                  ),
                                ),
                                title: Text(
                                  task,
                                  style: isScheduledForDeletion
                                      ? const TextStyle(
                                          color: Colors.white,
                                        )
                                      : isPending
                                          ? null
                                          : const TextStyle(
                                              decoration:
                                                  TextDecoration.lineThrough,
                                              color: Colors.grey,
                                            ),
                                ),
                                trailing: isScheduledForDeletion
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '$remainingSecs s',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                          const SizedBox(width: 10),
                                          IconButton(
                                            icon: const Icon(Icons.undo),
                                            color: Colors.white,
                                            onPressed: () =>
                                                _undoDeletion(task, isPending),
                                          ),
                                        ],
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () => onDelete(task),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Função para obter a cor para tarefas pendentes
  Color _getPendingTaskColor(int index) {
    // Alterna entre tons de azul
    return index % 2 == 0 ? Colors.blue[50]! : Colors.blue[100]!;
  }

  // Função para obter a cor para tarefas concluídas
  Color _getCompletedTaskColor(int index) {
    // Alterna entre tons de verde
    return index % 2 == 0 ? Colors.green[50]! : Colors.green[100]!;
  }

  void _showSnackBarWithCountdown(String message, int durationInSeconds) {
    timerSnackbar(
      context: context,
      contentText: message,
      afterExecuteMethod: () => null,
      second: durationInSeconds,
    );
  }

  void timerSnackbar({
    required BuildContext context,
    required String contentText,
    required void Function() afterExecuteMethod,
    int second = 5,
  }) {
    bool isExecute = true;

    final snackbar = SnackBar(
      content: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            constraints: const BoxConstraints(maxHeight: 22.0),
            child: TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: second * 1000.toDouble()),
              duration: Duration(seconds: second),
              builder: (context, double value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        value: value / (second * 1000),
                        color: Colors.grey[850],
                        backgroundColor: Colors.white,
                      ),
                    ),
                    Center(
                      child: Text(
                        (second - (value / 1000)).toInt().toString(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12.0),
          Expanded(child: Text(contentText)),
          InkWell(
            splashColor: Colors.white,
            onTap: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              isExecute = false;
            },
            child: Container(
              color: Colors.grey[850],
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                "Fechar",
                style: TextStyle(color: Colors.blue[100]),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.grey[850],
      duration: Duration(seconds: second),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(6.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4.0),
      ),
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(snackbar);

    Timer(Duration(seconds: second), () {
      if (isExecute) afterExecuteMethod();
    });
  }
}