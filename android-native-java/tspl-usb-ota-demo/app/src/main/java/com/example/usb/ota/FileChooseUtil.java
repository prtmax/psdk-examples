package com.example.usb.ota;

import android.content.ContentResolver;
import android.content.ContentUris;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.os.FileUtils;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.provider.OpenableColumns;
import android.webkit.MimeTypeMap;

import java.io.*;

public class FileChooseUtil {
    /**
     * 根据Uri获取文件绝对路径，解决Android4.4以上版本Uri转换 兼容Android 10
     *
     * @param context
     * @param imageUri
     */
    public static String getFileAbsolutePath(Context context, Uri imageUri) {
        if (context == null || imageUri == null) {
            return null;
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT) {
            return getRealFilePath(context, imageUri);
        }

        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.Q && DocumentsContract.isDocumentUri(context, imageUri)) {
            if (isExternalStorageDocument(imageUri)) {
                String docId = DocumentsContract.getDocumentId(imageUri);
                String[] split = docId.split(":");
                String type = split[0];
                if ("primary".equalsIgnoreCase(type)) {
                    return Environment.getExternalStorageDirectory() + "/" + split[1];
                }
            } else if (isDownloadsDocument(imageUri)) {
                String id = DocumentsContract.getDocumentId(imageUri);
                Uri contentUri = ContentUris.withAppendedId(Uri.parse("content://downloads/public_downloads"), Long.valueOf(id));
                return getDataColumn(context, contentUri, null, null);
            } else if (isMediaDocument(imageUri)) {
                String docId = DocumentsContract.getDocumentId(imageUri);
                String[] split = docId.split(":");
                String type = split[0];
                Uri contentUri = null;
                if ("image".equals(type)) {
                    contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
                } else if ("video".equals(type)) {
                    contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
                } else if ("audio".equals(type)) {
                    contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
                }
                String selection = MediaStore.Images.Media._ID + "=?";
                String[] selectionArgs = new String[]{split[1]};
                return getDataColumn(context, contentUri, selection, selectionArgs);
            }
        }
        // MediaStore (and general)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q){
            return uriToFileApiQ(context,imageUri);
        }
        else if ("content".equalsIgnoreCase(imageUri.getScheme())) {
            // Return the remote address
            if (isGooglePhotosUri(imageUri)) {
                return imageUri.getLastPathSegment();
            }
            return getDataColumn(context, imageUri, null, null);
        }
        // File
        else if ("file".equalsIgnoreCase(imageUri.getScheme())) {
            return imageUri.getPath();
        }
        return null;
    }

    //此方法 只能用于4.4以下的版本
    private static String getRealFilePath(final Context context, final Uri uri) {
        if (null == uri) {
            return null;
        }
        final String scheme = uri.getScheme();
        String data = null;
        if (scheme == null) {
            data = uri.getPath();
        } else if (ContentResolver.SCHEME_FILE.equals(scheme)) {
            data = uri.getPath();
        } else if (ContentResolver.SCHEME_CONTENT.equals(scheme)) {
            String[] projection = {MediaStore.Images.ImageColumns.DATA};
            Cursor cursor = context.getContentResolver().query(uri, projection, null, null, null);

//            Cursor cursor = context.getContentResolver().query(uri, new String[]{MediaStore.Images.ImageColumns.DATA}, null, null, null);
            if (null != cursor) {
                if (cursor.moveToFirst()) {
                    int index = cursor.getColumnIndex(MediaStore.Images.ImageColumns.DATA);
                    if (index > -1) {
                        data = cursor.getString(index);
                    }
                }
                cursor.close();
            }
        }
        return data;
    }


    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is ExternalStorageProvider.
     */
    private static boolean isExternalStorageDocument(Uri uri) {
        return "com.android.externalstorage.documents".equals(uri.getAuthority());
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is DownloadsProvider.
     */
    private static boolean isDownloadsDocument(Uri uri) {
        return "com.android.providers.downloads.documents".equals(uri.getAuthority());
    }

    private static String getDataColumn(Context context, Uri uri, String selection, String[] selectionArgs) {
        Cursor cursor = null;
        String column = MediaStore.Images.Media.DATA;
        String[] projection = {column};
        try {
            cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs, null);
            if (cursor != null && cursor.moveToFirst()) {
                int index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(index);
            }
        } finally {
            if (cursor != null) {
                cursor.close();
            }
        }
        return null;
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is MediaProvider.
     */
    private static boolean isMediaDocument(Uri uri) {
        return "com.android.providers.media.documents".equals(uri.getAuthority());
    }

    /**
     * @param uri The Uri to check.
     * @return Whether the Uri authority is Google Photos.
     */
    private static boolean isGooglePhotosUri(Uri uri) {
        return "com.google.android.apps.photos.content".equals(uri.getAuthority());
    }


    /**
     * Android 10 以上适配 另一种写法
     * @param context
     * @param uri
     * @return
     */
    public static String getFileFromContentUri(Context context, Uri uri) {
        if (uri == null) {
            return null;
        }
        String filePath;
        String[] filePathColumn = {MediaStore.MediaColumns.DATA, MediaStore.MediaColumns.DISPLAY_NAME};
        ContentResolver contentResolver = context.getContentResolver();
        Cursor cursor = contentResolver.query(uri, filePathColumn, null,
                null, null);
        if (cursor != null) {
            cursor.moveToFirst();
            try {
                filePath = cursor.getString(cursor.getColumnIndex(filePathColumn[0]));
                return filePath;
            } catch (Exception e) {
            } finally {
                cursor.close();
            }
        }
        return "";
    }

    /**
     * Android 10 以上适配
     * @param context
     * @param uri
     * @return
     */
    public static String uriToFileApiQ(Context context, Uri uri) {
        File file = null;
        //android10以上转换
        if (uri.getScheme().equals(ContentResolver.SCHEME_FILE)) {
            file = new File(uri.getPath());
        } else if (uri.getScheme().equals(ContentResolver.SCHEME_CONTENT)) {
            //把文件复制到沙盒目录
            ContentResolver contentResolver = context.getContentResolver();
            Cursor cursor = contentResolver.query(uri, null, null, null, null);
            if (cursor.moveToFirst()) {
                String displayName = cursor.getString(cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME));
                try {
                    InputStream is = contentResolver.openInputStream(uri);
                    File cache = new File(context.getExternalCacheDir().getAbsolutePath(), Math.round((Math.random() + 1) * 1000) + displayName);
                    FileOutputStream fos = new FileOutputStream(cache);
                  if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    FileUtils.copy(is, fos);
                  }
                  file = cache;
                    fos.close();
                    is.close();
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
        return file.getAbsolutePath();
    }


    /**
     * 通过文件路径 uri的转字符也可以
     * @param filePath
     * @return
     */
    public static String getMimeType(String filePath) {
        String ext = MimeTypeMap.getFileExtensionFromUrl(filePath);
        return MimeTypeMap.getSingleton().getMimeTypeFromExtension(ext);
    }
    public static byte[] File2Bytes(File file) {
        int byte_size = 1024;
        byte[] b = new byte[byte_size];
        try {
            FileInputStream fileInputStream = new FileInputStream(file);
            ByteArrayOutputStream outputStream = new ByteArrayOutputStream(
                    byte_size);
            for (int length; (length = fileInputStream.read(b)) != -1;) {
                outputStream.write(b, 0, length);
            }
            fileInputStream.close();
            outputStream.close();
            return outputStream.toByteArray();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return null;
    }
    public static byte[] readFiledata(String fileName) {
//        if (fileName.contains("PRTU") || fileName.contains("prtu")) {
        int byteread = 0;
        File file = new File(fileName);
        InputStream in = null;
        byte[] tempbytes = new byte[(int) file.length()];
        byte[] filedata = new byte[(int) file.length()];
        int bytesNumber = 0;
        try {
            in = new FileInputStream(fileName);
            //读入多个字节到字节数组中，byteread为一次读入的字节数
            while ((byteread = in.read(tempbytes)) != -1) {
                System.arraycopy(tempbytes, 0, filedata, bytesNumber, tempbytes.length);
                bytesNumber += byteread;
            }
        } catch (Exception e1) {
            e1.printStackTrace();
            return null;
        } finally {
            if (in != null) {
                try {
                    in.close();
                } catch (IOException e1) {
                    e1.printStackTrace();
                    return null;
                }
            }
        }

        return filedata;
//            if (fileName.contains("prtu") || fileName.contains("PRTU")) {
//                return filedata;
//            }
//        } else {
//            return null;
//        }
    }
}
