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
      headers: {'Content-Type': 'application/json'},
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
                  Navigator.pushNamed(context, '/signup');
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
    return 'ok';
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
  final _phoneController = TextEditingController();
  String _errorMessage = '';

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

    final result = await signUp(name, email, password, phone);

    if (result == 'ok') {
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
        _errorMessage = result;
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
              controller: _phoneController,
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
    return 'ok';
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
  final List<String> tasks = [];
  int? lastPendingTaskIndex;
  int? firstCompletedTaskIndex;
  final Set<String> scheduledToExclude = {};
  final Map<String, int> remainingTime = {};
  final _textController = TextEditingController();
  Map<String, Timer?> activeTimers = {};
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  @override
  void initState() {
    super.initState();
    _loadUserTasks();
  }

  bool isScheduledForDeletion(String task) {
    return scheduledToExclude.contains(task);
  }

  int? lastPendingTask() {
    return lastPendingTaskIndex;
  }

  int? firstCompletedTask() {
    return firstCompletedTaskIndex;
  }

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
          final pendingTasks = List<String>.from(userTasks['pendingTasks']);
          final completedTasks = List<String>.from(userTasks['completedTasks']);
          tasks.addAll(pendingTasks);
          tasks.addAll(completedTasks);

          lastPendingTaskIndex =
              pendingTasks.isNotEmpty ? pendingTasks.length - 1 : null;

          if (pendingTasks.isEmpty) {
            firstCompletedTaskIndex = completedTasks.isNotEmpty ? 0 : null;
          } else {
            firstCompletedTaskIndex =
                completedTasks.isNotEmpty ? pendingTasks.length : null;
          }
        } else {
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
      'pendingTasks': lastPendingTaskIndex != null
          ? tasks.sublist(0, lastPendingTaskIndex! + 1)
          : [],
      'completedTasks': firstCompletedTaskIndex != null
          ? tasks.sublist(firstCompletedTaskIndex!)
          : [],
    };

    final response = await http.patch(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.token}',
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

  void _addTask(String task) {
    setState(() {
      if (task.trim().isEmpty) {
        _showSnackBarWithCountdown(
            'Não é possível inserir tarefa com título vazio!', 2);
      } else if (tasks.contains(task.trim())) {
        _showSnackBarWithCountdown(
            'Já existe uma tarefa com este mesmo título na lista!', 2);
      } else {
        tasks.insert(0, task.trim());
        _listKey.currentState
            ?.insertItem(0, duration: Duration(milliseconds: 500));
        lastPendingTaskIndex = (lastPendingTaskIndex ?? -1) + 1;
        if (firstCompletedTaskIndex != null) {
          firstCompletedTaskIndex = firstCompletedTaskIndex! + 1;
        }
        _textController.clear();
        _updateTasksOnServer();
        _showSnackBarWithCountdown('Tarefas sincronizadas com o servidor!', 1);
      }
    });
  }

  void _animateTaskCompletion(int oldIndex, int insertIndex, String task) {
    final itemHeight =
        50.0; // Altura de cada item da lista (ajuste conforme necessário)
    final position =
        (insertIndex - oldIndex) * itemHeight; // Distância de movimento

    // Remover o item com animação
    _listKey.currentState?.removeItem(
      oldIndex,
      (context, animation) {
        final offsetAnimation = Tween<Offset>(
          begin: Offset(0.0, 0.0),
          end: Offset(0.0, position),
        ).animate(animation);
        return SlideTransition(
            position: offsetAnimation,
            child: _buildTaskTileWithAnimation(task, oldIndex, animation));
      },
    );

    _listKey.currentState?.insertItem(
      insertIndex,
      duration: Duration(seconds: 1),
    );
  }

  void _completeTask(String task) {
    setState(() {
      int oldIndex = tasks.indexOf(task);
      int insertIndex = lastPendingTaskIndex ?? lastPendingTaskIndex!;
      if (lastPendingTaskIndex != null && lastPendingTaskIndex! > 0) {
        lastPendingTaskIndex = lastPendingTaskIndex! - 1;
      } else {
        lastPendingTaskIndex = null;
      }
      firstCompletedTaskIndex =
          (lastPendingTaskIndex == null) ? 0 : lastPendingTaskIndex! + 1;
      tasks.remove(task);
      tasks.insert(insertIndex, task);
      _animateTaskCompletion(oldIndex, insertIndex, task);
      _updateTasksOnServer();
      _showSnackBarWithCountdown('Tarefas sincronizadas com o servidor!', 1);
    });
  }

  void _undoCompleteTask(String task) {
    setState(() {
      int oldTaskIndex = tasks.indexOf(task);
      int insertIndex = (lastPendingTaskIndex ?? -1) + 1;
      tasks.remove(task);
      tasks.insert(insertIndex, task);
      lastPendingTaskIndex = (lastPendingTaskIndex ?? -1) + 1;
      if ((oldTaskIndex == tasks.length - 1) &&
          (oldTaskIndex == firstCompletedTaskIndex)) {
        firstCompletedTaskIndex = null;
      } else {
        firstCompletedTaskIndex = firstCompletedTaskIndex! + 1;
      }
      _updateTasksOnServer();
      _showSnackBarWithCountdown('Tarefas sincronizadas com o servidor!', 1);
    });
  }

  void _scheduleTaskDeletion(String task, bool isPending) {
    setState(() {
      scheduledToExclude.add(task);
      remainingTime[task] = 3;
      activeTimers[task]?.cancel();
      activeTimers[task] = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          if (remainingTime[task]! > 0) {
            remainingTime[task] = remainingTime[task]! - 1;
          } else {
            timer.cancel();
            if (scheduledToExclude.contains(task)) {
              _finalizeDeletion(task, isPending);
            }
            activeTimers.remove(task);
          }
        });
      });
    });
  }

  void _undoDeletion(String task) {
    setState(() {
      scheduledToExclude.remove(task);
      activeTimers[task]?.cancel();
      activeTimers.remove(task);
    });
  }

  void _finalizeDeletion(String task, bool isPending) {
    setState(() {
      scheduledToExclude.remove(task);
      remainingTime.remove(task);
      int index = tasks.indexOf(task);
      int oldLength = tasks.length;
      tasks.remove(task);
      if (index < oldLength - 1) {
        _listKey.currentState?.removeItem(
          index,
          (context, animation) {
            return _buildTaskTile(task, index, animation);
          },
          duration: const Duration(milliseconds: 500),
        );
      }
      if (isPending) {
        if (lastPendingTaskIndex == 0) {
          lastPendingTaskIndex = null;
        } else if (lastPendingTaskIndex == null) {
          lastPendingTaskIndex = null;
        } else {
          lastPendingTaskIndex = lastPendingTaskIndex! - 1;
        }

        if (firstCompletedTaskIndex != null) {
          firstCompletedTaskIndex = firstCompletedTaskIndex! - 1;
        }
      } else if (!isPending) {
        if (lastPendingTaskIndex == null && index > firstCompletedTaskIndex!) {
          firstCompletedTaskIndex = firstCompletedTaskIndex;
        } else if (lastPendingTaskIndex == null &&
            firstCompletedTaskIndex == oldLength - 1) {
          firstCompletedTaskIndex = null;
        } else if (index >= firstCompletedTaskIndex! && lastPendingTaskIndex != null) {
          if (index < oldLength - 1) {
            print('caso 3');
            firstCompletedTaskIndex = firstCompletedTaskIndex;
          } else if ((index == oldLength - 1) && (index == firstCompletedTaskIndex!)) {
            print('caso 4');
            firstCompletedTaskIndex = null;
          }
          else if ((index == oldLength - 1) && (index > firstCompletedTaskIndex!)) {
            print('caso 5');
            firstCompletedTaskIndex = firstCompletedTaskIndex;
          }
        }
      }
      _updateTasksOnServer();
      _showSnackBarWithCountdown('Tarefas sincronizadas com o servidor!', 1);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Widget _buildTaskTileWithAnimation(
      String task, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // Animação para a "descida" da tarefa
        final slideAnimation = Tween<Offset>(
          begin: Offset(0, -1), // Começa um pouco acima
          end: Offset(0, 0), // Vai até a posição final
        ).animate(animation);

        // Animação de inclinação para dar o efeito de hover
        final rotateAnimation =
            Tween<double>(begin: 0, end: -0.05).animate(animation);

        return SlideTransition(
          position: slideAnimation,
          child: RotationTransition(
            turns: rotateAnimation, // Tilt (inclinação)
            child: _buildTaskTile(task, index, animation),
          ),
        );
      },
    );
  }

  Widget _buildTaskTile(String task, int index, Animation<double> animation) {
    final remainingSecs = remainingTime[task]?.toString() ?? '';
    bool isPending =
        lastPendingTaskIndex != null && index <= lastPendingTaskIndex!;
    return FadeTransition(
      opacity: animation,
      child: SizeTransition(
        sizeFactor: animation,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Dismissible(
            key: Key('${tasks[index].hashCode}'),
            background:
                Container(color: isPending ? Colors.green : Colors.blue),
            secondaryBackground: Container(color: Colors.red),
            onDismissed: (direction) {
              setState(() {
                if (direction == DismissDirection.startToEnd) {
                  if (isPending) {
                    _completeTask(task);
                    _showSnackBarWithCountdown('Tarefa "$task" concluída!', 2);
                  } else {
                    _undoCompleteTask(task);
                    _showSnackBarWithCountdown(
                        'Tarefa "$task" movida de volta para pendentes!', 2);
                  }
                } else if (direction == DismissDirection.endToStart) {
                  _scheduleTaskDeletion(task, isPending);
                }
              });
            },
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: () {
                    if (isScheduledForDeletion(task)) {
                      return Colors.red[300];
                    } else if (lastPendingTask() != null &&
                        index <= lastPendingTask()!) {
                      return _getPendingTaskColor(index);
                    } else if (firstCompletedTask() != null &&
                        index >= firstCompletedTask()!) {
                      return _getCompletedTaskColor(index);
                    }
                    return null;
                  }(),
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
                    message: isPending
                        ? 'Concluir tarefa'
                        : 'Mover de volta para pendentes',
                    child: Checkbox(
                      value: () {
                        if (lastPendingTask() != null &&
                            index <= lastPendingTask()!) {
                          return false;
                        } else if (firstCompletedTask() != null &&
                            index >= firstCompletedTask()!) {
                          return true;
                        }
                      }(),
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
                    style: () {
                      if (isScheduledForDeletion(task)) {
                        return const TextStyle(color: Colors.white);
                      } else if (lastPendingTask() != null &&
                          index <= lastPendingTask()!) {
                        return null;
                      } else if (firstCompletedTask() != null &&
                          index >= firstCompletedTask()!) {
                        return const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey,
                        );
                      }
                      return null;
                    }(),
                  ),
                  trailing: isScheduledForDeletion(task)
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$remainingSecs s',
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.undo),
                              color: Colors.white,
                              onPressed: () => _undoDeletion(task),
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () =>
                              _scheduleTaskDeletion(task, isPending),
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              tasks,
              decoration: BoxDecoration(
                color: Colors.orange[50],
                border: Border.all(color: Colors.deepOrange),
                borderRadius: BorderRadius.circular(8.0),
              ),
              lastPendingTaskIndex: lastPendingTaskIndex,
              firstCompletedTaskIndex: firstCompletedTaskIndex,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskBox(
    String title,
    List<String> tasks, {
    required BoxDecoration decoration,
    int? lastPendingTaskIndex,
    int? firstCompletedTaskIndex,
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
                  : AnimatedList(
                      key: _listKey,
                      initialItemCount: tasks.length,
                      itemBuilder: (context, index, animation) {
                        final task = tasks[index];
                        return _buildTaskTile(task, index, animation);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBarWithCountdown(String message, int durationInSeconds) {
    timerSnackbar(
      context: context,
      contentText: message,
      afterExecuteMethod: () => null,
      second: durationInSeconds,
    );
  }
}

Color _getPendingTaskColor(int index) {
  return index % 2 == 0 ? Colors.blue[50]! : Colors.blue[100]!;
}

Color _getCompletedTaskColor(int index) {
  return index % 2 == 0 ? Colors.green[50]! : Colors.green[100]!;
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
