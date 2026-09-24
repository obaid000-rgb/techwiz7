import '../models/fandom.dart';

class FandomService {
  Future<List<Fandom>> fetchFandoms() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return [];
  }
}