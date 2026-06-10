package com.bvn.filereader;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREFunction;
import java.util.HashMap;
import java.util.Map;

public class ANEFileReaderContext extends FREContext {

    @Override
    public Map<String, FREFunction> getFunctions() {
        Map<String, FREFunction> functions = new HashMap<>();
        functions.put("readBytes", new ReadBytesFunction());
        functions.put("listDir", new ListDirFunction());
        functions.put("exists", new ExistsFunction());
        return functions;
    }

    @Override
    public void dispose() {}
}
