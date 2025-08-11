package com.aiyin.psdk.demo.util;

public class CommandItem {
  public String type; // 指令类型
  public boolean checked;

  public CommandItem(String type, boolean checked) {
    this.type = type;
    this.checked = checked;
  }
}
