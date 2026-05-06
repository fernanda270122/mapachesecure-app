import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class TiendaRecompensasScreen extends StatefulWidget {
  const TiendaRecompensasScreen({super.key});

  @override
  State<TiendaRecompensasScreen> createState() =>
      _TiendaRecompensasScreenState();
}

class _TiendaRecompensasScreenState extends State<TiendaRecompensasScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _catalogo = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCatalogo();
  }

  Future<void> _cargarCatalogo() async {
    try {
      final data = await _api.get('/recompensas/catalogo');
      setState(() {
        _catalogo = data;
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminar(String id) async {
    try {
      await _api.delete('/recompensas/catalogo/$id');
      _cargarCatalogo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes eliminar esta recompensa')),
      );
    }
  }

  void _mostrarFormulario() {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final puntosCtrl = TextEditingController(text: '50');
    String icono = '🎁';

    final iconos = ['🎁', '📱', '🍕', '🎬', '🎮', '🏖️', '🍦', '🎡', '⭐', '🏆'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Nueva recompensa',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: puntosCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Puntos sugeridos',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Ícono:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: iconos
                    .map(
                      (e) => GestureDetector(
                        onTap: () => setModalState(() => icono = e),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: icono == e
                                  ? Colors.deepPurple
                                  : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: icono == e
                                ? Colors.deepPurple.withOpacity(0.1)
                                : null,
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 24)),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                  ),
                  onPressed: () async {
                    if (nombreCtrl.text.isEmpty) return;
                    try {
                      await _api.post('/recompensas/catalogo', {
                        'nombre': nombreCtrl.text,
                        'descripcion': descCtrl.text,
                        'puntos_sugeridos': int.tryParse(puntosCtrl.text) ?? 50,
                        'icono': icono,
                      });
                      Navigator.pop(context);
                      _cargarCatalogo();
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  },
                  child: const Text(
                    'Agregar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sistema = _catalogo.where((r) => r['creado_por'] == null).toList();
    final comunidad = _catalogo.where((r) => r['creado_por'] != null).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tienda de Recompensas'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _mostrarFormulario,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargarCatalogo,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Del sistema',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...sistema.map((r) => _tarjeta(r, esMia: false)),
                  const SizedBox(height: 20),
                  const Text(
                    'Recomendadas por la comunidad',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (comunidad.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aún no hay recompensas de la comunidad. ¡Sé el primero en agregar una!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ...comunidad.map((r) => _tarjeta(r, esMia: true)),
                ],
              ),
            ),
    );
  }

  Widget _tarjeta(dynamic r, {required bool esMia}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Text(r['icono'] ?? '🎁', style: const TextStyle(fontSize: 28)),
        title: Text(
          r['nombre'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (r['descripcion'] != null && r['descripcion'].isNotEmpty)
              Text(r['descripcion']),
            Text(
              '${r['puntos_sugeridos']} puntos',
              style: const TextStyle(
                color: Colors.deepPurple,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: esMia
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _eliminar(r['id']),
              )
            : null,
      ),
    );
  }
}
