import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';

class AlterarPasswordPage extends StatefulWidget {
  const AlterarPasswordPage({super.key});

  @override
  State<AlterarPasswordPage> createState() => _AlterarPasswordPageState();
}

class _AlterarPasswordPageState extends State<AlterarPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordAtualController = TextEditingController();
  final _novaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();
  
  bool _obscurePasswordAtual = true;
  bool _obscureNovaPassword = true;
  bool _obscureConfirmarPassword = true;
  bool _isLoading = false;
  bool _isPrimeiraAlteracao = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await AuthService.getCurrentUser();
      setState(() {
        _isPrimeiraAlteracao = user?.temQueAlterarPassword ?? false;
      });
    } catch (e) {
      print('Erro ao carregar dados do utilizador: $e');
    }
  }

  @override
  void dispose() {
    _passwordAtualController.dispose();
    _novaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _alterarPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final passwordAtual = _passwordAtualController.text;
      final novaPassword = _novaPasswordController.text;

      final sucesso = await AuthService.alterarPassword(
        passwordAtual: passwordAtual,
        novaPassword: novaPassword,
      );

      if (sucesso) {
        if (mounted) {
          // Mostrar mensagem de sucesso
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password alterada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );

          // Se era primeira alteração, redirecionar para home
          if (_isPrimeiraAlteracao) {
            context.go('/home');
          } else {
            // Senão, voltar para definições
            context.pop();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar password: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Alterar Password'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informação sobre primeira alteração
              if (_isPrimeiraAlteracao) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Primeira alteração de password',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Este é o seu primeiro acesso. Por favor, defina uma nova password segura.',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Password atual (apenas se não for primeira alteração)
              if (!_isPrimeiraAlteracao) ...[
                const Text(
                  'Password Atual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordAtualController,
                  obscureText: _obscurePasswordAtual,
                  decoration: InputDecoration(
                    hintText: 'Digite a sua password atual',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePasswordAtual
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () {
                        setState(() {
                          _obscurePasswordAtual = !_obscurePasswordAtual;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, digite a password atual';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
              ],

              // Nova password
              const Text(
                'Nova Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _novaPasswordController,
                obscureText: _obscureNovaPassword,
                decoration: InputDecoration(
                  hintText: 'Digite a nova password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNovaPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureNovaPassword = !_obscureNovaPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, digite a nova password';
                  }
                  if (value.length < 6) {
                    return 'A password deve ter pelo menos 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Confirmar nova password
              const Text(
                'Confirmar Nova Password',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _confirmarPasswordController,
                obscureText: _obscureConfirmarPassword,
                decoration: InputDecoration(
                  hintText: 'Confirme a nova password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmarPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmarPassword = !_obscureConfirmarPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, confirme a nova password';
                  }
                  if (value != _novaPasswordController.text) {
                    return 'As passwords não coincidem';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Botão de alterar
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _alterarPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Alterar Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              // Dicas de segurança
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Dicas para uma password segura:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Use pelo menos 8 caracteres\n'
                      '• Combine letras maiúsculas e minúsculas\n'
                      '• Inclua números e símbolos\n'
                      '• Evite informações pessoais',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
