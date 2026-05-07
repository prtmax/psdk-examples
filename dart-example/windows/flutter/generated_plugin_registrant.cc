//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <ble_plugin/ble_plugin_c_api.h>
#include <bluetooth_low_energy_windows/bluetooth_low_energy_windows_plugin_c_api.h>
#include <dynamic_color/dynamic_color_plugin_c_api.h>
#include <permission_handler_windows/permission_handler_windows_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  BlePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("BlePluginCApi"));
  BluetoothLowEnergyWindowsPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("BluetoothLowEnergyWindowsPluginCApi"));
  DynamicColorPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("DynamicColorPluginCApi"));
  PermissionHandlerWindowsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PermissionHandlerWindowsPlugin"));
}
