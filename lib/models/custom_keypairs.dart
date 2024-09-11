import 'package:dart_nostr/dart_nostr.dart';
import 'package:bip340/bip340.dart' as bip340;

// ignore: must_be_immutable
class CustomKeyPairs implements NostrKeyPairs {
  @override
  // ignore: overridden_fields
  final String private;

  @override
  // ignore: overridden_fields
  final String public;

  CustomKeyPairs({required this.private, required this.public});

  @override
  // TODO: implement stringify
  bool? get stringify => true;

  @override
  // TODO: implement props
  List<Object?> get props => throw UnimplementedError();

  @override
  String sign(String message) {
    final aux = Nostr.instance.utilsService.random64HexChars();
    return bip340.sign(private, message, aux);
  }

  @override
  set public(String _public) {
    public = _public;
  }
}
