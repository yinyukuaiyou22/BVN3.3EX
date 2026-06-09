package com.bvn.filereader;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;

public class BVNFileReaderExtension implements FREExtension
{
    public void initialize() {}

    public FREContext createContext(String extId)
    {
        return new BVNFileReaderExtensionContext();
    }

    public void dispose() {}
}
