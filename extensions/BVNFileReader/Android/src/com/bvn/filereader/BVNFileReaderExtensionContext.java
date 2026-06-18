package com.bvn.filereader;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.adobe.fre.FREByteArray;
import com.adobe.fre.FREArray;
import com.adobe.fre.FREWrongThreadException;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.Map;
import java.util.HashMap;

public class BVNFileReaderExtensionContext extends FREContext
{
    private static final String TAG = "BVNFileReader";

    @Override
    public Map<String, FREFunction> getFunctions()
    {
        Map<String, FREFunction> functions = new HashMap<>();
        functions.put("readBytes",         new ReadBytesFunction());
        functions.put("listDir",           new ListDirFunction());
        functions.put("exists",            new ExistsFunction());
        functions.put("createDirectory",   new CreateDirectoryFunction());
        functions.put("writeBytes",        new WriteBytesFunction());
        functions.put("deleteFile",        new DeleteFileFunction());
        functions.put("getFileState",      new GetFileStateFunction());
        functions.put("getExternalFilesDir",new GetExternalFilesDirFunction());
        functions.put("registerProvider",  new RegisterProviderFunction());
        return functions;
    }

    @Override
    public void dispose() {}

    // ===================================================================
    // readBytes(path) : ByteArray
    // Fixed: set length before acquire() per anetoolkit best practice.
    // ===================================================================
    private class ReadBytesFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                String path = args[0].getAsString();
                File file = new File(path);
                if(!file.exists() || !file.isFile())
                {
                    Log.w(TAG, "readBytes: file not found " + path);
                    return null;
                }
                FileInputStream fis = new FileInputStream(file);
                byte[] bytes = new byte[(int)file.length()];
                int total = 0;
                while(total < bytes.length)
                {
                    int n = fis.read(bytes, total, bytes.length - total);
                    if(n < 0) break;
                    total += n;
                }
                fis.close();

                FREByteArray ba = FREByteArray.newByteArray();
                ba.setProperty("length", FREObject.newObject(bytes.length));
                ba.acquire();
                ByteBuffer buf = ba.getBytes();
                buf.put(bytes);
                ba.release();

                Log.d(TAG, "readBytes: " + path + " ->" + bytes.length + " bytes");
                return ba;
            }
            catch(Exception e)
            {
                Log.e(TAG, "readBytes error", e);
            }
            return null;
        }
    }

    // ===================================================================
    // listDir(path) : Array<String>
    // ===================================================================
    private class ListDirFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                String path = args[0].getAsString();
                File dir = new File(path);
                if(!dir.exists() || !dir.isDirectory())
                {
                    Log.w(TAG, "listDir: not found or not dir " + path);
                    return null;
                }
                String[] files = dir.list();
                if(files == null) return null;

                FREArray arr = FREArray.newArray(files.length);
                for(int i = 0; i < files.length; i++)
                {
                    arr.setObjectAt(i, FREObject.newObject(files[i]));
                }
                Log.d(TAG, "listDir: " + path + " ->" + files.length + " entries");
                return arr;
            }
            catch(Exception e)
            {
                Log.e(TAG, "listDir error", e);
            }
            return null;
        }
    }

    // ===================================================================
    // exists(path) : Boolean
    // ===================================================================
    private class ExistsFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                String path = args[0].getAsString();
                boolean b = new File(path).exists();
                Log.d(TAG, "exists: " + path + " = " + b);
                return FREObject.newObject(b);
            }
            catch(Exception e)
            {
                Log.e(TAG, "exists error", e);
            }
            return null;
        }
    }

    // ===================================================================
    // createDirectory(path) : Boolean
    // ===================================================================
    private class CreateDirectoryFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                String path = args[0].getAsString();
                File dir = new File(path);
                boolean ok = dir.exists() || dir.mkdirs();
                Log.d(TAG, "createDirectory: " + path + " = " + ok);
                return FREObject.newObject(ok);
            }
            catch(Exception e)
            {
                Log.e(TAG, "createDirectory error", e);
                try { return FREObject.newObject(false); }
                catch(FREWrongThreadException ex) { return null; }
            }
        }
    }

    // ===================================================================
    // writeBytes(path, ByteArray, append) : Boolean
    // Source: anetoolkit WriteFile.java
    // ===================================================================
    private class WriteBytesFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                String path = args[0].getAsString();
                boolean append = args.length > 2 && args[2].getAsBool();
                FREByteArray freBA = (FREByteArray)args[1];
                freBA.acquire();
                ByteBuffer bb = freBA.getBytes();
                byte[] bytes = new byte[(int)freBA.getLength()];
                bb.get(bytes);
                freBA.release();

                FileOutputStream fos = new FileOutputStream(path, append);
                fos.write(bytes);
                fos.close();

                Log.d(TAG, "writeBytes: " + path + " ->" + bytes.length + " bytes, append=" + append);
                return FREObject.newObject(true);
            }
            catch(Exception e)
            {
                Log.e(TAG, "writeBytes error", e);
                try { return FREObject.newObject(false); }
                catch(FREWrongThreadException ex) { return null; }
            }
        }
    }

    // ===================================================================
    // deleteFile(path) : Boolean
    // Source: anetoolkit DelFile.java
    // ===================================================================
    private class DeleteFileFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                String path = args[0].getAsString();
                File file = new File(path);
                boolean ok = file.delete();
                Log.d(TAG, "deleteFile: " + path + " = " + ok);
                return FREObject.newObject(ok);
            }
            catch(Exception e)
            {
                Log.e(TAG, "deleteFile error", e);
                try { return FREObject.newObject(false); }
                catch(FREWrongThreadException ex) { return null; }
            }
        }
    }

    // ===================================================================
    // getFileState(path) : Object {exists, isDirectory, isFile}
    // Source: anetoolkit GetFileState.java
    // ===================================================================
    private class GetFileStateFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                String path = args[0].getAsString();
                File file = new File(path);
                FREObject obj = FREObject.newObject("Object", null);
                obj.setProperty("exists", FREObject.newObject(file.exists()));
                obj.setProperty("isDirectory", FREObject.newObject(file.isDirectory()));
                obj.setProperty("isFile", FREObject.newObject(file.isFile()));
                Log.d(TAG, "getFileState: " + path + " ->e=" + file.exists() + " d=" + file.isDirectory() + " f=" + file.isFile());
                return obj;
            }
            catch(Exception e)
            {
                Log.e(TAG, "getFileState error", e);
            }
            return null;
        }
    }

    // ===================================================================
    // getExternalFilesDir(subPath) : String
    // Returns Android's getExternalFilesDir(null) + optional subPath.
    // E.g., subPath="" ->"/storage/emulated/0/Android/data/<pkg>/files/"
    // ===================================================================
    private class GetExternalFilesDirFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                File dir = ctx.getActivity().getExternalFilesDir(null);
                if(dir == null)
                {
                    Log.w(TAG, "getExternalFilesDir: null (no external storage)");
                    return null;
                }
                // Return the parent (app's external data root), not files/ itself.
                // Caller appends subdirectory like "BVN/assets/"
                String result = dir.getParentFile().getAbsolutePath() + "/";
                Log.d(TAG, "getExternalFilesDir: " + result);
                return FREObject.newObject(result);
            }
            catch(Exception e)
            {
                Log.e(TAG, "getExternalFilesDir error", e);
            }
            return null;
        }
    }

    // ===================================================================
    // registerProvider() : Boolean
    // ===================================================================
    private class RegisterProviderFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                final android.app.Activity activity = ctx.getActivity();
                final Intent intent = new Intent(activity, BVNDataFilesWakeUpActivity.class);
                new Handler(Looper.getMainLooper()).post(new Runnable() {
                    @Override
                    public void run() {
                        activity.startActivity(intent);
                    }
                });
                Log.d(TAG, "registerProvider: posted wake-up activity");
                return FREObject.newObject(true);
            }
            catch(Exception e)
            {
                Log.e(TAG, "registerProvider error", e);
                try { return FREObject.newObject(false); }
                catch(FREWrongThreadException ex) { return null; }
            }
        }
    }
}
