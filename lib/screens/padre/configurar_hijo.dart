import 'package:flutter/material.dart';
import 'package:mapachesecure_app/services/api_service.dart';

const _appsPopulares = [
  {'nombre': 'TikTok', 'package': 'com.zhiliaoapp.musically', 'icono': Icons.music_video},
  {'nombre': 'YouTube', 'package': 'com.google.android.youtube', 'icono': Icons.play_circle_fill},
  {'nombre': 'Instagram', 'package': 'com.instagram.android', 'icono': Icons.camera_alt},
  {'nombre': 'Roblox', 'package': 'com.roblox.client', 'icono': Icons.videogame_asset},
  {'nombre': 'WhatsApp', 'package': 'com.whatsapp', 'icono': Icons.chat},
  {'nombre': 'Facebook', 'package': 'com.facebook.katana', 'icono': Icons.facebook},
  {'nombre': 'Snapchat', 'package': 'com.snapchat.android', 'icono': Icons.camera},
  {'nombre': 'Twitter/X', 'package': 'com.twitter.android', 'icono': Icons.alternate_email},
  {'nombre': 'Minecraft', 'package': 'com.mojang.minecraftpe', 'icono': Icons.grid_on},
  {'nombre': 'Netflix', 'package': 'com.netflix.mediaclient', 'icono': Icons.tv},
];

class ConfigurarHijoScreen extends StatefulWidget {
  final Map<String, dynamic> hijo;
  const ConfigurarHijoScreen({super.key, required this.hijo});

  @override
  State<ConfigurarHijoScreen> createState() => _ConfigurarHijoScreenState();
}

class _ConfigurarHijoScreenState extends State<ConfigurarHijoScreen> {
  final _tiempoCtrl = TextEditingController();
  List<dynamic> _appsBlockeadas = [];
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _tiempoCtrl.text = '${widget.hijo['tiempo_limite_minutos'] ?? 120}';
    _cargarApps();
  }

  @override
  void dispose() {
    _tiempoCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargarApps() async {
    try {
      final api = ApiService();
      final apps = await api.get('/apps/${widget.hijo['id']}');
      setState(() {
        _appsBlockeadas = apps is List ? apps : [];
        _cargando = false;
      });
    } catch (e) {
      setState(() => _cargando = false);
    }
  }

  bool _estaBloqueada(String package) {
    return _appsBlockeadas.any((a) => a['package_name'] == package);
  }

  String? _getAppId(String package) {
    final app = _appsBlockeadas.firstWhere(
      (a) => a['package_name'] == package,
      orElse: () => null,
    );
    return app?['id'];
  }

  Future<void> _toggleApp(Map app, bool activar) async {
    final api = ApiService();
    try {
      if (activar) {
        await api.post('/apps/', {
          'hijo_id': widget.hijo['id'],
          'nombre_app': app['nombre'],
          'package_name': app['package'],
          'requiere_desafio': true,
        });
      } else {
        final appId = _getAppId(app['package']);
        if (appId != null) await api.delete('/apps/$appId');
      }
      await _cargarApps();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al actualizar'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _guardarTiempo() async {
    final minutos = int.tryParse(_tiempoCtrl.text);
    if (minutos == null || minutos <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un tiempo válido'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _guardando = true);
    try {
      final api = ApiService();
      await api.put('/usuarios/${widget.hijo['id']}/configuracion', {'tiempo_limite_minutos': minutos});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiempo actualizado'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error al guardar'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Configurar a ${widget.hijo['nombre']}',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1A237E),
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text('Límite de tiempo diario',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tiempoCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Minutos por día',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          suffixText: 'min',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _guardando ? null : _guardarTiempo,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A237E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _guardando
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Guardar'),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Text('Apps a bloquear',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A237E))),
                const SizedBox(height: 6),
                const Text('Activa las apps que quieres bloquear cuando se acabe el tiempo',
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                ..._appsPopulares.map((app) {
                  final bloqueada = _estaBloqueada(app['package'] as String);
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: SwitchListTile(
                      secondary: CircleAvatar(
                        backgroundColor: bloqueada
                            ? Colors.red.shade50
                            : Colors.grey.shade100,
                        child: Icon(
                          app['icono'] as IconData,
                          color: bloqueada ? Colors.red : Colors.grey,
                        ),
                      ),
                      title: Text(app['nombre'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(bloqueada ? 'Bloqueada' : 'Permitida',
                          style: TextStyle(color: bloqueada ? Colors.red : Colors.green)),
                      value: bloqueada,
                      activeColor: const Color(0xFF1A237E),
                      onChanged: (val) => _toggleApp(app, val),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
