package com.psdk.examples.cloud_print_demo

import android.content.Context
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.wifi.WifiManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.net.Inet4Address

class MainActivity : FlutterActivity() {
    private var multicastLock: WifiManager.MulticastLock? = null
    private var discoveryWifiLock: WifiManager.WifiLock? = null
    private var discoveryNetworkCallback: ConnectivityManager.NetworkCallback? = null
    private var discoveryNetworkTimeout: Runnable? = null
    private var discoveryBoundNetwork: Network? = null
    private var discoveryNetworkInterface: String? = null
    private var discoveryNetworkAddress: String? = null
    private var discoveryNetworkPrefixLength: Int? = null
    private val discoveryBeginResults = mutableListOf<MethodChannel.Result>()
    private var discoveryNetworkGeneration = 0
    private var discoveryNetworkActive = false
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.psdk.examples.cloud_print_demo/android_sdk",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "sdkInt" -> result.success(Build.VERSION.SDK_INT)
                "beginLanDiscoveryNetwork" -> beginLanDiscoveryNetwork(result)
                "endLanDiscoveryNetwork" -> endLanDiscoveryNetwork(result)
                "lanDiscoveryNetworkInfo" -> result.success(
                    discoveryNetworkInfo(),
                )
                "acquireMulticastLock" -> {
                    try {
                        val lock = multicastLock ?: createMulticastLock()
                        if (!lock.isHeld) lock.acquire()
                        multicastLock = lock
                        result.success(true)
                    } catch (error: Exception) {
                        result.error(
                            "multicast_lock_unavailable",
                            error.message,
                            null,
                        )
                    }
                }
                "releaseMulticastLock" -> {
                    try {
                        multicastLock?.let { lock ->
                            if (lock.isHeld) lock.release()
                        }
                        multicastLock = null
                        result.success(true)
                    } catch (error: Exception) {
                        result.error(
                            "multicast_unlock_failed",
                            error.message,
                            null,
                        )
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun beginLanDiscoveryNetwork(result: MethodChannel.Result) {
        if (discoveryNetworkActive) {
            if (discoveryBoundNetwork != null) {
                result.success(true)
            } else {
                discoveryBeginResults.add(result)
            }
            return
        }

        val connectivityManager = applicationContext.getSystemService(
            Context.CONNECTIVITY_SERVICE,
        ) as? ConnectivityManager ?: run {
            result.error(
                "network_service_unavailable",
                "Connectivity service is unavailable",
                null,
            )
            return
        }
        val wifiManager = applicationContext.getSystemService(
            Context.WIFI_SERVICE,
        ) as? WifiManager ?: run {
            result.error(
                "wifi_service_unavailable",
                "Wi-Fi service is unavailable",
                null,
            )
            return
        }
        if (!wifiManager.isWifiEnabled) {
            result.error(
                "wifi_disabled",
                "Wi-Fi is disabled",
                null,
            )
            return
        }

        val generation = ++discoveryNetworkGeneration
        discoveryNetworkActive = true
        discoveryBeginResults.add(result)
        try {
            val wifiLock = wifiManager.createWifiLock(
                WifiManager.WIFI_MODE_FULL_HIGH_PERF,
                "cloud_print_demo_lan_discovery",
            ).apply {
                setReferenceCounted(false)
                acquire()
            }
            discoveryWifiLock = wifiLock

            val callback = object : ConnectivityManager.NetworkCallback() {
                override fun onAvailable(network: Network) {
                    mainHandler.post {
                        bindDiscoveryNetwork(
                            connectivityManager,
                            network,
                            generation,
                        )
                    }
                }

                override fun onLinkPropertiesChanged(
                    network: Network,
                    linkProperties: LinkProperties,
                ) {
                    mainHandler.post {
                        bindDiscoveryNetwork(
                            connectivityManager,
                            network,
                            generation,
                            linkProperties,
                        )
                    }
                }

                override fun onLost(network: Network) {
                    mainHandler.post {
                        if (generation != discoveryNetworkGeneration ||
                            discoveryBoundNetwork != network
                        ) {
                            return@post
                        }
                        failDiscoveryNetwork(
                            generation,
                            "wifi_network_lost",
                            "The Wi-Fi network was lost during discovery",
                        )
                    }
                }

                override fun onUnavailable() {
                    mainHandler.post {
                        failDiscoveryNetwork(
                            generation,
                            "wifi_network_unavailable",
                            "No connected Wi-Fi network with IPv4 is available",
                        )
                    }
                }
            }
            discoveryNetworkCallback = callback
            connectivityManager.requestNetwork(
                NetworkRequest.Builder()
                    .addTransportType(NetworkCapabilities.TRANSPORT_WIFI)
                    .build(),
                callback,
            )

            val timeout = Runnable {
                failDiscoveryNetwork(
                    generation,
                    "wifi_network_timeout",
                    "Timed out waiting for the current Wi-Fi network",
                )
            }
            discoveryNetworkTimeout = timeout
            mainHandler.postDelayed(timeout, DISCOVERY_NETWORK_TIMEOUT_MS)
        } catch (error: Exception) {
            failDiscoveryNetwork(
                generation,
                "wifi_network_binding_failed",
                error.message,
            )
        }
    }

    private fun bindDiscoveryNetwork(
        connectivityManager: ConnectivityManager,
        network: Network,
        generation: Int,
        linkProperties: LinkProperties? = null,
    ) {
        if (generation != discoveryNetworkGeneration ||
            !discoveryNetworkActive
        ) {
            return
        }
        val capabilities = connectivityManager.getNetworkCapabilities(network)
        if (capabilities == null ||
            !capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) ||
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_VPN)
        ) {
            return
        }
        val links = linkProperties
            ?: connectivityManager.getLinkProperties(network)
        val ipv4Link = ipv4LinkAddress(links)
        if (ipv4Link == null) {
            return
        }
        if (!connectivityManager.bindProcessToNetwork(network)) {
            failDiscoveryNetwork(
                generation,
                "wifi_network_binding_failed",
                "Android rejected the Wi-Fi process binding",
            )
            return
        }
        discoveryBoundNetwork = network
        discoveryNetworkInterface = links?.interfaceName
        discoveryNetworkAddress = ipv4Link.address.hostAddress
        discoveryNetworkPrefixLength = ipv4Link.prefixLength
        discoveryNetworkTimeout?.let(mainHandler::removeCallbacks)
        discoveryNetworkTimeout = null
        completeDiscoveryBeginResults(true)
    }

    private fun failDiscoveryNetwork(
        generation: Int,
        code: String,
        message: String?,
    ) {
        if (generation != discoveryNetworkGeneration) return
        val pendingResults = takeDiscoveryBeginResults()
        closeDiscoveryNetwork()
        pendingResults.forEach { it.error(code, message, null) }
    }

    private fun endLanDiscoveryNetwork(result: MethodChannel.Result?) {
        val pendingResults = takeDiscoveryBeginResults()
        closeDiscoveryNetwork()
        pendingResults.forEach {
            it.error(
                "wifi_network_binding_cancelled",
                "Wi-Fi discovery binding was cancelled",
                null,
            )
        }
        result?.success(true)
    }

    private fun completeDiscoveryBeginResults(success: Boolean) {
        val pendingResults = takeDiscoveryBeginResults()
        pendingResults.forEach {
            if (success) {
                it.success(true)
            } else {
                it.error(
                    "wifi_network_binding_failed",
                    "Wi-Fi discovery binding failed",
                    null,
                )
            }
        }
    }

    private fun takeDiscoveryBeginResults(): List<MethodChannel.Result> {
        val pendingResults = discoveryBeginResults.toList()
        discoveryBeginResults.clear()
        return pendingResults
    }

    private fun closeDiscoveryNetwork() {
        discoveryNetworkGeneration += 1
        discoveryNetworkActive = false
        discoveryNetworkTimeout?.let(mainHandler::removeCallbacks)
        discoveryNetworkTimeout = null

        val callback = discoveryNetworkCallback
        discoveryNetworkCallback = null
        val connectivityManager = applicationContext.getSystemService(
            Context.CONNECTIVITY_SERVICE,
        ) as? ConnectivityManager
        if (callback != null) {
            try {
                connectivityManager?.unregisterNetworkCallback(callback)
            } catch (_: Exception) {
                // The callback may already have been removed by Android.
            }
        }

        try {
            connectivityManager?.bindProcessToNetwork(null)
        } catch (_: Exception) {
            // Best effort: activity teardown still clears the process binding.
        }
        discoveryBoundNetwork = null
        discoveryNetworkInterface = null
        discoveryNetworkAddress = null
        discoveryNetworkPrefixLength = null

        discoveryWifiLock?.let { lock ->
            if (lock.isHeld) lock.release()
        }
        discoveryWifiLock = null
    }

    private fun ipv4LinkAddress(
        linkProperties: LinkProperties?,
    ): android.net.LinkAddress? {
        return linkProperties?.linkAddresses?.firstOrNull { link ->
            val address = link.address
            address is Inet4Address &&
                !address.isLoopbackAddress &&
                !address.isAnyLocalAddress &&
                !address.isLinkLocalAddress &&
                link.prefixLength > 0
        }
    }

    private fun discoveryNetworkInfo(): Map<String, Any>? {
        val address = discoveryNetworkAddress ?: return null
        val prefixLength = discoveryNetworkPrefixLength ?: return null
        return buildMap {
            put("address", address)
            put("prefixLength", prefixLength)
            discoveryNetworkInterface?.let { put("interfaceName", it) }
        }
    }

    private fun createMulticastLock(): WifiManager.MulticastLock {
        val wifiManager = applicationContext.getSystemService(
            Context.WIFI_SERVICE,
        ) as? WifiManager ?: error("Wi-Fi service is unavailable")
        return wifiManager.createMulticastLock(
            "cloud_print_demo_lan_discovery",
        ).apply {
            setReferenceCounted(false)
        }
    }

    override fun onDestroy() {
        endLanDiscoveryNetwork(null)
        multicastLock?.let { lock ->
            if (lock.isHeld) lock.release()
        }
        multicastLock = null
        super.onDestroy()
    }

    private companion object {
        const val DISCOVERY_NETWORK_TIMEOUT_MS = 3_000L
    }
}
