import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';

/// Pega o controle do mapa de dentro do próprio `FlutterMap`, para a tela poder
/// mover a câmera (por exemplo, ao abrir "ver no mapa" vindo de um alerta).
///
/// Criar um `MapController` por fora e passar para o mapa quebra a câmera
/// quando há limite de arrasto; por isso o controle é lido daqui.
class MapControllerGrabber extends StatefulWidget {
  const MapControllerGrabber({super.key, required this.onController});

  final ValueChanged<MapController> onController;

  @override
  State<MapControllerGrabber> createState() => _MapControllerGrabberState();
}

class _MapControllerGrabberState extends State<MapControllerGrabber> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.onController(MapController.of(context));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
