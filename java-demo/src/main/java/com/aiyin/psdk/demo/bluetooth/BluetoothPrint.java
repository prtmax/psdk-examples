package com.aiyin.psdk.demo.bluetooth;

import com.aiyin.psdk.demo.util.PrinterStatus;
import com.aiyin.psdk.demo.util.PrinterUtil;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.bluetooth.java.ClassicBluetooth;
import com.printer.psdk.device.bluetooth.java.JConnectListener;
import com.printer.psdk.device.bluetooth.java.JDiscoveryListen;

import javax.bluetooth.*;
import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class BluetoothPrint extends JFrame {
  private static final String TAG = "BluetoothPrint";

  private List<RemoteDevice> foundDevices;
  private JTextArea logArea;
  private JComboBox<String> deviceComboBox;
  private JButton searchButton, stopButton, connectButton, printButton, statusButton;
  private JProgressBar progressBar;
  private boolean isScanning = false;
  private boolean isConnected = false;

  public BluetoothPrint() {
    foundDevices = new ArrayList<>();
    initUI();
  }

  private void initUI() {
    setTitle("蓝牙打印机");
    setSize(600, 500);
    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    setLocationRelativeTo(null);

    JPanel mainPanel = new JPanel(new BorderLayout(10, 10));
    mainPanel.setBorder(new EmptyBorder(10, 10, 10, 10));

    // 设备选择面板
    JPanel devicePanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    JLabel deviceLabel = new JLabel("选择设备:");
    deviceComboBox = new JComboBox<>();
    deviceComboBox.setPreferredSize(new Dimension(200, 25));
    searchButton = new JButton("搜索设备");
    stopButton = new JButton("停止");
    stopButton.setEnabled(false);
    connectButton = new JButton("连接");
    connectButton.setEnabled(false);

    devicePanel.add(deviceLabel);
    devicePanel.add(deviceComboBox);
    devicePanel.add(searchButton);
    devicePanel.add(stopButton);
    devicePanel.add(connectButton);

    // 打印内容面板
    JPanel printPanel = new JPanel(new BorderLayout(10, 10));
    printButton = new JButton("打印");
    printButton.setEnabled(false);
    statusButton = new JButton("状态");
    statusButton.setEnabled(false);

    printPanel.add(printButton, BorderLayout.WEST);
    printPanel.add(statusButton, BorderLayout.EAST);

    // 日志面板
    logArea = new JTextArea(15, 50);
    logArea.setEditable(false);
    JScrollPane scrollPane = new JScrollPane(logArea);

    // 进度条
    progressBar = new JProgressBar();
    progressBar.setStringPainted(true);
    progressBar.setVisible(false);

    mainPanel.add(devicePanel, BorderLayout.NORTH);
    mainPanel.add(scrollPane, BorderLayout.CENTER);

    JPanel bottomPanel = new JPanel(new BorderLayout());
    bottomPanel.add(printPanel, BorderLayout.NORTH);
    bottomPanel.add(progressBar, BorderLayout.SOUTH);

    mainPanel.add(bottomPanel, BorderLayout.SOUTH);

    add(mainPanel);

    // 添加按钮事件监听器
    searchButton.addActionListener(e -> searchDevices());
    stopButton.addActionListener(e -> stopSearch());
    connectButton.addActionListener(e -> connectToSelectedDevice());
    printButton.addActionListener(e -> PrinterUtil.getInstance().safeWrite(PrinterUtil.getInstance().generateCmd()));
    statusButton.addActionListener(e -> {
      PrinterStatus status= PrinterUtil.getInstance().status();
      log(status.name());
    });
    // 添加窗口关闭事件
    addWindowListener(new WindowAdapter() {
      @Override
      public void windowClosing(WindowEvent e) {
        if (isScanning) {
          stopSearch();
        }
        disconnect();
        System.exit(0);
      }
    });
  }

  private void searchDevices() {
    if (isScanning) {
      log("扫描已在进行中...");
      return;
    }
    log("开始搜索蓝牙设备...");
    searchButton.setEnabled(false);
    stopButton.setEnabled(true);
    connectButton.setEnabled(false);
    printButton.setEnabled(false);
    deviceComboBox.removeAllItems();
    foundDevices.clear();
    progressBar.setVisible(true);
    progressBar.setIndeterminate(true);
    isScanning = true;
    ClassicBluetooth.getInstance().setDiscoveryListener(new JDiscoveryListen() {
      @Override
      public void onDiscoveryCompleted() {
        SwingUtilities.invokeLater(() -> {
          log("设备搜索完成，共发现 " + foundDevices.size() + " 个设备");
          searchButton.setEnabled(true);
          stopButton.setEnabled(false);
          connectButton.setEnabled(foundDevices.size() > 0);
          progressBar.setIndeterminate(false);
          progressBar.setVisible(false);
          isScanning = false;
        });
      }

      @Override
      public void onDeviceFound(RemoteDevice remoteDevice) {
        try {
          String name = remoteDevice.getFriendlyName(true);
          log("发现设备: " + name + " - " + remoteDevice.getBluetoothAddress());
          SwingUtilities.invokeLater(() -> {
            deviceComboBox.addItem(name + " - " + remoteDevice.getBluetoothAddress());
            foundDevices.add(remoteDevice);
          });
        } catch (IOException e) {
          log("发现设备: [无法获取名称] - " + remoteDevice.getBluetoothAddress());
          SwingUtilities.invokeLater(() -> {
            deviceComboBox.addItem("[无法获取名称] - " + remoteDevice.getBluetoothAddress());
            foundDevices.add(remoteDevice);
          });
        }
      }
      @Override
      public void onDiscoveryError(String s) {
        SwingUtilities.invokeLater(() -> {
          log("搜索失败: " + s);
          searchButton.setEnabled(true);
          stopButton.setEnabled(false);
          progressBar.setIndeterminate(false);
          progressBar.setVisible(false);
          isScanning = false;
        });
      }
    });
    ClassicBluetooth.getInstance().startDiscovery();
  }

  private void stopSearch() {
    if (!isScanning) {
      log("当前没有进行中的扫描");
      return;
    }

    log("正在停止蓝牙扫描...");
    ClassicBluetooth.getInstance().stopDiscovery();

    SwingUtilities.invokeLater(() -> {
      log("蓝牙扫描已停止");
      searchButton.setEnabled(true);
      stopButton.setEnabled(false);
      progressBar.setIndeterminate(false);
      progressBar.setVisible(false);
      isScanning = false;
    });
  }

  private void connectToSelectedDevice() {
    if(isConnected){
      disconnect();
      return;
    }
    int selectedIndex = deviceComboBox.getSelectedIndex();
    if (selectedIndex < 0 || selectedIndex >= foundDevices.size()) {
      log("请先选择一个设备");
      return;
    }

    RemoteDevice selectedDevice = foundDevices.get(selectedIndex);
    log("正在连接到设备: " + selectedDevice.getBluetoothAddress());

    connectButton.setEnabled(false);
    printButton.setEnabled(false);
    progressBar.setVisible(true);
    progressBar.setIndeterminate(true);
    ClassicBluetooth.getInstance().connect(selectedDevice, new JConnectListener() {
      @Override
      public void onConnectSuccess(ConnectedDevice connectedDevice) {
        //传入已连接对象
        PrinterUtil.getInstance().init(connectedDevice);
        SwingUtilities.invokeLater(() -> {
          log("连接成功");
          connectButton.setText("断开连接");
          connectButton.setEnabled(true);
          printButton.setEnabled(true);
          statusButton.setEnabled(true);
          progressBar.setIndeterminate(false);
          progressBar.setVisible(false);
          isConnected = true;
        });
      }

      @Override
      public void onConnectFail(String s) {
        SwingUtilities.invokeLater(() -> {
          log("连接失败: " + s);
          connectButton.setEnabled(true);
          progressBar.setIndeterminate(false);
          progressBar.setVisible(false);
          isConnected = false;
        });
      }
    });
  }

  private void disconnect() {
    try {
      PrinterUtil.getInstance().connectedDevice().disconnect();
      log("已断开连接");
      isConnected = false;
      if (connectButton != null) {
        connectButton.setText("连接");
        printButton.setEnabled(false);
      }
    } catch (Exception e) {
      log("断开连接失败: " + e.getMessage());
    }
  }

  private void log(String message) {
    SwingUtilities.invokeLater(() -> {
      logArea.append(message + "\n");
      logArea.setCaretPosition(logArea.getDocument().getLength());
    });
  }

}
