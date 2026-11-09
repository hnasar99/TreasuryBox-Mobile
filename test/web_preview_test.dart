import 'package:flutter_test/flutter_test.dart';
import 'package:treasurybox_mobile/core/signer/web_preview_signer.dart';

void main() {
  test('web preview cannot connect or sign typed data', () async {
    final signer = WebPreviewSigner();
    expect(signer.connected, isFalse);
    expect(signer.address, isNull);
    expect(signer.chains, isEmpty);
    await signer.configure('unused');
    await expectLater(
      signer.connect(['eip155:42220'], (_) async {}),
      throwsA(isA<StateError>()),
    );
    await expectLater(
      signer.signTypedData(caip2: 'eip155:42220', typedDataJson: '{}'),
      throwsA(isA<StateError>()),
    );
    await signer.disconnect();
    expect(signer.connected, isFalse);
  });
}
