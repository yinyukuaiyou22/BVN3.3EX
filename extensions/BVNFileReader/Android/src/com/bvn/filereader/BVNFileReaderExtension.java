package com.bvn.filereader;

import android.util.Log;

import com.adobe.fre.FREContext;
import com.adobe.fre.FREExtension;

public class BVNFileReaderExtension implements FREExtension
{
    private static final String TAG = "BVNFileReader";

    public void initialize()
    {
        Log.e(TAG, "initialize() called");
    }

    public FREContext createContext(String extId)
    {
        Log.e(TAG, "createContext() called extId=" + extId);
        return new BVNFileReaderExtensionContext();
    }

    public void dispose()
    {
        Log.e(TAG, "dispose() called");
    }
}
