import 'package:flutter/material.dart';
import 'todo.dart';
import 'database_helper.dart';

class TodoPage extends StatefulWidget {
  const TodoPage({super.key});

  @override
  _TodoPageState createState() => _TodoPageState();
}

class _TodoPageState extends State<TodoPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Todo> _todoList = [];
  List<Todo> _filteredTodoList = [];
  String _searchText = '';
  final Set<int> _selectedTodos = {};

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTodos();

    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text;
        _filterTodos();
      });
    });
  }

  void _fetchTodos() async {
    final todos = await _dbHelper.getTodos();
    setState(() {
      _todoList = todos;
      _filterTodos();
    });
  }

  void _filterTodos() {
    if (_searchText.isEmpty) {
      _filteredTodoList = _todoList;
    } else {
      _filteredTodoList = _todoList
          .where((todo) =>
              todo.title.toLowerCase().contains(_searchText.toLowerCase()))
          .toList();
    }
  }

  void _addOrUpdateTodo({Todo? todo}) {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final descriptionController =
        TextEditingController(text: todo?.description ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[50],
          title: Text(todo == null ? 'Tambah Film' : 'Edit Film'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Film',
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.blueAccent),
                  ),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Simpan'),
              onPressed: () async {
                final title = titleController.text;
                final description = descriptionController.text;

                if (title.isNotEmpty && description.isNotEmpty) {
                  if (todo == null) {
                    await _dbHelper.insertTodo(
                        Todo(title: title, description: description));
                  } else {
                    await _dbHelper.updateTodo(Todo(
                      id: todo.id,
                      title: title,
                      description: description,
                      isCompleted: todo.isCompleted,
                    ));
                  }
                  _fetchTodos();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _confirmDeleteTodoItem(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.blueGrey[50],
          title: const Text('Hapus Item'),
          content: const Text('Apakah Anda yakin ingin menghapus item ini?'),
          actions: [
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                Navigator.of(context).pop();
                await _dbHelper.deleteTodo(id);
                _fetchTodos();

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item berhasil dihapus'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  void _deleteCompletedItems() async {
    await _dbHelper.deleteCompletedTodos();
    _fetchTodos();
  }

  void _toggleCompletion(Todo todo) async {
    await _dbHelper.updateTodo(
      Todo(
        id: todo.id,
        title: todo.title,
        description: todo.description,
        isCompleted: !todo.isCompleted,
      ),
    );
    _fetchTodos();
  }

  void _toggleSelection(int todoId) {
    setState(() {
      if (_selectedTodos.contains(todoId)) {
        _selectedTodos.remove(todoId);
      } else {
        _selectedTodos.add(todoId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Todo List Film',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Cari Film',
                prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.deepPurple),
                ),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _filteredTodoList.length,
                itemBuilder: (context, index) {
                  final todo = _filteredTodoList[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      title: Text(
                        todo.title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: todo.isCompleted ? Colors.grey : Colors.black,
                        ),
                      ),
                      subtitle: Text(todo.description),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blueAccent),
                            onPressed: () => _addOrUpdateTodo(todo: todo),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDeleteTodoItem(todo.id!),
                          ),
                        ],
                      ),
                      leading: Checkbox(
                        value: todo.isCompleted,
                        onChanged: (_) {
                          _toggleCompletion(todo);
                          _toggleSelection(todo.id!);
                        },
                        activeColor: Colors.deepPurple,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_selectedTodos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: ElevatedButton(
                  onPressed: _deleteCompletedItems,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.all(8),
                  ),
                  child: const Text(
                    'Hapus Film Selesai',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () => _addOrUpdateTodo(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }
}
