package com.aiyin.psdk.demo.bluetooth;

import com.aiyin.psdk.demo.util.CommandItem;
import com.aiyin.psdk.demo.util.PrinterUtil;
import com.printer.psdk.device.adapter.ConnectedDevice;
import com.printer.psdk.device.bluetooth.java.ClassicBluetooth;
import com.printer.psdk.device.bluetooth.java.JConnectListener;
import com.printer.psdk.device.bluetooth.java.JDiscoveryListen;

import javax.bluetooth.*;
import javax.swing.*;
import javax.swing.border.EmptyBorder;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;

public class BluetoothPrint extends JFrame {
  private static final String TAG = "BluetoothPrint";

  private final List<RemoteDevice> foundDevices;
  private JTextArea logArea;
  private JComboBox<String> deviceComboBox;
  private JButton searchButton, stopButton, connectButton, printButton, statusButton;
  private JProgressBar progressBar;
  private boolean isScanning = false;
  private boolean isConnected = false;
  private ButtonGroup commandGroup;
  private List<CommandItem> items;
  private String currentType = "tspl";

  public BluetoothPrint() {
    foundDevices = new ArrayList<>();
    initData();
    initUI();
  }

  private void initUI() {
    setTitle("蓝牙打印机");
    setSize(800, 600);
    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    setLocationRelativeTo(null);

    JPanel mainPanel = new JPanel(new BorderLayout(10, 10));
    mainPanel.setBorder(new EmptyBorder(10, 10, 10, 10));

    JPanel topPanel = new JPanel();
    topPanel.setLayout(new BoxLayout(topPanel, BoxLayout.Y_AXIS));

    JPanel devicePanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    devicePanel.setBorder(BorderFactory.createTitledBorder("设备管理"));
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
    topPanel.add(devicePanel);
    topPanel.add(Box.createVerticalStrut(10));

    JPanel commandPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    commandPanel.setBorder(BorderFactory.createTitledBorder("指令选择"));
    commandGroup = new ButtonGroup();

    JPanel radioContainer = new JPanel(new GridLayout(0, 4, 15, 5));
    for (CommandItem item : items) {
      JRadioButton radio = new JRadioButton(item.type);
      radio.setActionCommand(item.type);
      radio.setSelected(item.checked);
      radio.setFont(new Font("宋体", Font.PLAIN, 12));
      radio.addActionListener(this::radioChange);
      commandGroup.add(radio);
      radioContainer.add(radio);
    }
    commandPanel.add(radioContainer);
    topPanel.add(commandPanel);

    mainPanel.add(topPanel, BorderLayout.NORTH);

    JPanel logPanel = new JPanel(new BorderLayout());
    logPanel.setBorder(BorderFactory.createTitledBorder("操作日志"));
    logArea = new JTextArea();
    logArea.setEditable(false);
    JScrollPane scrollPane = new JScrollPane(logArea);
    logPanel.add(scrollPane, BorderLayout.CENTER);
    mainPanel.add(logPanel, BorderLayout.CENTER);

    JPanel bottomPanel = new JPanel(new BorderLayout(10, 5));

    JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    printButton = new JButton("打印");
    printButton.setEnabled(false);
    statusButton = new JButton("状态");
    statusButton.setEnabled(false);
    buttonPanel.add(printButton);
    buttonPanel.add(statusButton);
    bottomPanel.add(buttonPanel, BorderLayout.NORTH);

    progressBar = new JProgressBar();
    progressBar.setStringPainted(true);
    progressBar.setVisible(false);
    progressBar.setPreferredSize(new Dimension(Integer.MAX_VALUE, 20));
    bottomPanel.add(progressBar, BorderLayout.SOUTH);

    mainPanel.add(bottomPanel, BorderLayout.SOUTH);

    add(mainPanel);

    searchButton.addActionListener(e -> searchDevices());
    stopButton.addActionListener(e -> stopSearch());
    connectButton.addActionListener(e -> connectToSelectedDevice());
    printButton.addActionListener(e -> PrinterUtil.getInstance().printModel(currentType));
    statusButton.addActionListener(e -> {
      String status = PrinterUtil.getInstance().printerStatus(currentType);
      log(status);
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

  private void initData() {
    items = new ArrayList<>();
    items.add(new CommandItem("tspl", true));
    items.add(new CommandItem("cpcl", false));
    items.add(new CommandItem("esc", false));
  }

  private void radioChange(ActionEvent evt) {
    currentType = evt.getActionCommand();
    log("选中的值: " + currentType);
    for (int i = 0; i < items.size(); i++) {
      if (items.get(i).type.equals(currentType)) {
        for (int j = 0; j < items.size(); j++) {
          items.get(j).checked = (j == i);
        }
        break;
      }
    }
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
    if (isConnected) {
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
