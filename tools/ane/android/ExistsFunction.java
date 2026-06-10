package com.bvn.filereader;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import com.adobe.fre.FREObject;
import com.adobe.fre.FREBoolean;
import java.io.File;

public class ExistsFunction implements FREFunction {

    @Override
    public FREObject call(FREContext ctx, FREObject[] args) {
        if (args.length < 1) return FREBoolean.newBoolean(false);
        try {
            String path = args[0].getAsString();
            return FREBoolean.newBoolean(new File(path).exists());
        } catch (Exception e) {
            return FREBoolean.newBoolean(false);
        }
    }
}
