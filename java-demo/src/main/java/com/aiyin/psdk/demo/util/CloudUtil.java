package com.aiyin.psdk.demo.util;

import org.apache.hc.client5.http.classic.methods.HttpPost;
import org.apache.hc.client5.http.entity.mime.MultipartEntityBuilder;
import org.apache.hc.client5.http.impl.classic.CloseableHttpClient;
import org.apache.hc.client5.http.impl.classic.HttpClients;
import org.apache.hc.core5.http.ContentType;
import org.apache.hc.core5.http.HttpEntity;
import org.apache.hc.core5.http.HttpStatus;
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
  public static void sendMessage(byte[] cmd,String deviceID) throws IOException {
      String filePath = "temp/print_cmd.bin";
      saveByteToFile(cmd, filePath);
      uploadFileToServer(filePath,deviceID);
  }

  /**
   * 上传文件到云打印服务器
   */
  public static void uploadFileToServer(String filePath,String deviceID) throws IOException {
    String url = "https://wiot.iprtapp.com/sw/files/ptFile";

    try (CloseableHttpClient httpClient = HttpClients.createDefault()) {
      HttpPost httpPost = new HttpPost(url);

      MultipartEntityBuilder builder = MultipartEntityBuilder.create();

      File file = new File(filePath);
      builder.addBinaryBody(
        "file", // 后端接收文件的字段名（对应前端的name: 'file'）
        Files.newInputStream(file.toPath()),
        ContentType.APPLICATION_OCTET_STREAM,
        file.getName()
      );

      // 添加表单参数（对应前端的formData）
      builder.addTextBody("devid", deviceID);       // 机器码
      builder.addTextBody("type", "1");       // 固定值1
      builder.addTextBody("width", "100");    // 宽度
      builder.addTextBody("height", "100");   // 高度

      HttpEntity multipart = builder.build();
      httpPost.setEntity(multipart);

      // 执行请求
      httpClient.execute(httpPost, response -> {
        final int statusCode = response.getCode();
        final String responseBody = EntityUtils.toString(response.getEntity());

        if (statusCode == HttpStatus.SC_OK) {
          System.out.println("上传成功，响应: " + responseBody);
          return true;
        } else {
          throw new IOException("上传失败，状态码: " + statusCode + "，响应: " + responseBody);
        }
      });
    }
  }

}
