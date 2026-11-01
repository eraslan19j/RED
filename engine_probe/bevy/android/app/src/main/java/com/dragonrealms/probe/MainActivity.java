package com.dragonrealms.probe;

import android.os.Bundle;
import androidx.core.view.WindowCompat;
import com.google.androidgamesdk.GameActivity;

/**
 * Rust cdylib'ini (libdragon_realms_probe.so) jniLibs uzerinden yukler.
 * GameActivity, Bevy'nin `android-game-activity` ozelligi ile bekledigi giris noktidir.
 */
public class MainActivity extends GameActivity {
    static {
        System.loadLibrary("dragon_realms_probe");
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        WindowCompat.enableEdgeToEdge(getWindow());
    }
}
