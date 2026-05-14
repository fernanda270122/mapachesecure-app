import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _recompensasSistema = [
  {
    'nombre': 'Elegir la película',
    'icono': '🎬',
    'color': Color(0xFFFF9800),
    'puntos': 150,
  },
  {
    'nombre': 'Postre especial',
    'icono': '🍦',
    'color': Color(0xFFE91E63),
    'puntos': 250,
  },
  {
    'nombre': 'Elegir la cena',
    'icono': '🍽️',
    'color': Color(0xFF009688),
    'puntos': 400,
  },
  {
    'nombre': 'Noche de juegos de mesa',
    'icono': '🎲',
    'color': Color(0xFF3F51B5),
    'puntos': 550,
  },
  {
    'nombre': 'Noche de pizza',
    'icono': '🍕',
    'color': Color(0xFFF44336),
    'puntos': 700,
  },
  {
    'nombre': 'Salida al parque',
    'icono': '🌳',
    'color': Color(0xFF4CAF50),
    'puntos': 850,
  },
  {
    'nombre': '30 min extra de juegos',
    'icono': '🎮',
    'color': Color(0xFF9C27B0),
    'puntos': 1000,
  },
  {
    'nombre': '30 min menos al desbloqueo',
    'icono': '🔓',
    'color': Color(0xFF1A237E),
    'puntos': 1200,
  },
];

class TiendaRecompensasScreen extends StatefulWidget {
  const TiendaRecompensasScreen({super.key});

  @override
  State<TiendaRecompensasScreen> createState() =>
      _TiendaRecompensasScreenState();
}

class _TiendaRecompensasScreenState extends State<TiendaRecompensasScreen> {
  final ApiService _api = ApiService();
  late List<bool> _activas;
  List<dynamic> _comunidad = [];
  bool _cargando = true;
  bool _confirmado = false;
  List<dynamic> _hijos = [];
  String? _hijoSeleccionadoId;
  String _hijoSeleccionadoNombre = '';

  @override
  void initState() {
    super.initState();
    _activas = List.generate(_recompensasSistema.length, (index) => false);
    _cargarHijos();
    _cargarComunidad();
  }
  Future<void> _cargarHijos() async {
    final prefs = await SharedPreferences.getInstance();
    final padreId = prefs.getString('user_id') ?? '';
    try {
      final data = await _api.get('/usuarios/$padreId/hijos');
      setState(() {
        _hijos = data is List ? data : [];
        if (_hijos.isNotEmpty) {
          _hijoSeleccionadoId = _hijos[0]['id'];
          _hijoSeleccionadoNombre = _hijos[0]['nombre'] ?? '';
        }
      });
    } catch (_) {}
  }

  Future<void> _cargarComunidad() async {
    try {
      final data = await _api.get('/recompensas/catalogo');
      setState(() {
        _comunidad = (data as List)
            .where((r) => r['creado_por'] != null)
            .toList();
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminar(String id) async {
    try {
      await _api.delete('/recompensas/catalogo/$id');
      _cargarComunidad();
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
                                  ? AppColors.background
                                  : Colors.grey,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: icono == e
                                ? AppColors.secondary.withOpacity(0.1)
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
                    backgroundColor: AppColors.accent,
                  ),
                  onPressed: () async {
                    if (nombreCtrl.text.isEmpty) return;
                    if (_hijoSeleccionadoId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Selecciona un hijo primero')),
                      );
                      return;
                    }
                    final prefs = await SharedPreferences.getInstance();
                    final padreId = prefs.getString('user_id') ?? '';
                    try {
                      await _api.post('/recompensas/', {
                        'padre_id': padreId,
                        'hijo_id': _hijoSeleccionadoId,
                        'titulo': '$icono ${nombreCtrl.text}',
                        'costo_puntos': int.tryParse(puntosCtrl.text) ?? 50,
                      });
                      Navigator.pop(context);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('¡Recompensa personalizada agregada! 🎁')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
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

  void _confirmarSeleccion() {
    if (_hijoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Primero selecciona a qué hijo asignar las recompensas')),
      );
      return;
    }
    final activadas = _activas.where((a) => a).length;
    if (activadas == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes activar al menos una recompensa')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Confirmar recompensas?'),
        content: Text('¿Asignar $activadas recompensas a $_hijoSeleccionadoNombre?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
            onPressed: () async {
              Navigator.pop(context);
              await _guardarRecompensas();
            },
            child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _guardarRecompensas() async {
    final prefs = await SharedPreferences.getInstance();
    final padreId = prefs.getString('user_id') ?? '';
    setState(() => _cargando = true);
    try {
      for (int i = 0; i < _recompensasSistema.length; i++) {
        if (_activas[i]) {
          final r = _recompensasSistema[i];
          await _api.post('/recompensas/', {
            'padre_id': padreId,
            'hijo_id': _hijoSeleccionadoId,
            'titulo': '${r['icono']} ${r['nombre']}',
            'costo_puntos': r['puntos'],
          });
        }
      }
      setState(() => _confirmado = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('¡Recompensas asignadas a $_hijoSeleccionadoNombre! 🎁')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Tienda de Recompensas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!_confirmado)
            FloatingActionButton.extended(
              onPressed: _confirmarSeleccion,
              backgroundColor: AppColors.secondary,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Confirmar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _confirmado ? null : _mostrarFormulario,
            backgroundColor: AppColors.textDark,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: AppBackground(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _cargarComunidad,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_hijos.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.child_care, color: Colors.white),
                            const SizedBox(width: 10),
                            const Text(
                              'Asignar a:',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButton<String>(
                                value: _hijoSeleccionadoId,
                                dropdownColor: AppColors.primary,
                                isExpanded: true,
                                underline: const SizedBox(),
                                items: _hijos.map<DropdownMenuItem<String>>((h) {
                                  return DropdownMenuItem<String>(
                                    value: h['id'],
                                    child: Text(
                                      h['nombre'] ?? 'Sin nombre',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                                onChanged: _confirmado
                                    ? null
                                    : (val) {
                                        setState(() {
                                          _hijoSeleccionadoId = val;
                                          _hijoSeleccionadoNombre =
                                              _hijos.firstWhere((h) => h['id'] == val)['nombre'] ?? '';
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Del sistema',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Activa las recompensas que quieres ofrecer a tu hijo',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(_recompensasSistema.length, (i) {
                      final r = _recompensasSistema[i];
                      final color = r['color'] as Color;
                      final activa = _activas[i];
                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: SwitchListTile(
                          secondary: CircleAvatar(
                            backgroundColor: activa
                                ? color.withOpacity(0.15)
                                : Colors.grey.shade100,
                            child: Text(
                              r['icono'] as String,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          title: Text(
                            r['nombre'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${r['puntos']} MapachePoints',
                            style: TextStyle(
                              color: activa ? color : Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          value: activa,
                          activeColor: AppColors.background,
                          onChanged: _confirmado
                              ? null
                              : (val) {
                                  if (val &&
                                      _activas.where((a) => a).length >= 3) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Puedes activar máximo 3 recompensas',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  setState(() => _activas[i] = val);
                                },
                        ),
                      );
                    }),
                    const SizedBox(height: 20),
                    const Text(
                      'Recomendadas por la comunidad',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_comunidad.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Aún no hay recompensas de la comunidad. ¡Sé la primera en agregar una!',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ..._comunidad.map((r) => _tarjetaComunidad(r)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _tarjetaComunidad(dynamic r) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
              '${r['puntos_sugeridos']} MapachePoints',
              style: const TextStyle(
                color: Color(0xFF1A237E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _eliminar(r['id']),
        ),
      ),
    );
  }
}
