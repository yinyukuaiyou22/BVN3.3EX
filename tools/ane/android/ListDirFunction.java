package com.bvn.filereader;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.adobe.fre.FREArray;
import java.io.File;

public class ListDirFunction implements FREFunction {

    @Override
    public FREObject call(FREContext ctx, FREObject[] args) {
        if (args.length < 1) return null;
        try {
            String path = args[0].getAsString();
            File dir = new File(path);
            if (!dir.exists() || !dir.isDirectory()) return null;

            String[] files = dir.list();
            if (files == null) return null;

            FREArray arr = FREArray.newArray(files.length);
            for (int i = 0; i < files.length; i++) {
                arr.setObjectAt(i, FREObject.newObject(files[i]));
            }
            return arr;
        } catch (Exception e) {
            return null;
        }
    }
}
