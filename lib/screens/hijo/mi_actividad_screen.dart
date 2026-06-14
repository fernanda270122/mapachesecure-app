import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';
import 'package:mapachesecure_app/providers/actividad_provider.dart'; // Tu nuevo provider
import 'package:usage_stats/usage_stats.dart';

class MiActividadScreen extends StatefulWidget {
  const MiActividadScreen({super.key});

  @override
  State<MiActividadScreen> createState() => _MiActividadScreenState();
}

class _MiActividadScreenState extends State<MiActividadScreen> {
  @override
  void initState() {
    super.initState();
    // Ejecuta la lectura real de UsageStats al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActividadProvider>().obtenerActividadDelDia();
    });
  }

  String _formatDuration(Duration duration) {
    int horas = duration.inHours;
    int minutos = duration.inMinutes.remainder(60);
    if (horas > 0) return '${horas}h ${minutos}m';
    return '$minutos min';
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>().colores;
    final actividadProd = context.watch<ActividadProvider>();

    final tiempoTotalStr = _formatDuration(actividadProd.tiempoTotalPantalla);
    const limitePermitidoHoras = 3;
    final porcentajeTotal =
        (actividadProd.tiempoTotalPantalla.inMinutes /
                (limitePermitidoHoras * 60))
            .clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: tema.background,
      appBar: AppBar(
        title: const Text('Mi Actividad'),
        backgroundColor: tema.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: actividadProd.cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => actividadProd.obtenerActividadDelDia(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Cómo vas hoy?',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: tema.onBackground,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Tarjeta con la suma de tiempos reales de UsageStats
                    _buildTotalTimeCard(
                      tema.accent,
                      tiempoTotalStr,
                      porcentajeTotal,
                    ),

                    const SizedBox(height: 30),

                    Text(
                      'Tiempo por Aplicación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: tema.onBackground,
                      ),
                    ),
                    const SizedBox(height: 15),

                    // Lista generada dinámicamente con los paquetes del celular
                    actividadProd.listaUsoReal.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              'No hay registro de aplicaciones usadas hoy.',
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: actividadProd.listaUsoReal.length,
                            itemBuilder: (context, index) {
                              final UsageInfo appReal =
                                  actividadProd.listaUsoReal[index];
                              final milis = int.parse(
                                appReal.totalTimeInForeground ?? '0',
                              );
                              final duracionApp = Duration(milliseconds: milis);

                              // Buscamos si el paquete coincide con tus _appsPopulares
                              final infoVisual = actividadProd.appsPopulares
                                  .firstWhere(
                                    (element) =>
                                        element['package'] ==
                                        appReal.packageName,
                                    orElse: () => {
                                      'nombre':
                                          appReal.packageName
                                              ?.split('.')
                                              .last ??
                                          'Desconocida',
                                      'icono': Icons.android,
                                      'color': Colors.blueGrey,
                                    },
                                  );

                              // Barra de progreso relativa (ej: barra llena si pasa de 1 hora)
                              final progresoApp = (duracionApp.inMinutes / 60)
                                  .clamp(0.0, 1.0);

                              return _buildAppUsageTile(
                                infoVisual['nombre'] as String,
                                _formatDuration(duracionApp),
                                infoVisual['icono'] as IconData,
                                infoVisual['color'] as Color,
                                progresoApp,
                              );
                            },
                          ),

                    const SizedBox(height: 30),

                    // Mensaje motivador estático
                    _buildMensajeMotivador(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTotalTimeCard(
    Color accentColor,
    String tiempoTotal,
    double porcentaje,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Tiempo Total de Pantalla',
            style: TextStyle(
              color: Colors.blueGrey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            tiempoTotal,
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: accentColor,
            ),
          ),
          const Text(
            'Recuerda no excederte',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: porcentaje,
              minHeight: 12,
              backgroundColor: const Color(0xFFE0E0E0),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageTile(
    String app,
    String time,
    IconData icon,
    Color color,
    double progress,
  ) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(app, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time),
            const SizedBox(height: 5),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildMensajeMotivador() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.wb_sunny, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              '¡Vas muy bien! Recuerda descansar la vista cada 20 minutos.',
              style: TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
