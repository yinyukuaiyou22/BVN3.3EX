package com.bvn.filereader;

import android.app.Activity;
import android.os.Bundle;

/**
 * No-op Activity that immediately finishes.
 * Used to "wake up" the app process so the DocumentsProvider becomes available
 * to the system, even when the AIR render activity is not in the foreground.
 *
 * From MTDataFilesProvider (github.com/L-JINBIN/MTDataFilesProvider).
 */
public class BVNDataFilesWakeUpActivity extends Activity
{
    @Override
    protected void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        finish();
    }
}
