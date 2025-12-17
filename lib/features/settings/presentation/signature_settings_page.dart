import 'dart:io';
import 'package:appwrite/appwrite.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/config/appwrite_config.dart';
import '../../../../core/services/appwrite_service.dart';
import '../../settings/data/settings_dao.dart';

class SignatureSettingsPage extends ConsumerStatefulWidget {
  const SignatureSettingsPage({super.key});

  @override
  ConsumerState<SignatureSettingsPage> createState() => _SignatureSettingsPageState();
}

class _SignatureSettingsPageState extends ConsumerState<SignatureSettingsPage> {
  final _nameCtrl = TextEditingController();
  String? _signatureId;
  String? _stampId;
  File? _newSignature;
  File? _newStamp;
  bool _isLoading = false;

  late SettingsDao _dao;

  @override
  void initState() {
    super.initState();
    _dao = SettingsDao(AppwriteService.instance);
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    final config = await _dao.getSignatureConfig();
    _nameCtrl.text = config['signerName'] ?? '';
    setState(() {
      _signatureId = config['signatureFileId'];
      _stampId = config['stampFileId'];
      _isLoading = false;
    });
  }

  Future<void> _pickImage(bool isSignature) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (isSignature) {
          _newSignature = File(picked.path);
        } else {
          _newStamp = File(picked.path);
        }
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      String? sigId = _signatureId;
      String? stpId = _stampId;

      if (_newSignature != null) {
        final file = await AppwriteService.instance.storage.createFile(
          bucketId: AppwriteConfig.storageBucketId,
          fileId: 'unique()',
          file: InputFile.fromPath(path: _newSignature!.path, filename: 'signature.png'),
        );
        sigId = file.$id;
      }

      if (_newStamp != null) {
        final file = await AppwriteService.instance.storage.createFile(
          bucketId: AppwriteConfig.storageBucketId,
          fileId: 'unique()',
          file: InputFile.fromPath(path: _newStamp!.path, filename: 'stamp.png'),
        );
        stpId = file.$id;
      }

      await _dao.setSignatureConfig(_nameCtrl.text, sigId, stpId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disimpan!')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Konfigurasi Tanda Tangan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Penanda Tangan'),
                ),
                const SizedBox(height: 20),
                const Text('Tanda Tangan', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_newSignature != null)
                  Image.file(_newSignature!, height: 100)
                else if (_signatureId != null)
                  const Text('File Tersimpan (Preview from storage TODO)')
                else
                  const Text('Belum ada tanda tangan'),
                ElevatedButton(onPressed: () => _pickImage(true), child: const Text('Upload Tanda Tangan')),
                const SizedBox(height: 20),
                const Text('Stempel', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_newStamp != null)
                  Image.file(_newStamp!, height: 100)
                else if (_stampId != null)
                  const Text('File Tersimpan')
                else
                  const Text('Belum ada stempel'),
                ElevatedButton(onPressed: () => _pickImage(false), child: const Text('Upload Stempel')),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  child: const Text('Simpan Konfigurasi'),
                ),
              ],
            ),
    );
  }
}
