import 'package:flutter/material.dart';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.orange,
      ),
      home: const MyHomePage(title: 'Lista de Tarefas'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({
    super.key,
    required this.title,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final List<String> pendingTasks = [];
  final List<String> completedTasks = [];
  final Set<String> scheduledToExclude = {};
  final Map<String, int> remainingTime = {};
  final textController = TextEditingController();
  Map<String, Timer?> activeTimers = {};
  int _counter = 0;

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
        textController.clear();
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
          activeTimers.remove(task); // Remove o timer após finalizar a exclusão
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
      } else {
        completedTasks.remove(task);
        _showSnackBarWithCountdown('Tarefa "$task" excluída das concluídas', 2);
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
    });
  }

  void _undoCompleteTask(String task) {
    setState(() {
      completedTasks.remove(task);
      pendingTasks.insert(0, task);
    });
  }

  @override
  void dispose() {
    textController.dispose();
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
                      controller: textController,
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
                    onPressed: () => _addTask(textController.text),
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
                                          onPressed: () => _undoDeletion(
                                              task, isPending),
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
