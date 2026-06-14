import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapachesecure_app/providers/tema_padre_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';

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
      if (_hijoSeleccionadoId != null) {
        await _cargarRecompensasActivas(_hijoSeleccionadoId!);
      }
    } catch (_) {}
  }

  Future<void> _cargarRecompensasActivas(String hijoId) async {
    try {
      final data = await _api.get('/recompensas/$hijoId');
      if (data is List && data.isNotEmpty) {
        final titulos = data.map((r) => r['titulo']?.toString() ?? '').toSet();
        setState(() {
          for (int i = 0; i < _recompensasSistema.length; i++) {
            final r = _recompensasSistema[i];
            final titulo = '${r['icono']} ${r['nombre']}';
            _activas[i] = titulos.contains(titulo);
          }
          _confirmado = true;
        });
      } else {
        setState(() {
          _activas = List.generate(_recompensasSistema.length, (_) => false);
          _confirmado = false;
        });
      }
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No puedes eliminar esta recompensa')),
      );
    }
  }

  void _mostrarFormulario(Color colorTema, Color colorFondo) {
    final nombreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final puntosCtrl = TextEditingController(text: '50');
    String icono = '🎁';

    final iconos = ['🎁', '📱', '🍕', '🎬', '🎮', '🏖️', '🍦', '🎡', '⭐', '🏆'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            // Ajuste responsivo de teclado + zona segura inferior
            bottom:
                MediaQuery.of(context).viewInsets.bottom +
                MediaQuery.of(context).viewPadding.bottom +
                20,
          ),
          // 🛡️ SOLUCIÓN AL ERROR: Permite scroll cuando el teclado reduce el espacio visible
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nueva recompensa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Título en negro
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nombreCtrl,
                  style: const TextStyle(
                    color: Colors.black,
                  ), // ✍️ Texto al escribir en negro
                  decoration: InputDecoration(
                    labelText: 'Nombre',
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorTema, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(
                    color: Colors.black,
                  ), // ✍️ Texto al escribir en negro
                  decoration: InputDecoration(
                    labelText: 'Descripción',
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorTema, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: puntosCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    color: Colors.black,
                  ), // ✍️ Texto al escribir en negro
                  decoration: InputDecoration(
                    labelText: 'Puntos sugeridos',
                    labelStyle: const TextStyle(color: Colors.black54),
                    border: const OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: colorTema, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ícono:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black, // Subtítulo en negro
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: iconos
                      .map(
                        (e) => GestureDetector(
                          onTap: () => setModalState(() => icono = e),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: icono == e
                                    ? colorTema
                                    : Colors.grey.shade300,
                                width: icono == e ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              color: icono == e
                                  ? colorTema.withValues(alpha: 0.1)
                                  : Colors.white,
                            ),
                            child: Text(
                              e,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: colorTema),
                    onPressed: () async {
                      if (nombreCtrl.text.isEmpty) return;
                      if (_hijoSeleccionadoId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Selecciona un hijo primero'),
                          ),
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
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              '¡Recompensa personalizada agregada! 🎁',
                            ),
                          ),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    },
                    child: const Text(
                      'Agregar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmarSeleccion(Color colorBoton) {
    if (_hijoSeleccionadoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primero selecciona a qué hijo asignar las recompensas',
          ),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('¿Confirmar recompensas?'),
        content: Text(
          '¿Asignar $activadas recompensas a $_hijoSeleccionadoNombre?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: colorBoton),
            onPressed: () async {
              // Corrección de Contexto: Cierra diálogo antes, ejecuta después de forma limpia
              Navigator.pop(context);
              await _guardarRecompensas();
            },
            child: const Text(
              'Confirmar',
              style: TextStyle(color: Colors.white),
            ),
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
          SnackBar(
            content: Text(
              '¡Recompensas asignadas a $_hijoSeleccionadoNombre! 🎁',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final temaPadre = context.watch<TemaPadreProvider>().coloresPadre;

    return Scaffold(
      backgroundColor: temaPadre.background,
      appBar: AppBar(
        title: const Text(
          'Tienda de Recompensas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: temaPadre.primary,
        foregroundColor: Colors.white,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!_confirmado)
            FloatingActionButton.extended(
              heroTag: 'btnConfirmar',
              onPressed: () => _confirmarSeleccion(temaPadre.primary),
              backgroundColor: temaPadre.primary,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'Confirmar',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'btnAgregar',
            onPressed: _confirmado
                ? null
                : () => _mostrarFormulario(
                    temaPadre.primary,
                    temaPadre.background,
                  ),
            backgroundColor: _confirmado
                ? Colors.grey.shade400
                : Colors.black87,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.lerp(temaPadre.primary, Colors.white, 0.62)!,
              temaPadre.background,
            ],
          ),
        ),
        child: SafeArea(
          bottom:
              true, // Protege la interfaz de la barra de gestos nativa del celular
          child: _cargando
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _cargarComunidad,
                  // LayoutBuilder calcula el ancho real para decidir cuántas columnas usar
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Si el ancho de pantalla es mayor a 600px usa 2 columnas, si no, usa 1.
                      final int columnas = constraints.maxWidth > 600 ? 2 : 1;

                      return CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.only(
                              top: 16,
                              left: 16,
                              right: 16,
                              bottom: 0,
                            ),
                            sliver: SliverList(
                              delegate: SliverChildListDelegate([
                                if (_hijos.isNotEmpty) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.black.withValues(alpha: 0.08),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.child_care,
                                          color: temaPadre.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        const Text(
                                          'Asignar a:',
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: DropdownButton<String>(
                                            value: _hijoSeleccionadoId,
                                            dropdownColor: Colors.white,
                                            isExpanded: true,
                                            underline: const SizedBox(),
                                            items: _hijos
                                                .map<DropdownMenuItem<String>>((
                                                  h,
                                                ) {
                                                  return DropdownMenuItem<
                                                    String
                                                  >(
                                                    value: h['id'],
                                                    child: Text(
                                                      h['nombre'] ??
                                                          'Sin nombre',
                                                      style: const TextStyle(
                                                        color: Colors.black87,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  );
                                                })
                                                .toList(),
                                            onChanged: (val) {
                                              setState(() {
                                                _hijoSeleccionadoId = val;
                                                _hijoSeleccionadoNombre =
                                                    _hijos.firstWhere(
                                                      (h) => h['id'] == val,
                                                    )['nombre'] ??
                                                    '';
                                                _activas = List.generate(
                                                  _recompensasSistema.length,
                                                  (_) => false,
                                                );
                                                _confirmado = false;
                                              });
                                              _cargarRecompensasActivas(val!);
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                const Text(
                                  'Del sistema',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Activa las recompensas que quieres ofrecer a tu hijo',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ]),
                            ),
                          ),

                          // SECCIÓN RESPONSIVA: Grid Adaptable para las Recompensas del Sistema
                          SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columnas,
                                    mainAxisExtent:
                                        80, // Altura fija ideal para Switches en lista
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 10,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                i,
                              ) {
                                final r = _recompensasSistema[i];
                                final color = r['color'] as Color;
                                final activa = _activas[i];
                                return Card(
                                  elevation: 1,
                                  margin: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: SwitchListTile(
                                    secondary: CircleAvatar(
                                      backgroundColor: activa
                                          ? color.withValues(alpha: 0.15)
                                          : Colors.grey.shade100,
                                      child: Text(
                                        r['icono'] as String,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                    ),
                                    title: Text(
                                      r['nombre'] as String,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${r['puntos']} Pts',
                                      style: TextStyle(
                                        color: activa ? color : Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    value: activa,
                                    activeThumbColor: temaPadre.primary,
                                    onChanged: _confirmado
                                        ? null
                                        : (val) {
                                            if (val &&
                                                _activas
                                                        .where((a) => a)
                                                        .length >=
                                                    3) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
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
                              }, childCount: _recompensasSistema.length),
                            ),
                          ),

                          // Título de la sección de Comunidad
                          SliverPadding(
                            padding: const EdgeInsets.only(
                              top: 24,
                              left: 16,
                              right: 16,
                              bottom: 8,
                            ),
                            sliver: SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Recomendadas por la comunidad',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (_comunidad.isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 12,
                                      ),
                                      child: Text(
                                        'Aún no hay recompensas de la comunidad. ¡Sé el primero en agregar una!',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                          // SECCIÓN RESPONSIVA: Grid Adaptable para la Comunidad
                          SliverPadding(
                            // 🟢 Padding inferior extra de 110px para evitar el pegado inferior y no tapar botones flotantes
                            padding: const EdgeInsets.only(
                              left: 16,
                              right: 16,
                              bottom: 110,
                            ),
                            sliver: SliverGrid(
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: columnas,
                                    mainAxisExtent:
                                        95, // Más altura por si hay descripción
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 10,
                                  ),
                              delegate: SliverChildBuilderDelegate((
                                context,
                                index,
                              ) {
                                final r = _comunidad[index];
                                return _tarjetaComunidad(r, temaPadre.primary);
                              }, childCount: _comunidad.length),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }

  Widget _tarjetaComunidad(dynamic r, Color colorTema) {
    return Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Text(r['icono'] ?? '🎁', style: const TextStyle(fontSize: 26)),
        title: Text(
          r['nombre'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (r['descripcion'] != null &&
                r['descripcion'].toString().isNotEmpty)
              Text(
                r['descripcion'],
                style: const TextStyle(color: Colors.black54, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 2),
            Text(
              '${r['puntos_sugeridos']} Pts',
              style: TextStyle(
                color: colorTema,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          constraints: const BoxConstraints(),
          padding: EdgeInsets.zero,
          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
          onPressed: () => _eliminar(r['id']),
        ),
      ),
    );
  }
}
