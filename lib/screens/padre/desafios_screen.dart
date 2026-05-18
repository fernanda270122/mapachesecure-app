import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/api_service.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mapachesecure_app/theme/app_background.dart';
import 'package:mapachesecure_app/theme/app_colors.dart';

class DesafiosScreen extends StatefulWidget {
  const DesafiosScreen({super.key});

  @override
  State<DesafiosScreen> createState() => _DesafiosScreenState();
}

class _DesafiosScreenState extends State<DesafiosScreen> {
  final ApiService _api = ApiService();
  final FlutterTts _tts = FlutterTts();

  List<dynamic> _opcionesIA = [];
  bool _cargando = false;
  List<dynamic> _desafiosCognitiva = [];
  List<dynamic> _desafiosFisica = [];
  List<dynamic> _desafiosHogar = [];
  List<dynamic> _desafiosIA = [];
  List<dynamic> _hijos = [];
  String? _hijoSeleccionadoId;
  String _hijoSeleccionadoNombre = '';

  @override
  void initState() {
    super.initState();
    _cargarTodo();
    _tts.setLanguage('es-MX');
  }

  // Carga inicial de datos
  Future<void> _cargarTodo() async {
    setState(() => _cargando = true);
    await Future.wait([
      _cargarHijos(),
      _cargarDesafiosIA(),
    ]);
    setState(() => _cargando = false);
  }

  // --- NUEVA FUNCIÓN PARA ACTIVAR/DESACTIVAR DESDE EL DASHBOARD ---
  Future<void> _actualizarEstadoMision(dynamic id, bool nuevoEstado) async {
    try {
      await _api.post('/desafios/actualizar_estado', {
        'id': id,
        'esta_activo': nuevoEstado,
      });
      // Refrescamos la lista para que el Switch y los colores cambien
      if (_hijoSeleccionadoId != null) _cargarDesafiosSistema(_hijoSeleccionadoId!);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al cambiar estado: $e')));
    }
  }

  Future<void> _cargarHijos() async {
    final prefs = await SharedPreferences.getInstance();
    final padreId = prefs.getString('user_id') ?? '';
    try {
      final hijos = await _api.get('/usuarios/$padreId/hijos');
      setState(() {
        _hijos = hijos is List ? hijos : [];
        if (_hijos.isNotEmpty) {
          _hijoSeleccionadoId = _hijos[0]['id'];
          _hijoSeleccionadoNombre = _hijos[0]['nombre'] ?? '';
        }
      });
      if (_hijoSeleccionadoId != null) {
        await _cargarDesafiosSistema(_hijoSeleccionadoId!);
      }
    } catch (_) {}
  }

  Future<void> _cargarDesafiosSistema(String hijoId) async {
    try {
      final todos = await _api.get('/desafios/hijo/$hijoId');
      final lista = todos is List ? todos : [];
      setState(() {
        _desafiosCognitiva = lista.where((d) => d['tipo'] == 'cognitiva').toList();
        _desafiosFisica = lista.where((d) => d['tipo'] == 'fisica').toList();
        _desafiosHogar = lista.where((d) => d['tipo'] == 'hogar').toList();
      });
    } catch (_) {}
  }

  Future<void> _cargarDesafiosIA() async {
    final prefs = await SharedPreferences.getInstance();
    final guardados = prefs.getString('desafios_ia');
    if (guardados != null) {
      setState(() {
        _desafiosIA = jsonDecode(guardados);
      });
    }
  }

  // --- SECCIÓN DE IA (SIN MODIFICACIONES EN LA LÓGICA CORE) ---

  Future<void> _generarDesafios(
    String categoria,
    String dificultad,
    String hijoId,
  ) async {
    setState(() => _cargando = true);
    try {
      final resultado = await _api.post('/ia/generar', {
        'categoria': categoria,
        'hijo_id': hijoId,
        'dificultad': dificultad,
        'cantidad': 3,
      });
      final nuevos = List<dynamic>.from(resultado['desafios'] ?? []);
      setState(() {
        _opcionesIA = nuevos;
      });
      if (_opcionesIA.isNotEmpty) {
        _mostrarSelectorIA(context, hijoId, categoria, dificultad);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  void _mostrarSelectorIA(
    BuildContext context,
    String hijoId,
    String categoria,
    String dificultad,
  ) {
    Set<int> seleccionados = {};
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Selecciona misiones para el niño:",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  ...List.generate(_opcionesIA.length, (index) {
                    final desafio = _opcionesIA[index];
                    final isSelected = seleccionados.contains(index);
                    return CheckboxListTile(
                      title: Text(
                        desafio['titulo'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        "${desafio['descripcion']}\n${desafio['puntos']} pts",
                      ),
                      value: isSelected,
                      activeColor: Colors.green,
                      onChanged: (bool? value) {
                        setModalState(() {
                          if (value == true)
                            seleccionados.add(index);
                          else
                            seleccionados.remove(index);
                        });
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: seleccionados.isEmpty
                          ? null
                          : () {
                              List<Map<String, dynamic>> elegidos =
                                  seleccionados
                                      .map(
                                        (i) => Map<String, dynamic>.from(
                                          _opcionesIA[i],
                                        ),
                                      )
                                      .toList();
                              Navigator.pop(context);
                              _confirmarVariosDesafios(
                                elegidos,
                                hijoId,
                                categoria,
                                dificultad,
                              );
                            },
                      child: Text("Enviar ${seleccionados.length} misiones"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmarVariosDesafios(
    List<Map<String, dynamic>> desafios,
    String hijoId,
    String categoria,
    String dificultad,
  ) async {
    setState(() => _cargando = true);
    try {
      for (var desafio in desafios) {
        final Map<String, dynamic> datos = {
          'titulo': desafio['titulo'],
          'descripcion': desafio['descripcion'],
          'puntos': desafio['puntos'],
          'tipo': categoria.toLowerCase(),
          'dificultad': dificultad.toLowerCase(),
          'hijo_id': hijoId,
          'esta_activo':
              false, // Por defecto llegan desactivados para que el padre los cure
        };
        await _api.post('/ia/asignar', datos);
      }
      if (_hijoSeleccionadoId != null) _cargarDesafiosSistema(_hijoSeleccionadoId!); // Actualizar lista tras asignar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Misiones enviadas al panel de control! 🦝'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  // --- INTERFAZ ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Gestionar Desafíos',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: AppBackground(
        child: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
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
                          const Text('Ver desafíos de:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                                  child: Text(h['nombre'] ?? 'Sin nombre', style: const TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _hijoSeleccionadoId = val;
                                  _hijoSeleccionadoNombre = _hijos.firstWhere((h) => h['id'] == val)['nombre'] ?? '';
                                });
                                _cargarDesafiosSistema(val!);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildSeccion(
                    'Cognitiva',
                    _desafiosCognitiva,
                    Colors.blue,
                    Icons.psychology,
                  ),
                  _buildSeccion(
                    'Física',
                    _desafiosFisica,
                    Colors.orange,
                    Icons.fitness_center,
                  ),
                  _buildSeccion(
                    'Hogar',
                    _desafiosHogar,
                    Colors.green,
                    Icons.home,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _mostrarFormularioIA(context),
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text(
                      'Generar nuevos con IA',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSeccion(
    String titulo,
    List<dynamic> desafios,
    Color color,
    IconData icono,
  ) {
    if (desafios.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        ...desafios.map(
          (d) => _buildChallengeCard(
            id: d['id'],
            titulo: d['titulo'] ?? '',
            descripcion: d['descripcion'] ?? '',
            puntos: d['puntos']?.toString() ?? '0',
            dificultad: d['dificultad'] ?? 'facil',
            color: color,
            icono: icono,
            estaActivo: d['esta_activo'] ?? false,
          ),
        ),
      ],
    );
  }

  Widget _buildChallengeCard({
    required dynamic id,
    required String titulo,
    required String descripcion,
    required String puntos,
    required String dificultad,
    required Color color,
    required IconData icono,
    required bool estaActivo,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: estaActivo
              ? color.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          child: Icon(icono, color: estaActivo ? color : Colors.grey),
        ),
        title: Text(
          titulo,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: estaActivo ? Colors.black87 : Colors.grey[600],
          ),
        ),
        subtitle: Text(
          '$puntos pts • $dificultad',
          style: TextStyle(fontSize: 12, color: color),
        ),
        trailing: Switch(
          value: estaActivo,
          activeColor: color,
          onChanged: (val) => _actualizarEstadoMision(id, val),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  descripcion,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.indigo),
                      onPressed: () => _tts.speak(descripcion),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FORMULARIO GENERACIÓN IA (IGUAL AL TUYO) ---
  void _mostrarFormularioIA(BuildContext context) {
    String categoria = 'cognitiva';
    String dificultad = 'facil';
    String? hijo = _hijos.isNotEmpty ? _hijos[0]['id'] : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Generar con IA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Categoría'),
              DropdownButton<String>(
                isExpanded: true,
                value: categoria,
                items: const [
                  DropdownMenuItem(
                    value: 'cognitiva',
                    child: Text('Cognitiva'),
                  ),
                  DropdownMenuItem(value: 'fisica', child: Text('Física')),
                  DropdownMenuItem(value: 'hogar', child: Text('Hogar')),
                ],
                onChanged: (v) => setModalState(() => categoria = v!),
              ),
              const SizedBox(height: 10),
              const Text('Dificultad'),
              DropdownButton<String>(
                isExpanded: true,
                value: dificultad,
                items: const [
                  DropdownMenuItem(value: 'facil', child: Text('Fácil')),
                  DropdownMenuItem(value: 'medio', child: Text('Medio')),
                  DropdownMenuItem(value: 'dificil', child: Text('Difícil')),
                ],
                onChanged: (v) => setModalState(() => dificultad = v!),
              ),
              const SizedBox(height: 10),
              const Text('Hijo'),
              DropdownButton<String>(
                isExpanded: true,
                value: hijo,
                items: _hijos
                    .map<DropdownMenuItem<String>>(
                      (h) => DropdownMenuItem(
                        value: h['id'],
                        child: Text(h['nombre'] ?? 'Sin nombre'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setModalState(() => hijo = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.textDark,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    if (hijo != null) {
                      Navigator.pop(context);
                      _generarDesafios(categoria, dificultad, hijo!);
                    }
                  },
                  child: const Text('Generar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
