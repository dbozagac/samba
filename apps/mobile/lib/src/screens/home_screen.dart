import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.apiService, required this.user});

  final ApiService apiService;
  final User user;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _tcController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  List<UserModel> users = const [];
  bool loading = false;
  int? editingId;
  String message = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _tcController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<String> _token() => widget.user.getIdToken();

  Future<void> _loadUsers() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final token = await _token();
      final data = await widget.apiService.listUsers(token);
      setState(() => users = data);
    } catch (e) {
      setState(() => message = e.toString());
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final token = await _token();
      if (editingId == null) {
        await widget.apiService.createUser(
          token,
          username: _usernameController.text,
          tcNo: _tcController.text,
          email: _emailController.text,
          phone: _phoneController.text,
        );
        setState(() => message = 'Kullanıcı eklendi.');
      } else {
        await widget.apiService.updateUser(
          token,
          editingId!,
          username: _usernameController.text,
          tcNo: _tcController.text,
          email: _emailController.text,
          phone: _phoneController.text,
        );
        setState(() => message = 'Kullanıcı güncellendi.');
      }

      _clearForm();
      await _loadUsers();
    } catch (e) {
      setState(() => message = e.toString());
    }
  }

  Future<void> _delete(int id) async {
    try {
      final token = await _token();
      await widget.apiService.deleteUser(token, id);
      setState(() => message = 'Kullanıcı silindi.');
      await _loadUsers();
    } catch (e) {
      setState(() => message = e.toString());
    }
  }

  void _startEdit(UserModel user) {
    setState(() {
      editingId = user.id;
      _usernameController.text = user.username;
      _tcController.text = user.tcNo;
      _emailController.text = user.email;
      _phoneController.text = user.phone;
    });
  }

  void _clearForm() {
    setState(() {
      editingId = null;
      _usernameController.clear();
      _tcController.clear();
      _emailController.clear();
      _phoneController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Samba Mobile'),
        actions: [
          IconButton(
            onPressed: () async => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout),
          )
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (message.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(message),
                    ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text(editingId == null ? 'Yeni Kullanıcı' : 'Kullanıcı Düzenle'),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(labelText: 'Kullanıcı adı'),
                              validator: (value) => value == null || value.isEmpty ? 'Zorunlu' : null,
                            ),
                            TextFormField(
                              controller: _tcController,
                              decoration: const InputDecoration(labelText: 'TC No'),
                              validator: (value) => value != null && value.length == 11 ? null : '11 hane',
                            ),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(labelText: 'E-posta'),
                              validator: (value) => value != null && value.contains('@') ? null : 'Geçersiz',
                            ),
                            TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(labelText: 'Telefon'),
                              validator: (value) => value == null || value.isEmpty ? 'Zorunlu' : null,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _submit,
                                  child: Text(editingId == null ? 'Kaydet' : 'Güncelle'),
                                ),
                                const SizedBox(width: 8),
                                if (editingId != null)
                                  OutlinedButton(
                                    onPressed: _clearForm,
                                    child: const Text('İptal'),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...users.map(
                    (user) => Card(
                      child: ListTile(
                        title: Text(user.username),
                        subtitle: Text('${user.email}\nTC: ${user.tcNo} | ${user.phone}'),
                        isThreeLine: true,
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              onPressed: () => _startEdit(user),
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              onPressed: () => _delete(user.id),
                              icon: const Icon(Icons.delete, color: Colors.red),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }
}
