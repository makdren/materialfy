// Главная активность: QtActivity + edge-to-edge, разрешение на уведомления (Android 13+), «Назад» системы → QML.
package org.materialfy;

import android.Manifest;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.os.Build;
import android.os.Bundle;
import android.view.KeyEvent;
import android.view.Window;
import android.window.OnBackInvokedCallback;
import android.window.OnBackInvokedDispatcher;

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
        // Android 13+: «Назад» (кнопка и жест) приходит только сюда — приложениям с targetSdk 36 система больше
        // не шлёт KEYCODE_BACK, и до Qt он не доходит. Решает QML (MobileMain.goBack): меню, плеер, стек, свернуть.
        if (Build.VERSION.SDK_INT >= 33) {
            OnBackInvokedCallback callback = MaterialfyActivity::sendBack;
            backCallback = callback;
            getOnBackInvokedDispatcher().registerOnBackInvokedCallback(OnBackInvokedDispatcher.PRIORITY_DEFAULT,
                                                                       callback);
        }
        // Без разрешения уведомление плеера (и кнопки на экране блокировки) не показывается
        if (Build.VERSION.SDK_INT >= 33
            && checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
            requestPermissions(new String[] { Manifest.permission.POST_NOTIFICATIONS }, REQUEST_NOTIFICATIONS);
        }
    }

    private Object backCallback;

    private static void sendBack()
    {
        try {
            MobileBridge.onMediaCommand("back", 0);
        } catch (UnsatisfiedLinkError e) {
            // нативная часть ещё не загружена — нажатие теряется, как и раньше
        }
    }

    // Android 12 и старше: клавиша «Назад» — тоже в QML, а не в обработчик QtActivity (тот закрыл бы окно)
    @Override
    public boolean dispatchKeyEvent(KeyEvent event)
    {
        if (event.getKeyCode() == KeyEvent.KEYCODE_BACK) {
            if (event.getAction() == KeyEvent.ACTION_UP && !event.isCanceled())
                sendBack();
            return true;
        }
        return super.dispatchKeyEvent(event);
    }

    @Override
    protected void onDestroy()
    {
        if (Build.VERSION.SDK_INT >= 33 && backCallback != null)
            getOnBackInvokedDispatcher().unregisterOnBackInvokedCallback((OnBackInvokedCallback) backCallback);
        // Активность закрыта, а процесс живёт (музыка играет в сервисе) — ссылку отпускаем
        MobileBridge.detach(this);
        super.onDestroy();
    }
}
