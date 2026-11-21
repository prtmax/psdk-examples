package com.printer.demo.utils;

public class ImageScaleUtils {

    // 缩放模式枚举
    public enum ScaleMode {
        CENTER,           // 居中，不缩放
        CENTER_CROP,      // 填充并裁剪
        CENTER_INSIDE,    // 完整显示，可能留白
        FIT_XY,           // 拉伸填充，可能变形
        START_CROP,       // 从左上角开始裁剪 (示例，可扩展其他角落)
    }

    /**
     * 计算图像在指定画布中适应不同模式的缩放参数
     *
     * @param bitmapWidth  原图宽度
     * @param bitmapHeight 原图高度
     * @param canvasWidth  画布宽度
     * @param canvasHeight 画布高度
     * @param scaleMode    缩放模式
     * @return 包含缩放后位置(x, y)和尺寸(width, height)的对象
     */
    public static ScaleResult calculateScale(
            float bitmapWidth, float bitmapHeight,
            float canvasWidth, float canvasHeight,
            ScaleMode scaleMode) {

        ScaleResult result = new ScaleResult();

        switch (scaleMode) {
            case CENTER:
                // 不缩放，直接居中
                result.scale = 1.0f;
                result.scaledWidth = bitmapWidth;
                result.scaledHeight = bitmapHeight;
                result.x = (canvasWidth - bitmapWidth) / 2.0f;
                result.y = (canvasHeight - bitmapHeight) / 2.0f;


                break;

            case CENTER_CROP: // 应用 CardCanvas 的自适应缩放逻辑
                // 边界检查，防止除以零
                if (bitmapWidth <= 0 || bitmapHeight <= 0 || canvasWidth <= 0 || canvasHeight <= 0) {
                    result.scale = 1.0f;
                    result.scaledWidth = bitmapWidth;
                    result.scaledHeight = bitmapHeight;
                    result.x = (canvasWidth - bitmapWidth) / 2.0f;
                    result.y = (canvasHeight - bitmapHeight) / 2.0f;
                    break;
                }
                // 计算宽度和高度方向的缩放比例
                float scaleX = canvasWidth / bitmapWidth;
                float scaleY = canvasHeight / bitmapHeight;
                // 取较大值，确保图片填满目标区域（cover模式）
                float scaleCrop = Math.max(scaleX, scaleY);
                result.scale = scaleCrop;
                result.scaledWidth = bitmapWidth * scaleCrop;
                result.scaledHeight = bitmapHeight * scaleCrop;
                // 计算居中偏移（使图片在目标区域内居中）
                result.x = (canvasWidth - result.scaledWidth) / 2.0f;
                result.y = (canvasHeight - result.scaledHeight) / 2.0f;
                break;


            case CENTER_INSIDE: // 完整显示，留白
                float scaleInside = Math.min(canvasWidth / bitmapWidth, canvasHeight / bitmapHeight);
                scaleInside = Math.min(scaleInside, 1.0f); // 可选：只缩小不放大
                result.scale = scaleInside;
                result.scaledWidth = bitmapWidth * scaleInside;
                result.scaledHeight = bitmapHeight * scaleInside;
                result.x = (canvasWidth - result.scaledWidth) / 2.0f;
                result.y = (canvasHeight - result.scaledHeight) / 2.0f;
                break;



            case FIT_XY: // 拉伸变形
                result.scale = 1.0f; // 比例已改变，scale意义不大
                result.scaledWidth = canvasWidth;
                result.scaledHeight = canvasHeight;
                result.x = 0.0f;
                result.y = 0.0f;
                break;

            case START_CROP: // 示例：从左上角开始裁剪，不平移
                float scaleStart = Math.max(canvasWidth / bitmapWidth, canvasHeight / bitmapHeight);
                result.scale = scaleStart;
                result.scaledWidth = bitmapWidth * scaleStart;
                result.scaledHeight = bitmapHeight * scaleStart;
                result.x = 0.0f; // 从左上角(0,0)开始
                result.y = 0.0f;
                break;

            default:
                // 默认使用 CENTER_CROP
                return calculateScale(bitmapWidth, bitmapHeight, canvasWidth, canvasHeight, ScaleMode.CENTER_CROP);
        }
        return result;
    }

    // 定义一个内部类来承载计算结果
    public static class ScaleResult {
        public float x;
        public float y;
        public float scaledWidth;
        public float scaledHeight;
        public float scale;
    }
}
