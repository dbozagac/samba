import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.apiService,
    required this.auth,
    required this.googleSignIn,
  });

  final ApiService apiService;
  final FirebaseAuth auth;
  final GoogleSignIn googleSignIn;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _tcController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _searchController = TextEditingController();

  List<UserModel> users = const [];
  bool loading = false;
  int? editingId;
  String message = '';

  // Pagination state
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;
  String _search = '';
  static const _pageSize = 20;

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
    _searchController.dispose();
    super.dispose();
  }

  Future<String> _token() async {
    final currentUser = widget.auth.currentUser;
    if (currentUser == null) {
      throw Exception('Oturum bulunamadı. Lütfen tekrar giriş yapın.');
    }

    var idToken = await currentUser.getIdToken();
    if (idToken == null || idToken.isEmpty) {
      idToken = await currentUser.getIdToken(true);
    }

    if (idToken == null || idToken.isEmpty) {
      throw Exception('Firebase token alınamadı. Lütfen tekrar giriş yapın.');
    }
    return idToken;
  }

  Future<void> _signOut() async {
    try {
      await widget.auth.signOut();
      try {
        await widget.googleSignIn.disconnect();
      } catch (_) {
        await widget.googleSignIn.signOut();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => message = 'Çıkış başarısız: $e');
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final token = await _token();
      final result = await widget.apiService.listUsers(
        token,
        page: _currentPage,
        pageSize: _pageSize,
        search: _search.isNotEmpty ? _search : null,
      );
      setState(() {
        users = result.items;
        _totalPages = result.totalPages;
        _totalCount = result.totalCount;
        _currentPage = result.page;
      });
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
    } on ApiException catch (e) {
      setState(() => message = e.message);
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

  void _onSearch() {
    setState(() {
      _search = _searchController.text.trim();
      _currentPage = 1;
    });
    _loadUsers();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _search = '';
      _currentPage = 1;
    });
    _loadUsers();
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages) return;
    setState(() => _currentPage = page);
    _loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Samba Mobile'),
        actions: [
          IconButton(
            onPressed: _signOut,
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

                  // ── Form Card ──
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            Text(editingId == null
                                ? 'Yeni Kullanıcı'
                                : 'Kullanıcı Düzenle'),
                            TextFormField(
                              controller: _usernameController,
                              decoration: const InputDecoration(
                                  labelText: 'Kullanıcı adı'),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Zorunlu'
                                      : null,
                            ),
                            TextFormField(
                              controller: _tcController,
                              decoration:
                                  const InputDecoration(labelText: 'TC No'),
                              validator: (value) =>
                                  value != null && value.length == 11
                                      ? null
                                      : '11 hane',
                            ),
                            TextFormField(
                              controller: _emailController,
                              decoration:
                                  const InputDecoration(labelText: 'E-posta'),
                              validator: (value) =>
                                  value != null && value.contains('@')
                                      ? null
                                      : 'Geçersiz',
                            ),
                            TextFormField(
                              controller: _phoneController,
                              decoration:
                                  const InputDecoration(labelText: 'Telefon'),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                      ? 'Zorunlu'
                                      : null,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton(
                                  onPressed: _submit,
                                  child: Text(editingId == null
                                      ? 'Kaydet'
                                      : 'Güncelle'),
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

                  // ── Search Bar ──
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Ad, TC, e-posta veya telefon ile ara…',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            suffixIcon: _search.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                          ),
                          onSubmitted: (_) => _onSearch(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _onSearch,
                        child: const Text('Ara'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // ── User List ──
                  if (users.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            _search.isNotEmpty
                                ? 'Aramanızla eşleşen kayıt bulunamadı.'
                                : 'Henüz kayıt yok.',
                          ),
                        ),
                      ),
                    ),

                  ...users.map(
                    (user) => Card(
                      child: ListTile(
                        title: Text(user.username),
                        subtitle: Text(
                            '${user.email}\nTC: ${user.tcNo} | ${user.phone}'),
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
                  ),

                  // ── Pagination ──
                  if (_totalPages > 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 1
                                ? () => _goToPage(_currentPage - 1)
                                : null,
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Text(
                            'Sayfa $_currentPage / $_totalPages  ($_totalCount kayıt)',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          IconButton(
                            onPressed: _currentPage < _totalPages
                                ? () => _goToPage(_currentPage + 1)
                                : null,
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
