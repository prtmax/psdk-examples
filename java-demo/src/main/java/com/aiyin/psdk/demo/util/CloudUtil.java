package com.aiyin.psdk.demo.util;

import org.apache.hc.client5.http.classic.methods.HttpPost;
import org.apache.hc.client5.http.entity.mime.MultipartEntityBuilder;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.CloseableHttpResponse;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.ContentType;
import org.apache.hc.core5.http.HttpStatus;
import org.apache.hc.core5.http.ParseException;
import org.apache.hc.core5.http.io.entity.EntityUtils;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;

public class CloudUtil {

  public static void saveByteToFile(byte[] cmd, String filePath) throws IOException {
    //使用Files.write（Java NIO，推荐）
    Path path = Paths.get(filePath);
    Path parentDir = path.getParent();
    if (parentDir != null) {
      Files.createDirectories(parentDir);
    }
    Files.write(path, cmd);
    System.out.println("文件保存成功：" + filePath);
  }

  /**
   * 发送指令到云打印服务
   * @param cmd 二进制指令数据
   */
  public static UploadResult sendMessage(byte[] cmd, String deviceID) {
    String filePath = "temp/print_cmd.bin";
    try {
      saveByteToFile(cmd, filePath);
      return uploadFileToServer(filePath, deviceID);
    } catch (IOException e) {
      String errorMsg = "发送消息失败：" + e.getMessage();
      return new UploadResult(false, errorMsg, -1);
    }
  }

  /**
   * 上传文件到云打印服务器
   * @return 上传结果对象
   */
  public static UploadResult uploadFileToServer(String filePath, String deviceID) {
    String url = "https://wiot.iprtapp.com/sw/files/ptFile";

    try (CloseableHttpClient httpClient = HttpClients.createDefault()) {
      HttpPost httpPost = new HttpPost(url);

      MultipartEntityBuilder builder = MultipartEntityBuilder.create();
      File file = new File(filePath);

      builder.addBinaryBody(
              "file",
              Files.newInputStream(file.toPath()),
              ContentType.APPLICATION_OCTET_STREAM,
              file.getName()
      );

      builder.addTextBody("devid", deviceID);
      builder.addTextBody("type", "1");
      builder.addTextBody("width", "100");
      builder.addTextBody("height", "100");

      httpPost.setEntity(builder.build());

      // 执行请求
      try (CloseableHttpResponse response = httpClient.execute(httpPost)) {
        int statusCode = response.getCode();
        String responseBody = EntityUtils.toString(response.getEntity(), "UTF-8");

        if (statusCode == HttpStatus.SC_OK) {
          String successMsg = "文件上传成功，设备ID：" + deviceID + "，响应：" + responseBody;
          return new UploadResult(true, successMsg, statusCode);
        } else {
          String errorMsg = "文件上传失败，设备ID：" + deviceID +
                  "，状态码：" + statusCode + "，响应：" + responseBody;
          return new UploadResult(false, errorMsg, statusCode);
        }
      } catch (ParseException e) {
        throw new RuntimeException(e);
      }
    } catch (IOException e) {
      String errorMsg = "文件上传发生异常，设备ID：" + deviceID + "，错误：" + e.getMessage();
      return new UploadResult(false, errorMsg, -1);
    }
  }
}
