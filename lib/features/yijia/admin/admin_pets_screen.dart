import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_theme.dart';
import '../../../core/services/pet_service.dart';
import '../../../core/widgets/animated_pet_widget.dart';
import '../../../core/widgets/empty_state_widget.dart';
import '../../../core/widgets/loading_widget.dart';
import '../../../models/pet_model.dart';
import '../../../core/widgets/app_snackbar.dart';

class AdminPetsScreen extends StatefulWidget {
  const AdminPetsScreen({super.key});

  @override
  State<AdminPetsScreen> createState() => _AdminPetsScreenState();
}

class _AdminPetsScreenState extends State<AdminPetsScreen> {
  List<PetModel> _pets = [];
  bool _isLoading = true;
  bool _isUploading = false;

  String? _soundUrl;
  bool _isUploadingSound = false;

  final _nameController = TextEditingController();
  final _priceController = TextEditingController(text: '100');
  final _descController = TextEditingController();
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final pets = await PetService.getAllPets();
    if (mounted) setState(() { _pets = pets; _isLoading = false; });
  }

  Future<String?> _pickAndUploadImage(StateSetter setModalState) async {
    // Ask user what type of file
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const Text('Select Pet Image',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.primary,
                  child: Icon(Icons.gif_box, color: Colors.white)),
              title: const Text('Upload GIF (Animated)'),
              subtitle: const Text('Recommended for animated pets'),
              onTap: () => Navigator.pop(context, 'gif'),
            ),
            ListTile(
              leading: const CircleAvatar(
                  backgroundColor: AppTheme.secondary,
                  child: Icon(Icons.image, color: Colors.white)),
              title: const Text('Upload Image (PNG/JPG)'),
              onTap: () => Navigator.pop(context, 'image'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (choice == null) return null;

    setModalState(() => _isUploading = true);

    try {
      String? url;

      if (choice == 'gif') {
        // Use file_picker for GIF — no compression
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['gif'],
        );
        if (result == null || result.files.isEmpty) {
          setModalState(() => _isUploading = false);
          return null;
        }

        final file = File(result.files.single.path!);
        final bytes = await file.readAsBytes();
        final fileName = 'pet_${DateTime.now().millisecondsSinceEpoch}.gif';

        await Supabase.instance.client.storage
            .from('pets')
            .uploadBinary(fileName, bytes,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/gif', // important!
            ));

        url = Supabase.instance.client.storage
            .from('pets')
            .getPublicUrl(fileName);
      } else {
        // Regular image via image_picker
        final picker = ImagePicker();
        final source = await showModalBottomSheet<ImageSource>(
          context: context,
          shape: const RoundedRectangleBorder(
              borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                const Text('Select Source',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: AppTheme.primary,
                      child: Icon(Icons.camera_alt, color: Colors.white)),
                  title: const Text('Take a Photo'),
                  onTap: () =>
                      Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: AppTheme.secondary,
                      child:
                      Icon(Icons.photo_library, color: Colors.white)),
                  title: const Text('Choose from Gallery'),
                  onTap: () =>
                      Navigator.pop(context, ImageSource.gallery),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );

        if (source == null) {
          setModalState(() => _isUploading = false);
          return null;
        }

        final picked = await picker.pickImage(
            source: source, maxWidth: 512, imageQuality: 80);
        if (picked == null) {
          setModalState(() => _isUploading = false);
          return null;
        }

        final bytes = await picked.readAsBytes();
        final fileName =
            'pet_${DateTime.now().millisecondsSinceEpoch}.jpg';

        await Supabase.instance.client.storage
            .from('pets')
            .uploadBinary(fileName, bytes,
            fileOptions: const FileOptions(upsert: true));

        url = Supabase.instance.client.storage
            .from('pets')
            .getPublicUrl(fileName);
      }

      setModalState(() {
        _imageUrl = url;
        _isUploading = false;
      });
      return url;
    } catch (e) {
      setModalState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Upload failed: $e')));
      }
      return null;
    }
  }

  Future<void> _showForm({PetModel? pet}) async {
    if (pet != null) {
      _nameController.text = pet.name;
      _priceController.text = pet.price.toString();
      _descController.text = pet.description ?? '';
      _imageUrl = pet.imageUrl;
      _soundUrl = pet.soundUrl;
    } else {
      _nameController.clear();
      _priceController.text = '100';
      _descController.clear();
      _imageUrl = null;
      _soundUrl = null;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(pet == null ? 'Add New Pet' : 'Edit Pet',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                // Pet image preview
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.petsColor.withValues(alpha:0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.petsColor.withValues(alpha:0.3)),
                        ),
                        child: _imageUrl != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AnimatedPetWidget(
                            imageUrl: _imageUrl,
                            size: 100,
                            animate: false,
                            interactive: false,
                          ),
                        )
                            : const Icon(Icons.pets,
                            size: 48, color: AppTheme.petsColor),
                      ),
                      GestureDetector(
                        onTap: _isUploading
                            ? null
                            : () =>
                            _pickAndUploadImage(setModalState),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: _isUploading
                              ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2))
                              : const Icon(Icons.camera_alt,
                              color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'Tip: Upload a GIF for animated pets!',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Pet Sound',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _isUploadingSound
                      ? null
                      : () => _pickAndUploadSound(setModalState),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _soundUrl != null
                          ? AppTheme.success.withValues(alpha:0.1)
                          : AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _soundUrl != null
                            ? AppTheme.success
                            : AppTheme.border,
                      ),
                    ),
                    child: _isUploadingSound
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(width: 12),
                        Text('Uploading sound...'),
                      ],
                    )
                        : Row(
                      children: [
                        Icon(
                          _soundUrl != null
                              ? Icons.music_note
                              : Icons.upload_file,
                          color: _soundUrl != null
                              ? AppTheme.success
                              : AppTheme.textSecondary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                _soundUrl != null
                                    ? 'Sound uploaded ✓'
                                    : 'Upload pet sound',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _soundUrl != null
                                      ? AppTheme.success
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                _soundUrl != null
                                    ? 'Tap to replace (MP3/WAV)'
                                    : 'Tap to select MP3 or WAV file',
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                      labelText: 'Pet Name',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Price (Coins)',
                      border: OutlineInputBorder(),
                      prefixIcon:
                      Icon(Icons.monetization_on)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.trim().isEmpty) {
                      AppSnackbar.warning(context, 'Please enter a pet name.');
                      return;
                    }
                    try {
                      if (pet == null) {
                        await PetService.createPet(
                          name: _nameController.text.trim(),
                          price: int.tryParse(_priceController.text) ?? 100,
                          imageUrl: _imageUrl,
                          description: _descController.text.trim(),
                          soundUrl: _soundUrl,
                        );
                        if (context.mounted) Navigator.pop(context);
                        _load();
                        if (context.mounted) {
                          AppSnackbar.success(context, 'Pet added to the shop!');
                        }
                      } else {
                        await PetService.updatePet(pet.id, {
                          'name': _nameController.text.trim(),
                          'price': int.tryParse(_priceController.text) ?? 100,
                          'image_url': _imageUrl,
                          'description': _descController.text.trim(),
                          'sound_url': _soundUrl,
                        });
                        if (context.mounted) Navigator.pop(context);
                        _load();
                        if (context.mounted) {
                          AppSnackbar.success(context, 'Pet updated successfully!');
                        }
                      }
                    } catch (e) {
                      if (context.mounted) {
                        AppSnackbar.error(context, 'Failed: ${e.toString()}');
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child:
                  Text(pet == null ? 'Add Pet' : 'Update Pet'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _delete(PetModel pet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Pet'),
        content: Text(
            'Remove "${pet.name}" from the shop? Children who own this pet will keep it.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: AppTheme.danger))),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await PetService.deletePet(pet.id);
        _load();
        if (mounted) {
          AppSnackbar.success(context, '"${pet.name}" removed from shop.');
        }
      } catch (e) {
        if (mounted) {
          AppSnackbar.error(context, 'Failed to delete: ${e.toString()}');
        }
      }
    }
  }

  Future<void> _pickAndUploadSound(StateSetter setModalState) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg'],
    );

    if (result == null || result.files.isEmpty) return;

    setModalState(() => _isUploadingSound = true);
    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();
      final ext = result.files.single.extension ?? 'mp3';
      final fileName =
          'pet_sound_${DateTime.now().millisecondsSinceEpoch}.$ext';

      await Supabase.instance.client.storage
          .from('pet-sounds')
          .uploadBinary(fileName, bytes,
          fileOptions: FileOptions(
            upsert: true,
            contentType: ext == 'mp3'
                ? 'audio/mpeg'
                : ext == 'wav'
                ? 'audio/wav'
                : 'audio/ogg',
          ));

      final url = Supabase.instance.client.storage
          .from('pet-sounds')
          .getPublicUrl(fileName);

      setModalState(() {
        _soundUrl = url;
        _isUploadingSound = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sound uploaded!')));
      }
    } catch (e) {
      setModalState(() => _isUploadingSound = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sound upload failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Pets')),
      body: _isLoading
          ? const LoadingWidget()
          : _pets.isEmpty
          ? EmptyStateWidget(
        message: 'No pets yet.\nTap + to add one.',
        icon: Icons.pets,
        actionLabel: 'Add Pet',
        onAction: () => _showForm(),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pets.length,
        itemBuilder: (_, i) {
          final pet = _pets[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              leading: AnimatedPetWidget(
                  imageUrl: pet.imageUrl,
                  size: 48,
                  animate: false),
              title: Text(pet.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold)),
              subtitle: Text(
                  '${pet.price} coins · ${pet.description ?? 'No description'}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: AppTheme.textSecondary),
                    onPressed: () => _showForm(pet: pet),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        color: AppTheme.danger),
                    onPressed: () => _delete(pet),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}