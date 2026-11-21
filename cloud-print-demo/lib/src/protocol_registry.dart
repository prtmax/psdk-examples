import 'package:psdk_color_core/psdk_color_core.dart';
import 'package:psdk_device_adapter/psdk_device_adapter.dart';
import 'package:psdk_frame_cloud/psdk_frame_cloud.dart';
import 'package:psdk_fruit_inkjet/psdk_fruit_inkjet.dart';
import 'package:psdk_fruit_sublimation/psdk_fruit_sublimation.dart';

/// Registers all supported cloud/Wi-Fi/color protocols onto [CloudPrinterRegistry].
///
/// `psdk_fruit_sublimation` provides `registerSublimationProtocol`, whereas
/// `psdk_fruit_inkjet` does not ship a registry helper on `main` and is
/// registered explicitly here.
void registerDemoProtocols(
  CloudPrinterRegistry registry, {
  required ColorCoreEngine colorCore,
  SublimationUdpTransport? sublimationUdpTransport,
  SublimationTransportConnector? sublimationConnector,
  InkjetMdnsBrowser? inkjetMdnsBrowser,
  InkjetSoftApProbeTransport? inkjetSoftApProbe,
  InkjetNetworkBinder? inkjetNetworkBinder,
  InkjetBleGattHooks? inkjetBleGattHooks,
  bool allowInkjetLoopback = true,
  bool enrichMdnsWithXslQuery = false,
}) {
  registerSublimationProtocol(
    registry,
    colorCore: colorCore,
    transportConnector: sublimationConnector,
    udpTransport: sublimationUdpTransport ?? const RawDatagramUdpTransport(),
  );

  registry.registerDriver(CloudPrinterFamily.colorInkjetPjl, ({
    ConnectedDevice<dynamic>? device,
    DiscoveredCloudPrinter? printer,
  }) {
    return InkjetPrinterDriver(
      colorCore: colorCore,
      networkBinder: inkjetNetworkBinder,
    );
  });

  registry.registerProvisioner(WifiProvisionProtocol.inkjetBleAcl, ({
    ConnectedDevice<dynamic>? device,
  }) {
    return InkjetBleProvisioner(device: device, hooks: inkjetBleGattHooks);
  });

  registry.registerScanner(
    LanDiscoveryProtocol.mdnsPrinterTcp,
    () => InkjetDiscoveryAdapter(
      mdnsBrowser: inkjetMdnsBrowser,
      networkBinder: inkjetNetworkBinder,
      softApProbeTransport: inkjetSoftApProbe,
      enrichMdnsWithXslQuery: enrichMdnsWithXslQuery,
      allowLoopbackForTesting: allowInkjetLoopback,
    ),
  );

  registry.registerScanner(
    LanDiscoveryProtocol.softApProbe,
    () => InkjetDiscoveryAdapter(
      mdnsBrowser: inkjetMdnsBrowser,
      networkBinder: inkjetNetworkBinder,
      softApProbeTransport: inkjetSoftApProbe,
      allowLoopbackForTesting: allowInkjetLoopback,
    ),
  );
}
