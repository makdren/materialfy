// Медиабраузер: показывает системе медиасессию плеера (PlaybackService). Каталога нет — список пуст; нужен,
// чтобы система и оболочки (OriginOS, HyperOS) считали приложение музыкальным и выводили карточку плеера.
// Пока ничего не играет, сессии нет — браузер отказывает (и система не предлагает «продолжить» с экрана блокировки).
package org.materialfy;

import android.media.browse.MediaBrowser.MediaItem;
import android.media.session.MediaSession;
import android.os.Bundle;
import android.service.media.MediaBrowserService;

import java.util.ArrayList;
import java.util.List;

public class MediaBrowser extends MediaBrowserService
{
    private static final String ROOT = "materialfy";

    @Override
    public void onCreate()
    {
        super.onCreate();
        attach();
    }

    private boolean attach()
    {
        if (getSessionToken() != null)
            return true;
        MediaSession.Token token = PlaybackService.sessionToken();
        if (token == null)
            return false;
        setSessionToken(token);
        return true;
    }

    @Override
    public BrowserRoot onGetRoot(String clientPackageName, int clientUid, Bundle rootHints)
    {
        return attach() ? new BrowserRoot(ROOT, null) : null;
    }

    @Override
    public void onLoadChildren(String parentId, Result<List<MediaItem>> result)
    {
        result.sendResult(new ArrayList<>());
    }
}
