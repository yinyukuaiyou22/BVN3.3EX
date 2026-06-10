package com.bvn.filereader;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.adobe.fre.FREByteArray;
import com.adobe.fre.FREInvalidObjectException;
import com.adobe.fre.FREWrongThreadException;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;

public class ReadBytesFunction implements FREFunction {

    @Override
    public FREObject call(FREContext ctx, FREObject[] args) {
        if (args.length < 1) return null;
        try {
            String path = args[0].getAsString();
            File file = new File(path);
            if (!file.exists() || !file.isFile()) return null;

            FREByteArray freBA = FREByteArray.newByteArray();
            freBA.acquire();
            ByteBuffer buf = freBA.getBytes();
            byte[] data = new byte[(int) file.length()];
            FileInputStream fis = new FileInputStream(file);
            fis.read(data);
            fis.close();
            buf.put(data);
            freBA.release();
            return freBA;
        } catch (Exception e) {
            return null;
        }
    }
}
