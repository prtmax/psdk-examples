package com.aiyin.psdk.demo.util;

public class UploadResult {
  private final boolean success;
  private final String message;
  private final int statusCode; // 可选：记录HTTP状态码

  // 构造方法、getter和setter
  public UploadResult(boolean success, String message, int statusCode) {
    this.success = success;
    this.message = message;
    this.statusCode = statusCode;
  }

  public boolean isSuccess() {
    return success;
  }

  public String getMessage() {
    return message;
  }

  public int getStatusCode() {
    return statusCode;
  }
}
