package com.bvn.filereader;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;

public class ANEFileReaderExtension implements FREExtension {

    @Override
    public FREContext createContext(String type) {
        return new ANEFileReaderContext();
    }

    @Override
    public void initialize() {}

    @Override
    public void dispose() {}
}
