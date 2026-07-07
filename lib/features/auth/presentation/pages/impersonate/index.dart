import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:progress_group/core/constants/colors.dart';
import 'package:progress_group/core/utils/widget/custom_snackbar.dart';
import 'package:progress_group/features/auth/data/models/impersonatable_user_model.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_bloc.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_event.dart';
import 'package:progress_group/features/auth/presentation/state/auth/auth_state.dart';



class ImpersonatePage extends StatefulWidget {
  const ImpersonatePage({super.key});

  @override
  State<ImpersonatePage> createState() => _ImpersonatePageState();
}

class _ImpersonatePageState extends State<ImpersonatePage> {
  final TextEditingController _searchTC = TextEditingController();
  Timer? _debounce;

  
  
  List<ImpersonatableUser> _users = [];
  bool _loadingList = true; 
  String? _listError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(LoadImpersonatableUsersEvent());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchTC.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<AuthBloc>().add(LoadImpersonatableUsersEvent(search: value.trim()));
    });
  }

  void _confirmImpersonate(ImpersonatableUser user) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Masuk sebagai user ini?'),
        content: Text(
          'Anda akan masuk sebagai "${user.fullName}"'
          '${user.roleName != null ? ' (${user.roleName})' : ''}.\n'
          '${(user.detail ?? '').isNotEmpty ? '${user.detail}\n' : ''}'
          '\n'
          'Aplikasi akan menampilkan data & izin milik user tersebut. '
          'Gunakan tombol "Keluar" pada banner untuk kembali ke akun admin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<AuthBloc>().add(ImpersonateEvent(user.userId));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(primaryColor)),
            child: const Text('Masuk', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Login Sebagai User'),
        backgroundColor: Color(primaryColor),
        foregroundColor: Colors.white,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            curr is ImpersonatableUsersLoading ||
            curr is ImpersonatableUsersLoaded ||
            curr is ImpersonatableUsersError ||
            curr is ImpersonationInProgress ||
            curr is ImpersonationFailure,
        listener: (context, state) {
          if (state is ImpersonatableUsersLoading) {
            setState(() { _loadingList = true; _listError = null; });
          } else if (state is ImpersonatableUsersLoaded) {
            setState(() {
              _loadingList = false;
              _listError = null;
              _users = state.users.cast<ImpersonatableUser>();
            });
          } else if (state is ImpersonatableUsersError) {
            setState(() { _loadingList = false; _listError = state.message; });
          } else if (state is ImpersonationInProgress) {
            setState(() => _busy = true);
          } else if (state is ImpersonationFailure) {
            setState(() => _busy = false);
            showSnackbar(context, state.message, isError: true);
          }
          
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: _searchTC,
                onChanged: _onSearchChanged,
                enabled: !_busy,
                decoration: InputDecoration(
                  hintText: 'Cari nama / username / email…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
            ),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loadingList) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_listError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_listError!, textAlign: TextAlign.center),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () => context.read<AuthBloc>().add(
                  LoadImpersonatableUsersEvent(search: _searchTC.text.trim())),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
    }
    if (_users.isEmpty) {
      return const Center(child: Text('Tidak ada user.'));
    }
    return ListView.separated(
      itemCount: _users.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
      itemBuilder: (context, i) {
        final u = _users[i];
        return ListTile(
          enabled: !_busy,
          leading: CircleAvatar(
            backgroundColor: Color(primaryColor),
            child: Text(
              u.fullName.isNotEmpty ? u.fullName[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
          isThreeLine: (u.detail ?? '').isNotEmpty || (u.email ?? '').isNotEmpty,
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((u.detail ?? '').isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    u.detail!,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(primaryColor),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              Text(
                '@${u.username}'
                '${u.roleName != null && u.roleName!.isNotEmpty ? ' • ${u.roleName}' : ''}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
              if ((u.email ?? '').isNotEmpty)
                Text(
                  u.email!,
                  style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                ),
            ],
          ),
          trailing: const Icon(Icons.login, size: 20),
          onTap: _busy ? null : () => _confirmImpersonate(u),
        );
      },
    );
  }
}
