package com.aiyin.psdk.demo.usb;

import com.aiyin.psdk.demo.util.CommandItem;
import com.aiyin.psdk.demo.util.PrinterUtil;
import com.printer.psdk.device.usb.java.USBConnectedDevice;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.util.ArrayList;
import java.util.List;
import javax.print.*;

public class USBPrinter extends JFrame {
  private static String curPrinter;

  private JComboBox<String> comboBoxPrinter;
  private JButton printButton;
  private JButton statusButton;
  private JButton clearLogButton;
  private JTextArea logArea;

  private ButtonGroup commandGroup;
  private List<CommandItem> items;
  private String currentType = "tspl";
  public USBPrinter() {
    initData();
    setTitle("USB打印机");
    setSize(600, 400);
    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    setLayout(new BorderLayout());

    // 创建顶部面板
    JPanel topPanel = new JPanel(new FlowLayout());
    JLabel labelPrinter = new JLabel("选择打印机:");
    comboBoxPrinter = new JComboBox<>();
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
    printButton = new JButton("打印");
    statusButton = new JButton("打印机状态");
    clearLogButton = new JButton("清除日志");

//    topPanel.add(labelPrinter);
//    topPanel.add(comboBoxPrinter);
    topPanel.add(printButton);
    topPanel.add(statusButton);
    topPanel.add(clearLogButton);

    // 创建日志区域
    logArea = new JTextArea(15, 50);
    logArea.setEditable(false);
    JScrollPane scrollPane = new JScrollPane(logArea);

    // 添加组件到主窗口
    add(topPanel, BorderLayout.NORTH);
    add(scrollPane, BorderLayout.CENTER);

    // 初始化打印机
    initPrinterDriver();

    // 添加事件监听器
    comboBoxPrinter.addActionListener(e -> {
      curPrinter = (String) comboBoxPrinter.getSelectedItem();
      log("已选择打印机: " + curPrinter);
    });

    printButton.addActionListener(e -> PrinterUtil.getInstance().printModel(currentType));
    statusButton.addActionListener(e -> {
      String status = PrinterUtil.getInstance().printerStatus(currentType);
      log(status);
    });

    // 添加清除日志按钮事件监听器
    clearLogButton.addActionListener(e -> {
      logArea.setText("");
      log("日志已清除");
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

  private void updatePrinterList(String defaultPrinter) {
    log("更新打印机列表...");
    // 获取所有可用的打印机
    PrintService[] services = PrintServiceLookup.lookupPrintServices(null, null);
    for (PrintService service : services) {
      String printerName = service.getName();
      comboBoxPrinter.addItem(printerName);
      log("发现打印机: " + printerName);
      if (printerName.equals(defaultPrinter)) {
        comboBoxPrinter.setSelectedItem(printerName);
        log("已设置默认打印机: " + printerName);
      }
    }
    if (comboBoxPrinter.getItemCount() > 0) {
      curPrinter = (String) comboBoxPrinter.getSelectedItem();
      log("当前选择的打印机: " + curPrinter);
    } else {
      log("未找到可用的打印机");
    }
  }

  private void initPrinterDriver() {
    // 获取默认打印机
//    PrintService defaultService = PrintServiceLookup.lookupDefaultPrintService();
//    String defaultPrinter = (defaultService != null) ? defaultService.getName() : "";
//    updatePrinterList(defaultPrinter);
    //初始化后就可以打印了
    PrinterUtil.getInstance().init(new USBConnectedDevice());
    log("打印机初始化完成");
  }

  private void log(String message) {
    logArea.append(message + "\n");
    logArea.setCaretPosition(logArea.getDocument().getLength());
  }
}
