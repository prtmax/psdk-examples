package com.aiyin.psdk.demo.usb;

import com.aiyin.psdk.demo.util.PrinterStatus;
import com.aiyin.psdk.demo.util.PrinterUtil;
import com.printer.psdk.device.usb.java.USBConnectedDevice;

import javax.swing.*;
import java.awt.*;
import javax.print.*;

public class USBPrinter extends JFrame {
  private static String curPrinter;

  private JComboBox<String> comboBoxPrinter;
  private JButton button1;
  private JButton button2;
  private JButton clearLogButton;
  private JTextArea logArea;
  public USBPrinter() {
    setTitle("标签打印机");
    setSize(600, 400);
    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    setLayout(new BorderLayout());

    // 创建顶部面板
    JPanel topPanel = new JPanel(new FlowLayout());
    JLabel labelPrinter = new JLabel("选择打印机:");
    comboBoxPrinter = new JComboBox<>();
    button1 = new JButton("TSPL指令打印");
    button2 = new JButton("打印机状态");
    clearLogButton = new JButton("清除日志");

//    topPanel.add(labelPrinter);
//    topPanel.add(comboBoxPrinter);
    topPanel.add(button1);
    topPanel.add(button2);
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

    button1.addActionListener(e -> {
      log("开始TSPL指令打印...");
      try {
        PrinterUtil.getInstance().safeWrite(PrinterUtil.getInstance().generateCmd());
        log("TSPL指令打印完成");
      } catch (Exception ex) {
        log("TSPL指令打印错误: " + ex.getMessage());
        ex.printStackTrace();
      }
    });
    button2.addActionListener(e -> {
      PrinterStatus status= PrinterUtil.getInstance().status();
      log(status.name());
    });

    // 添加清除日志按钮事件监听器
    clearLogButton.addActionListener(e -> {
      logArea.setText("");
      log("日志已清除");
    });
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
