import 'package:cloud_print_demo/src/utils/icc_profile_loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundled inkjet and sublimation ICC profiles load and cache', () async {
    final h100 = await IccProfileLoader.load(IccProfileLoader.h100Chart);
    expect(h100, hasLength(2502580));
    expect(
      identical(h100, await IccProfileLoader.load(IccProfileLoader.h100Chart)),
      isTrue,
    );

    final z11 = await IccProfileLoader.load(IccProfileLoader.z11D380);
    expect(z11, hasLength(2442864));
    expect(
      identical(z11, await IccProfileLoader.load(IccProfileLoader.z11D380)),
      isTrue,
    );
  });
}
