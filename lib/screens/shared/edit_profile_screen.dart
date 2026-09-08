import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_provider.dart';
import '../../models/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _name;
  late TextEditingController _department;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _name = TextEditingController(text: user?.fullName ?? '');
    _department = TextEditingController(text: user?.department ?? '');
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final res = await ApiService.post('users/update_profile.php', {
      'full_name': _name.text.trim(),
      'department': _department.text.trim(),
    });
    setState(() => _loading = false);
    if (!mounted) return;

    if (res['success'] == true) {
      final auth = context.read<AuthProvider>();
      final current = auth.user!;
      await auth.setUser(AppUser(
        id: current.id,
        fullName: _name.text.trim(),
        email: current.email,
        department: _department.text.trim(),
        role: current.role,
        profilePhoto: current.profilePhoto,
        status: current.status,
      ));
      if (!mounted) return;
      Navigator.of(context).pop();
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? '')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Full Name', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _name),
            const SizedBox(height: 16),
            const Text('Department', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(controller: _department),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              child: _loading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }
}
