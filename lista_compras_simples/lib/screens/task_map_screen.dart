import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/task.dart';
import '../models/map_marker.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../screens/task_form_screen.dart';

class TaskMapScreen extends StatefulWidget {
  const TaskMapScreen({super.key});

  @override
  State<TaskMapScreen> createState() => _TaskMapScreenState();
}

class _TaskMapScreenState extends State<TaskMapScreen> {
  GoogleMapController? _mapController;
  List<Task> _tasks = [];
  Set<Marker> _markers = {};
  bool _isLoading = true;
  LatLng? _currentLocation;
  CameraPosition _initialCameraPosition = const CameraPosition(
    target: LatLng(-19.9167, -43.9345),
    zoom: 12,
  );

  @override
  void initState() {
    super.initState();
    _loadTasks();
    _getCurrentLocation();
  }

  Future<void> _loadTasks() async {
    try {
      final tasks = await DatabaseService.instance.readAll();
      final tasksWithLocation = tasks.where((task) => task.hasLocation).toList();
      
      setState(() {
        _tasks = tasksWithLocation;
        _isLoading = false;
      });
      
      _updateMarkers();
    } catch (e) {
      print('❌ Erro ao carregar tarefas para mapa: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService.instance.getCurrentLocation();
    if (position != null) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _initialCameraPosition = CameraPosition(
          target: _currentLocation!,
          zoom: 14,
        );
      });
    }
  }

  void _updateMarkers() {
    final markers = <Marker>{};
    
    for (final task in _tasks) {
      if (task.hasLocation) {
        final marker = MapMarker(
          taskId: task.id.toString(),
          title: task.title,
          description: task.description,
          latitude: task.latitude!,
          longitude: task.longitude!,
          priority: task.priority,
          completed: task.completed,
          photoPath: task.photoPath,
          locationName: task.locationName,
        );

        markers.add(
          Marker(
            markerId: MarkerId(task.id.toString()),
            position: LatLng(task.latitude!, task.longitude!),
            icon: marker.markerIcon,
            infoWindow: InfoWindow(
              title: task.title,
              snippet: task.completed ? '✅ Concluída' : '📝 Pendente',
              onTap: () => _showTaskDetails(task),
            ),
            onTap: () => _showTaskDetails(task),
          ),
        );
      }
    }

    // Adicionar marcador da localização atual
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(title: 'Minha Localização'),
        ),
      );
    }

    setState(() {
      _markers = markers;
    });
  }

  void _showTaskDetails(Task task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _buildTaskBottomSheet(task),
    );
  }

  Widget _buildTaskBottomSheet(Task task) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                task.completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: task.completed ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  task.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Descrição
          if (task.description.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.description,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
              ],
            ),

          // Localização
          if (task.locationName != null)
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    task.locationName!,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

          const SizedBox(height: 12),

          // Badges
          Wrap(
            spacing: 8,
            children: [
              // Prioridade
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPriorityColor(task.priority).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPriorityColor(task.priority).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  _getPriorityLabel(task.priority),
                  style: TextStyle(
                    fontSize: 12,
                    color: _getPriorityColor(task.priority),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: task.completed ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: task.completed ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  task.completed ? 'Concluída' : 'Pendente',
                  style: TextStyle(
                    fontSize: 12,
                    color: task.completed ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Foto
              if (task.hasPhoto)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.photo, size: 12, color: Colors.blue),
                      SizedBox(width: 4),
                      Text(
                        'Foto',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Botões de Ação
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); 
                    _navigateToTask(task);
                  },
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Editar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context); 
                    _zoomToTask(task);
                  },
                  icon: const Icon(Icons.zoom_in, size: 18),
                  label: const Text('Zoom'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.blue;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'urgent':
        return 'Urgente';
      case 'high':
        return 'Alta';
      case 'medium':
        return 'Média';
      case 'low':
        return 'Baixa';
      default:
        return 'Normal';
    }
  }

  void _navigateToTask(Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: task),
      ),
    ).then((result) {
      if (result == true) {
        _loadTasks(); // Recarregar se a tarefa foi atualizada
      }
    });
  }

  void _zoomToTask(Task task) {
    if (_mapController != null && task.hasLocation) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(task.latitude!, task.longitude!),
          16,
        ),
      );
    }
  }

  void _goToCurrentLocation() {
    if (_mapController != null && _currentLocation != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation!, 16),
      );
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar Tarefas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filtros em desenvolvimento...'),
            const SizedBox(height: 16),
            Text('${_tasks.length} tarefas com localização'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapa de Tarefas'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filtrar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
            tooltip: 'Recarregar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: _initialCameraPosition,
                  onMapCreated: (controller) {
                    setState(() {
                      _mapController = controller;
                    });
                  },
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: true,
                ),

                Positioned(
                  bottom: 100,
                  right: 16,
                  child: FloatingActionButton(
                    onPressed: _goToCurrentLocation,
                    mini: true,
                    child: const Icon(Icons.my_location),
                  ),
                ),

                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${_tasks.length} tarefas',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (_tasks.isNotEmpty)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Legenda:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLegendItem('Urgente', Colors.red),
                          _buildLegendItem('Alta', Colors.orange),
                          _buildLegendItem('Média', Colors.amber),
                          _buildLegendItem('Baixa', Colors.green),
                          _buildLegendItem('Localização', Colors.blue),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskFormScreen(),
            ),
          ).then((result) {
            if (result == true) {
              _loadTasks(); 
            }
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.location_on,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}