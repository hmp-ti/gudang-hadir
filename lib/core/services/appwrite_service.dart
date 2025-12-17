import 'package:appwrite/appwrite.dart';
import '../config/appwrite_config.dart';

class AppwriteService {
  static final AppwriteService instance = AppwriteService._init();

  late final Client client;
  late final Account account;
  late final Databases databases;
  late final TablesDB tables;
  late final Storage storage;

  AppwriteService._init() {
    client = Client()
      ..setEndpoint(AppwriteConfig.endpoint)
      ..setProject(AppwriteConfig.projectId);
    // ..setSelfSigned(status: true); // For self-signed certificates, only use for development

    account = Account(client);
    databases = Databases(client);
    tables = TablesDB(client);
    storage = Storage(client);
  }
}
