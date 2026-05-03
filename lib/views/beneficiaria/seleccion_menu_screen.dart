import 'package:alimenta_peru/core/constants/app_colors.dart';
import 'package:alimenta_peru/models/menu_model.dart';
import 'package:alimenta_peru/viewmodels/auth_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/menu_viewmodel.dart';
import 'package:alimenta_peru/viewmodels/reserva_viewmodel.dart';
import 'package:alimenta_peru/views/beneficiaria/confirmacion_reserva_screen.dart';
import 'package:alimenta_peru/views/shared/widgets/app_button.dart';
import 'package:alimenta_peru/views/shared/widgets/empty_state.dart';
import 'package:alimenta_peru/views/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Pantalla de selección de menú diario.
/// Basada en 03-seleccion-racion.png
class SeleccionMenuScreen extends StatefulWidget {
  const SeleccionMenuScreen({super.key});

  @override
  State<SeleccionMenuScreen> createState() => _SeleccionMenuScreenState();
}

class _SeleccionMenuScreenState extends State<SeleccionMenuScreen> {
  int _navIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authVM = context.read<AuthViewModel>();
      // Usamos un comedor demo; en producción vendría del perfil del usuario
      final comedorId =
          (authVM.usuario as dynamic)?.comedorId ?? 'comedor_santa_rosa';
      context.read<MenuViewModel>().cargarMenus(comedorId);

      final uid = authVM.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        context.read<ReservaViewModel>().suscribirAReservas(uid);
      }
    });
  }

  Future<void> _onReservar(BuildContext ctx, MenuModel menu) async {
    final authVM = ctx.read<AuthViewModel>();
    final reservaVM = ctx.read<ReservaViewModel>();
    final uid = authVM.currentUser?.uid ?? '';

    if (uid.isEmpty) {
      _showError(ctx, 'Debes iniciar sesión para reservar');
      return;
    }

    final ok = await reservaVM.crearReserva(
      menuId: menu.id,
      beneficiariaId: uid,
      comedorId: menu.comedorId,
      turno: '12:00pm - 1:00pm',
    );

    if (!ctx.mounted) return;
    if (ok) {
      final reserva = reservaVM.reservaActual;
      if (reserva != null) {
        Navigator.push(
          ctx,
          MaterialPageRoute(
            builder: (_) => ConfirmacionReservaScreen(
              menu: menu,
              reservaId: reserva.id,
              codigoQR: reserva.codigoQR,
              turno: reserva.turno,
              numRaciones: reserva.numRaciones,
            ),
          ),
        );
      }
    } else {
      _showError(ctx, reservaVM.error ?? 'Error al crear la reserva');
    }
  }

  void _showError(BuildContext ctx, String msg) {
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mesActual = DateFormat('MMMM yyyy', 'es').format(DateTime.now());

    return Consumer2<MenuViewModel, ReservaViewModel>(
      builder: (context, menuVM, reservaVM, _) {
        final cargando = menuVM.cargando || reservaVM.cargando;

        return LoadingOverlay(
          visible: cargando,
          child: Scaffold(
            backgroundColor: AppColors.backgroundLight,
            body: Column(
              children: [
                // ── Header verde ──────────────────────────────────────
                Container(
                  width: double.infinity,
                  color: AppColors.primaryGreen,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 20,
                    right: 20,
                    bottom: 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.maybePop(context),
                        child: const Icon(Icons.arrow_back,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined,
                              color: Colors.white, size: 28),
                          const SizedBox(width: 10),
                          Text(
                            'Seleccionar Menú',
                            style: GoogleFonts.nunito(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        // Capitaliza primera letra
                        '${mesActual[0].toUpperCase()}${mesActual.substring(1)}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.85),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Lista de menús ────────────────────────────────────
                Expanded(
                  child: menuVM.menus.isEmpty && !menuVM.cargando
                      ? const EmptyState(
                          emoji: '🍽️',
                          mensaje: 'Sin menús disponibles',
                          subtitulo:
                              'La administradora aún no ha publicado menús para este mes.',
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          itemCount: menuVM.menus.length,
                          itemBuilder: (ctx, i) {
                            final menu = menuVM.menus[i];
                            return _MenuCard(
                              menu: menu,
                              onReservar: () => _onReservar(ctx, menu),
                            );
                          },
                        ),
                ),
              ],
            ),
            bottomNavigationBar: _BottomNav(
              currentIndex: _navIndex,
              onTap: (i) => setState(() => _navIndex = i),
            ),
          ),
        );
      },
    );
  }
}

/// Tarjeta de menú individual.
class _MenuCard extends StatelessWidget {
  final MenuModel menu;
  final VoidCallback onReservar;

  const _MenuCard({required this.menu, required this.onReservar});

  @override
  Widget build(BuildContext context) {
    final diasSemana = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final diaSemana = diasSemana[menu.fecha.weekday - 1];
    final diaMes = menu.fecha.day;
    final agotado = menu.racionesDisponibles == 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: agotado
              ? AppColors.borderNeutral
              : AppColors.primaryGreen.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fila superior: badge día + nombre + raciones ───────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge día
                Container(
                  width: 62,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: agotado
                        ? AppColors.borderNeutral
                        : const Color(0xFFD1FAE5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        diaSemana,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: agotado
                              ? AppColors.textSecondary
                              : AppColors.primaryGreen,
                        ),
                      ),
                      Text(
                        '$diaMes',
                        style: GoogleFonts.nunito(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: agotado
                              ? AppColors.textSecondary
                              : AppColors.primaryGreen,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        menu.nombrePlato,
                        style: GoogleFonts.nunito(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.group_outlined,
                              size: 16,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            agotado
                                ? 'Sin raciones disponibles'
                                : '${menu.racionesDisponibles} raciones disponibles',
                            style: GoogleFonts.nunito(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Imagen placeholder amarilla ────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFDE68A), Color(0xFFFBBF24)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Icon(Icons.restaurant_menu,
                      size: 40, color: Color(0xFFF59E0B)),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Botón reservar ─────────────────────────────────────────
            AppButton(
              texto: agotado ? 'Agotado' : 'Reservar',
              onPressed: agotado ? null : onReservar,
              color: AppColors.primaryGreen,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      selectedItemColor: AppColors.primaryGreen,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: GoogleFonts.nunito(fontWeight: FontWeight.w700),
      unselectedLabelStyle: GoogleFonts.nunito(),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.calendar_month_outlined),
          activeIcon: Icon(Icons.calendar_month),
          label: 'Reservar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Inicio',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
