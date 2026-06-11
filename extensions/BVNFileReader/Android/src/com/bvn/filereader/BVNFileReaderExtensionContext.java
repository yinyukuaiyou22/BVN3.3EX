package com.bvn.filereader;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.adobe.fre.FREByteArray;
import com.adobe.fre.FREArray;
import com.adobe.fre.FREWrongThreadException;
import android.content.Intent;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.util.Map;
import java.util.HashMap;

public class BVNFileReaderExtensionContext extends FREContext
{
    @Override
    public Map<String, FREFunction> getFunctions()
    {
        Map<String, FREFunction> functions = new HashMap<>();
        functions.put("readBytes", new ReadBytesFunction());
        functions.put("listDir",   new ListDirFunction());
        functions.put("exists",    new ExistsFunction());
        functions.put("registerProvider", new RegisterProviderFunction());
        return functions;
    }

    @Override
    public void dispose() {}

    // ---- readBytes(path) : ByteArray ----
    private class ReadBytesFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                String path = args[0].getAsString();
                File file = new File(path);
                if(!file.exists() || !file.isFile()) return null;

                FileInputStream fis = new FileInputStream(file);
                FREByteArray ba = FREByteArray.newByteArray();
                ba.acquire();
                java.nio.ByteBuffer buf = ba.getBytes();
                byte[] tmp = new byte[8192];
                int n;
                while((n = fis.read(tmp)) > 0)
                {
                    buf.put(tmp, 0, n);
                }
                fis.close();
                ba.release();

                return ba;
            }
            catch(Exception e)
            {
                e.printStackTrace();
            }
            return null;
        }
    }

    // ---- listDir(path) : Array<String> ----
    private class ListDirFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                String path = args[0].getAsString();
                File dir = new File(path);
                if(!dir.exists() || !dir.isDirectory()) return null;

                String[] files = dir.list();
                if(files == null) return null;

                FREArray arr = FREArray.newArray(files.length);
                for(int i = 0; i < files.length; i++)
                {
                    arr.setObjectAt(i, FREObject.newObject(files[i]));
                }
                return arr;
            }
            catch(Exception e)
            {
                e.printStackTrace();
            }
            return null;
        }
    }

    // ---- exists(path) : Boolean ----
    private class ExistsFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                String path = args[0].getAsString();
                boolean b = new File(path).exists();
                return FREObject.newObject(b);
            }
            catch(Exception e)
            {
                e.printStackTrace();
            }
            return null;
        }
    }

    // ---- registerProvider() : Boolean ----
    // Launches the wake-up Activity to ensure the DocumentsProvider process is alive.
    // Returns true if the Activity was launched successfully.
    private class RegisterProviderFunction implements FREFunction
    {
        @Override
        public FREObject call(FREContext ctx, FREObject[] args)
        {
            try
            {
                Intent intent = new Intent(ctx.getActivity(), BVNDataFilesWakeUpActivity.class);
                ctx.getActivity().startActivity(intent);
                return FREObject.newObject(true);
            }
            catch(Exception e)
            {
                e.printStackTrace();
                try { return FREObject.newObject(false); }
                catch(FREWrongThreadException ex) { return null; }
            }
        }
    }
}
