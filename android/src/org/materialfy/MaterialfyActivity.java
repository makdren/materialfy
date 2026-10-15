// Главная активность: QtActivity + edge-to-edge, разрешение на уведомления (Android 13+).
package org.materialfy;

import android.Manifest;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.view.Window;

import org.qtproject.qt.android.bindings.QtActivity;

public class MaterialfyActivity extends QtActivity
{
    private static final int REQUEST_NOTIFICATIONS = 4101;

    @Override
    public void onCreate(Bundle savedInstanceState)
    {
        super.onCreate(savedInstanceState);
        Window window = getWindow();
        // Интерфейс рисуется под системными панелями (отступы — SafeArea в QML)
        window.setStatusBarColor(Color.TRANSPARENT);
        window.setNavigationBarColor(Color.TRANSPARENT);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            window.setNavigationBarContrastEnforced(false);
            window.setStatusBarContrastEnforced(false);
        }
        MobileBridge.attach(this);
        // Без разрешения уведомление плеера (и кнопки на экране блокировки) не показывается
        if (Build.VERSION.SDK_INT >= 33
            && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[] { Manifest.permission.POST_NOTIFICATIONS }, REQUEST_NOTIFICATIONS);
        }
    }

    @Override
    protected void onDestroy()
    {
        // Активность закрыта, а процесс живёт (музыка играет в сервисе) — ссылку отпускаем
        MobileBridge.detach(this);
        super.onDestroy();
    }
}
