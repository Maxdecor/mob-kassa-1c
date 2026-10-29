import 'package:flutter/material.dart';

import '../api.dart';
import '../models.dart';
import '../state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _url = TextEditingController(text: app.baseUrl);
  final _user = TextEditingController(text: app.user);
  final _pass = TextEditingController();

  bool _busy = false;
  String? _error;
  ServerInfo? _info;
  Ref? _org;
  Ref? _warehouse;
  Ref? _kkm;
  Ref? _priceType;

  @override
  void dispose() {
    _url.dispose();
    _user.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    if (_url.text.trim().isEmpty || _user.text.trim().isEmpty) {
      setState(() => _error = 'Manzil va loginni kiriting.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final info = await Api(_url.text.trim(), _user.text.trim(), _pass.text).info();
      if (!mounted) return;
      setState(() {
        _info = info;
        _org = info.organizations.isNotEmpty ? info.organizations.first : null;
        _warehouse = info.warehouses.isNotEmpty ? info.warehouses.first : null;
        _kkm = info.cashRegisters.isNotEmpty ? info.cashRegisters.first : null;
        _priceType = info.priceTypes.isNotEmpty ? info.priceTypes.first : null;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _enter() async {
    if (_org == null || _warehouse == null || _kkm == null || _priceType == null) {
      setState(() => _error = 'Organizatsiya, ombor, kassa va narx turini tanlang.');
      return;
    }
    await app.signIn(
      baseUrl: _url.text.trim(),
      user: _user.text.trim(),
      pass: _pass.text,
      org: _org!,
      warehouse: _warehouse!,
      kkm: _kkm!,
      priceType: _priceType!,
      canSeeCost: _info?.canSeeCost ?? false,
    );
  }

  Widget _drop(String label, IconData icon, List<Ref> items, Ref? value, ValueChanged<Ref?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DropdownButtonFormField<Ref>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
        ),
        items: [
          for (final r in items) DropdownMenuItem(value: r, child: Text(r.name, overflow: TextOverflow.ellipsis)),
        ],
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(Icons.point_of_sale, size: 56, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(height: 8),
                  Text('Mobil kassa',
                      textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineSmall),
                  const Text('1C:UNF bilan ulanish', textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    enabled: info == null,
                    decoration: const InputDecoration(
                      labelText: 'Server manzili',
                      hintText: 'https://1c.firma.uz/unf',
                      prefixIcon: Icon(Icons.dns_outlined),
                                          ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _user,
                    enabled: info == null,
                    decoration: const InputDecoration(
                      labelText: 'Login',
                      prefixIcon: Icon(Icons.person_outline),
                                          ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _pass,
                    obscureText: true,
                    enabled: info == null,
                    onSubmitted: (_) => info == null ? _connect() : null,
                    decoration: const InputDecoration(
                      labelText: 'Parol',
                      prefixIcon: Icon(Icons.lock_outline),
                                          ),
                  ),
                  if (info != null) ...[
                    _drop('Organizatsiya', Icons.business, info.organizations, _org, (v) => setState(() => _org = v)),
                    _drop('Ombor', Icons.warehouse_outlined, info.warehouses, _warehouse,
                        (v) => setState(() => _warehouse = v)),
                    _drop('Kassa (KKM)', Icons.point_of_sale, info.cashRegisters, _kkm,
                        (v) => setState(() => _kkm = v)),
                    _drop('Narx turi', Icons.sell_outlined, info.priceTypes, _priceType,
                        (v) => setState(() => _priceType = v)),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ],
                  const SizedBox(height: 20),
                  if (info == null)
                    FilledButton(
                      onPressed: _busy ? null : _connect,
                      child: _busy
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Ulanish'),
                    )
                  else ...[
                    FilledButton(onPressed: _enter, child: const Text('Kirish')),
                    TextButton(
                      onPressed: () => setState(() => _info = null),
                      child: const Text('Boshqa serverga ulanish'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
