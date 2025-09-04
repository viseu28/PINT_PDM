import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:projeto_pint/app/screens/home/cursos_page.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:projeto_pint/app/services/api_service.dart';
import 'package:projeto_pint/app/routes/route_names.dart';
import 'package:projeto_pint/app/screens/courses/notas_cursos_page.dart';
import 'package:projeto_pint/app/widgets/notification_badge.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final PageController _pageController = PageController(
    initialPage: 1,
  ); // Começa na imagem central

  @override
  void initState() {
    super.initState();
    _sincronizarComAPI();
  }

  void _sincronizarComAPI() async {
    await ApiService.descarregarCursosDaAPI();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w400,
              color: Colors.black,
              fontFamily: 'Roboto',
            ),
            children: [
              TextSpan(
                text: 'Soft',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w300,
                ),
              ),
              TextSpan(
                text: 'Skills',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        centerTitle: false,
        actions: [
          // Ícone de notificações com badge
          const NotificationBadge(),
          IconButton(
            icon: Icon(
              Icons.account_circle_outlined,
              color: Colors.black,
              size: 28,
            ),
            onPressed: () async {
              context.go('/perfil');
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Expanded(
              child: PageView(
                controller: _pageController,
                children: [
                  _buildCarouselItem('progresso.png', context, 0),
                  _buildCarouselItem('cursos.png', context, 1),
                  _buildCarouselItem('notas.png', context, 2),
                ],
              ),
            ),
            SizedBox(height: 18),
            SmoothPageIndicator(
              controller: _pageController,
              count: 3,
              effect: WormEffect(
                dotColor: Colors.grey.shade300,
                activeDotColor: Colors.blue,
                spacing: 6.0,
                radius: 3.0,
                dotHeight: 6.0,
                dotWidth: 18.0,
              ),
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey,
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey.shade400,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          elevation: 0,
          currentIndex: 0,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: ""),
            BottomNavigationBarItem(
              icon: Icon(Icons.forum_outlined),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bookmark_border),
              label: "",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: "",
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                // Já está na home
                break;
              case 1:
                context.go(RouteNames.forum);
                break;
              case 2:
                context.go(RouteNames.favoritos);
                break;
              case 3:
                context.go(RouteNames.settings);
                break;
              default:
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildCarouselItem(String imagePath, BuildContext context, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Image.asset(
              'assets/$imagePath',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: _buildNavigationButton(context, index),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButton(BuildContext context, int index) {
    final Map<int, Map<String, dynamic>> buttonData = {
      0: {
        'text': 'Ir para progresso',
        'route': '/progresso', // Rota para progresso (criar se necessário)
        'screen': (),
        'icon': Icons.show_chart,
      },
      1: {
        'text': 'Ir para cursos',
        'route': '/cursos',
        'screen': CoursesScreen(),
        'icon': Icons.menu_book_outlined,
      },
      2: {
        'text': 'Ir para notas',
        'route': '/notas-cursos', // Rota para notas (criar se necessário)
        'screen': GradesCoursesScreen(),
        'icon': Icons.grade_outlined,
      },
    };

    return ElevatedButton.icon(
      onPressed: () {
        final route = buttonData[index]!['route'] as String?;
        if (route != null) {
          // Usar GoRouter se a rota estiver definida
          context.go(route);
        } else {
          // Fallback para Navigator.push
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => buttonData[index]!['screen']),
          );
        }
      },
      icon: Icon(buttonData[index]!['icon'], size: 22, color: Colors.blue),
      label: Text(
        buttonData[index]!['text'],
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black,
          fontFamily: 'Roboto',
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blue,
        elevation: 2,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.black12,
      ),
    );
  }
}