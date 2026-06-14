import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_provider.dart';

class TiendaRecompensasHijoScreen extends StatefulWidget {
  const TiendaRecompensasHijoScreen({super.key});

  @override
  State<TiendaRecompensasHijoScreen> createState() =>
      _TiendaRecompensasHijoScreenState();
}

class _TiendaRecompensasHijoScreenState
    extends State<TiendaRecompensasHijoScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _recompensas = [];
  int _misPuntos = 0;
  bool _cargando = true;
  bool _tienePendiente = false;
  String _hijoId = '';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    final hijoId = prefs.getString('user_id') ?? '';
    _hijoId = hijoId;

    try {
      final data = await _api.get('/recompensas/$hijoId');
      final puntosData = await _api.get('/desafios/puntos/$hijoId');
      final pendienteData = await _api.get('/canjes/tiene-pendiente/$hijoId');

      final lista = data is List ? data : [];
      final vistos = <String>{};
      final unicos = lista.where((r) {
        final titulo = r['titulo']?.toString() ?? '';
        return vistos.add(titulo);
      }).toList();

      setState(() {
        _recompensas = unicos;
        _misPuntos = puntosData is Map ? (puntosData['total_puntos'] ?? 0) : 0;
        _tienePendiente = pendienteData is Map
            ? (pendienteData['tiene_pendiente'] ?? false)
            : false;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _canjearRecompensa(Map<String, dynamic> recompensa) async {
    final puntosCosto = recompensa['costo_puntos'] ?? 0;
    if (_misPuntos < puntosCosto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '¡Aún te faltan MapachePoints! Sigue cumpliendo desafíos 🦝',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Canjear ${recompensa['titulo']}?'),
        content: Text('Se descontarán $puntosCosto puntos de tu cuenta.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            onPressed: () async {
              Navigator.pop(context);
              try {
                // Endpoint para solicitar el canje
                await _api.post('/recompensas/canjear', {
                  'hijo_id': _hijoId,
                  'recompensa_id': recompensa['id'],
                });

                if (mounted) {
                  _cargarDatos(); // Recargar puntos y lista
                  _mostrarExito();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: const Text(
              '¡SÍ, CANJEAR!',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarExito() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 50)),
            const SizedBox(height: 10),
            const Text(
              '¡Solicitud enviada!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              'Dile a tus papás que revisen su app para entregarte tu premio.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('¡Genial!'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tema = context.watch<TemaProvider>().colores;
    return Scaffold(
      backgroundColor: tema.background,
      appBar: AppBar(
        title: const Text('Tienda de Premios'),
        backgroundColor: tema.primary,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeaderPuntos(),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _recompensas.length,
                    itemBuilder: (context, index) {
                      final r = _recompensas[index];
                      return _buildTarjetaPremio(r);
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeaderPuntos() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Tienes:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Text(
            '$_misPuntos',
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(width: 5),
          const Icon(Icons.stars, color: Colors.orange),
        ],
      ),
    );
  }

  Widget _buildTarjetaPremio(dynamic r) {
    final int costo = r['costo_puntos'] ?? 0;
    final bool puedeComprar = _misPuntos >= costo;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Text(
          r['titulo']?.toString().split(' ').first ?? '🎁',
          style: const TextStyle(fontSize: 32),
        ),
        title: Text(
          r['titulo']?.toString().split(' ').skip(1).join(' ') ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '$costo MapachePoints',
          style: TextStyle(
            color: puedeComprar ? Colors.purple : Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: (_tienePendiente || !puedeComprar)
                ? Colors.grey.shade300
                : Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: (!_tienePendiente && puedeComprar)
              ? () => _canjearRecompensa(r)
              : null,
          child: Text(
            _tienePendiente ? 'EN ESPERA' : 'CANJEAR',
            style: TextStyle(
              color: (_tienePendiente || !puedeComprar)
                  ? Colors.grey.shade600
                  : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
