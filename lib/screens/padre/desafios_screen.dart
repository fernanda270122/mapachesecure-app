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
  bool _cargando = false;
  List<dynamic> _desafiosCognitiva = [];
  List<dynamic> _desafiosFisica = [];
  List<dynamic> _desafiosHogar = [];
  List<dynamic> _desafiosIA = [];
  List<dynamic> _hijos = [];

  @override
  void initState() {
    super.initState();
    _cargarDesafiosSistema();
    _cargarDesafiosIA();
    _cargarHijos();
    _tts.setLanguage('es-MX');
  }

  Future<void> _cargarHijos() async {
    final prefs = await SharedPreferences.getInstance();
    final padreId = prefs.getString('user_id') ?? '';
    try {
      final hijos = await _api.get('/usuarios/$padreId/hijos');
      setState(() {
        _hijos = hijos is List ? hijos : [];
      });
    } catch (_) {}
  }

  Future<void> _cargarDesafiosSistema() async {
    try {
      final cognitiva = await _api.get('/desafios/tipo/cognitiva');
      final fisica = await _api.get('/desafios/tipo/fisica');
      final hogar = await _api.get('/desafios/tipo/hogar');
      setState(() {
        _desafiosCognitiva = cognitiva is List ? cognitiva : [];
        _desafiosFisica = fisica is List ? fisica : [];
        _desafiosHogar = hogar is List ? hogar : [];
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
      final acumulados = List<dynamic>.from(_desafiosIA)..addAll(nuevos);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('desafios_ia', jsonEncode(acumulados));
      setState(() {
        _desafiosIA = acumulados;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al generar desafíos: $e')));
    } finally {
      setState(() => _cargando = false);
    }
  }

  Future<void> _eliminarDesafioIA(int index) async {
    final actualizada = List<dynamic>.from(_desafiosIA)..removeAt(index);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('desafios_ia', jsonEncode(actualizada));
    setState(() {
      _desafiosIA = actualizada;
    });
  }

  void _mostrarFormularioIA(BuildContext context) {
    String categoriaSeleccionada = 'cognitiva';
    String dificultadSeleccionada = 'facil';
    String? hijoSeleccionado = _hijos.isNotEmpty ? _hijos[0]['id'] : null;

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
                'Generar desafíos con IA',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              const Text('Categoría'),
              DropdownButton<String>(
                isExpanded: true,
                value: categoriaSeleccionada,
                items: const [
                  DropdownMenuItem(
                    value: 'cognitiva',
                    child: Text('Cognitiva'),
                  ),
                  DropdownMenuItem(value: 'fisica', child: Text('Física')),
                  DropdownMenuItem(value: 'hogar', child: Text('Hogar')),
                ],
                onChanged: (v) =>
                    setModalState(() => categoriaSeleccionada = v!),
              ),
              const SizedBox(height: 10),
              const Text('Dificultad'),
              DropdownButton<String>(
                isExpanded: true,
                value: dificultadSeleccionada,
                items: const [
                  DropdownMenuItem(value: 'facil', child: Text('Fácil')),
                  DropdownMenuItem(value: 'medio', child: Text('Medio')),
                  DropdownMenuItem(value: 'dificil', child: Text('Difícil')),
                ],
                onChanged: (v) =>
                    setModalState(() => dificultadSeleccionada = v!),
              ),
              const SizedBox(height: 10),
              const Text('Hijo'),
              DropdownButton<String>(
                isExpanded: true,
                value: hijoSeleccionado,
                items: _hijos.map<DropdownMenuItem<String>>((hijo) {
                  return DropdownMenuItem<String>(
                    value: hijo['id'],
                    child: Text(hijo['nombre'] ?? 'Sin nombre'),
                  );
                }).toList(),
                onChanged: (v) => setModalState(() => hijoSeleccionado = v),
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
                    if (hijoSeleccionado == null) return;
                    Navigator.pop(context);
                    _generarDesafios(
                      categoriaSeleccionada,
                      dificultadSeleccionada,
                      hijoSeleccionado!,
                    );
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
      body: AppBackground(child: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
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
                if (_desafiosIA.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Generados con IA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ..._desafiosIA.asMap().entries.map(
                    (entry) => _buildChallengeCard(
                      entry.value['titulo'] ?? '',
                      entry.value['descripcion'] ?? '',
                      '${entry.value['puntos']} pts · ${entry.value['tiempo_estimado_minutos']} min',
                      Colors.purple,
                      Icons.auto_awesome,
                      onEliminar: () => _eliminarDesafioIA(entry.key),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _mostrarFormularioIA(context),
                    child: const Text(
                      'Generar nuevos desafíos',
                      style: TextStyle(fontSize: 16),
                    ),
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
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A237E),
          ),
        ),
        const SizedBox(height: 10),
        ...desafios.map(
          (d) => _buildChallengeCard(
            d['titulo'] ?? '',
            d['descripcion'] ?? '',
            '${d['puntos']} pts · ${d['tiempo_estimado_minutos']} min',
            color,
            icono,
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildChallengeCard(
    String titulo,
    String descripcion,
    String metainfo,
    Color color,
    IconData icono, {
    VoidCallback? onEliminar,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icono, color: color),
        ),
        title: Text(
          titulo,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        trailing: onEliminar != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onEliminar,
              )
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (descripcion.isNotEmpty)
                  Text(
                    descripcion,
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      metainfo,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.volume_up, color: Colors.indigo),
                      tooltip: 'Escuchar actividad',
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
}
