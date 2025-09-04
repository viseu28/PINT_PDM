import 'package:go_router/go_router.dart';
import 'package:projeto_pint/app/screens/auth/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:projeto_pint/app/screens/home/favoritos_page.dart';
import 'package:projeto_pint/app/screens/home/home_page.dart';
import 'package:projeto_pint/app/screens/home/definicoes_page.dart';
import 'package:projeto_pint/app/screens/home/notificacoes_page.dart';
import 'package:projeto_pint/app/screens/home/forum_page.dart';
import 'package:projeto_pint/app/screens/home/perfil_page.dart';
import 'package:projeto_pint/app/screens/home/cursos_page.dart';
import 'package:projeto_pint/app/screens/home/notas_page.dart';
import 'package:projeto_pint/app/screens/home/alterar_password_page.dart';
import 'package:projeto_pint/app/screens/courses/meus_cursos_page.dart';
import 'package:projeto_pint/app/screens/courses/inscricao_form_page.dart';
import 'package:projeto_pint/app/screens/courses/notas_cursos_page.dart';
import 'package:projeto_pint/app/models/curso_model.dart';
import 'package:projeto_pint/app/screens/home/progresso_page.dart';
import 'package:projeto_pint/app/screens/home/curso_detalhe_page.dart';
import 'package:projeto_pint/app/screens/home/percurso_formativo_page.dart';
import 'package:projeto_pint/app/screens/firebase_test_screen.dart';


final GoRouter goRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) async {
    // Só faz redirect no início da app, não durante navegação manual
    if (state.uri.path == '/login') {
      final prefs = await SharedPreferences.getInstance();
      final hasToken = prefs.getString('jwt_token') != null;
      final isMarkedLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      // Se tem token e está marcado como logado, vai para home
      if (hasToken && isMarkedLoggedIn) {
        return '/home';
      }
    }
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(path: '/home', builder: (context, state) => HomePage()),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/alterar-password',
      builder: (context, state) => const AlterarPasswordPage(),
    ),
    GoRoute(
      path: '/favoritos',
      builder: (context, state) => const FavoritosPage(),
    ),
    GoRoute(
      path: '/notificacoes',
      builder: (context, state) => NotificacoesPage(),
    ),
    GoRoute(
      path: '/firebase-test',
      builder: (context, state) => const FirebaseTestScreen(),
    ),
    GoRoute(path: '/forum', builder: (context, state) => ForumPage()),
    GoRoute(path: '/perfil', builder: (context, state) => PerfilPage()),
    GoRoute(path: '/cursos', builder: (context, state) => CoursesScreen()),
    GoRoute(
      path: '/notas-cursos',
      builder: (context, state) => GradesCoursesScreen(),
    ),
    GoRoute(
      path: '/notas',
      builder: (context, state) {
        final args = state.extra;

        if (args is! Map<String, dynamic>) {
          throw ArgumentError('Esperava um Map<String, dynamic> como extra.');
        }

        final curso = args['curso'];
        final userid = args['userid'];

        if (curso is! Curso || userid is! int) {
          throw ArgumentError(
            'Argumentos inválidos: curso ou userid não fornecidos corretamente.',
          );
        }

        return GradesScreen(curso: curso, userid: userid);
      },
    ),

    GoRoute(
      path: '/meus-cursos',
      builder: (context, state) => const MeusCursosPage(),
    ),
    GoRoute(
      path: '/inscricao',
      builder: (context, state) {
        final curso = state.extra as Curso;
        return InscricaoFormPage(curso: curso);
      },
    ),
    GoRoute(
      name: 'curso_detalhe',
      path: '/curso_detalhe',
      builder: (context, state) {
        
        final curso = state.extra as Curso;
        return CursoDetalhePage(curso: curso);
      },
    ),
    GoRoute(
      path: '/progresso',
      builder: (context, state) => const ProgressoPage(),
    ),
    GoRoute(
      path: '/percurso-formativo/:id',
      builder: (context, state) {
        final id = int.parse(state.pathParameters['id']!);
        return PercursoFormativoPage(idUtilizador: id);
      },
    ),
  ],
);