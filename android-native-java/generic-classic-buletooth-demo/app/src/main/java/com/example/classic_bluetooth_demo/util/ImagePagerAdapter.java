package com.example.classic_bluetooth_demo.util;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.Matrix;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import androidx.viewpager.widget.PagerAdapter;

public class ImagePagerAdapter extends PagerAdapter {

  private final Bitmap[] images;
  private final Context context;

  public ImagePagerAdapter(Context context, Bitmap[] images) {
    this.context = context;
    this.images = images;
  }

  @Override
  public int getCount() {
    return images.length;
  }

  @Override
  public boolean isViewFromObject(View view, Object object) {
    return view == object;
  }

  @Override
  public Object instantiateItem(ViewGroup container, int position) {
    ImageView imageView = new ImageView(this.context);
    Bitmap bitmap = images[position];
    //检查是否需要压缩
    int width = bitmap.getWidth();
    int height = bitmap.getHeight();
    int inSampleSize = 1;
    int max = 100 * 1024 * 1024;
    while (width * height * 4 / inSampleSize > max) {
      inSampleSize *= 2;
    }
    if (inSampleSize > 1) {
      Matrix m2 = new Matrix();
      m2.setScale(1 / (float) inSampleSize, 1 / (float) inSampleSize);
      bitmap = Bitmap.createBitmap(bitmap, 0, 0, width, height, m2, false);
    }
    imageView.setImageBitmap(bitmap);
    container.addView(imageView);
    return imageView;
  }

  @Override
  public void destroyItem(ViewGroup container, int position, Object object) {
    container.removeView((View) object);
  }
}
