package com.aiyin.psdk.demo.cloud;

import com.aiyin.psdk.demo.util.CloudUtil;
import com.aiyin.psdk.demo.util.CommandItem;
import com.aiyin.psdk.demo.util.PrinterUtil;

import javax.swing.*;
import java.awt.*;
import java.awt.event.ActionEvent;
import java.util.ArrayList;
import java.util.List;

public class CloudPrinter extends JFrame {
  private JButton printButton;
  private JButton clearLogButton;
  private final JTextArea logArea;

  private ButtonGroup commandGroup;
  private final JTextField deviceIDField;
  private List<CommandItem> items;
  private String currentType = "tspl";
  public CloudPrinter() {
    initData();
    setTitle("云打印机");
    setSize(600, 400);
    setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
    setLayout(new BorderLayout());

    JPanel topContainer = new JPanel();
    topContainer.setLayout(new BoxLayout(topContainer, BoxLayout.Y_AXIS));
    topContainer.setBorder(BorderFactory.createEmptyBorder(10, 10, 10, 10));

    JPanel commandPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    commandPanel.setBorder(BorderFactory.createTitledBorder("指令选择"));
    commandGroup = new ButtonGroup();

    JPanel radioContainer = new JPanel(new GridLayout(0, 3, 15, 5));
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
    topContainer.add(commandPanel);
    topContainer.add(Box.createVerticalStrut(10));

    JPanel deviceIDPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    deviceIDPanel.setBorder(BorderFactory.createEmptyBorder(5, 5, 5, 5));

    JLabel deviceIDLabel = new JLabel("机器码:");
    deviceIDField = new JTextField(20);
    deviceIDField.setToolTipText("请输入机器码");
    deviceIDField.setText("SW244100075");
    deviceIDField.setPreferredSize(new Dimension(150, 25));

    deviceIDPanel.add(deviceIDLabel);
    deviceIDPanel.add(deviceIDField);
    topContainer.add(deviceIDPanel);
    topContainer.add(Box.createVerticalStrut(10));

    JPanel buttonPanel = new JPanel(new FlowLayout(FlowLayout.LEFT));
    printButton = new JButton("打印");
    clearLogButton = new JButton("清除日志");
    buttonPanel.add(printButton);
    buttonPanel.add(clearLogButton);
    topContainer.add(buttonPanel);

    logArea = new JTextArea(15, 50);
    logArea.setEditable(false);
    JScrollPane scrollPane = new JScrollPane(logArea);
    scrollPane.setBorder(BorderFactory.createTitledBorder("操作日志"));

    add(topContainer, BorderLayout.NORTH);
    add(scrollPane, BorderLayout.CENTER);

    printButton.addActionListener(e -> {
      String deviceID = deviceIDField.getText().trim();
      if (deviceID.isEmpty()) {
        JOptionPane.showMessageDialog(this, "请输入机器码", "提示", JOptionPane.WARNING_MESSAGE);
        return;
      }
      log("开始打印，机器码: " + deviceID + "，指令类型: " + currentType);
      byte[] data = PrinterUtil.getInstance().getPrintData(currentType);
      try {
        CloudUtil.sendMessage(data, deviceID);
      } catch (Exception ex) {
        log("发送失败: "+ ex.getMessage());
      }
    });

    // 清除日志按钮事件
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

  private void log(String message) {
    logArea.append(message + "\n");
    logArea.setCaretPosition(logArea.getDocument().getLength());
  }
}
