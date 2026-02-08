import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(_emailController.text.trim());

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo de recuperación enviado'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.error ?? 'Error'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
             mainAxisAlignment: MainAxisAlignment.center,
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               const Text(
                 'Introduce tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                 textAlign: TextAlign.center,
                 style: TextStyle(color: AppColors.textSecondary),
               ),
               const SizedBox(height: 32),
               TextFormField(
                 controller: _emailController,
                 keyboardType: TextInputType.emailAddress,
                 decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                 validator: (v) => v == null || !v.contains('@') ? 'Email inválido' : null,
               ),
               const SizedBox(height: 24),
               ElevatedButton(
                 onPressed: auth.isLoading ? null : _submit,
                 child: auth.isLoading ? const CircularProgressIndicator(color: Colors.black) : const Text('ENVIAR CORREO'),
               ),
             ],
          ),
        ),
      ),
    );
  }
}
