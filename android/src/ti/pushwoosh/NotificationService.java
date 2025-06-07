package ti.pushwoosh;

import android.content.Intent;
import android.util.Log;
import com.pushwoosh.notification.NotificationServiceExtension;
import com.pushwoosh.notification.PushMessage;

import org.appcelerator.kroll.KrollDict;
import org.appcelerator.titanium.TiApplication;

public class NotificationService extends NotificationServiceExtension {

    @Override
    public boolean onMessageReceived(PushMessage data) {
        Log.d("Pushwoosh", "onMessageReceived");

        PushWooshModule module = PushWooshModule.getModuleInstance();

        if (module != null && module.hasListeners(PushWooshModule.ON_MESSAGE_RECEIVED)) {
            KrollDict dictCallback = new KrollDict();
            dictCallback.put("message", data.getMessage());
            dictCallback.put("customData", data.getCustomData());
            dictCallback.put("badges", data.getBadges());
            module.fireEvent(PushWooshModule.ON_MESSAGE_RECEIVED, dictCallback);
        }

        return false;
    }

    @Override
    public void onMessageOpened(PushMessage message) {
        Log.d("Pushwoosh", "onMessageOpened event fired.");

        if(TiApplication.isCurrentActivityInForeground()){
            // Callback para JS
            PushWooshModule module = PushWooshModule.getModuleInstance();
            if (module != null && module.hasListeners(PushWooshModule.ON_MESSAGE_OPENED)) {
                KrollDict dictCallback = new KrollDict();
                dictCallback.put("message", message.getMessage());
                dictCallback.put("customData", message.getCustomData());
                dictCallback.put("badges", message.getBadges());
                module.fireEvent(PushWooshModule.ON_MESSAGE_OPENED, dictCallback);
            }

            return;
        }

        Log.d("Pushwoosh", "Click notification in background.");
        Log.d("Pushwoosh", "Will open/restart the app.");

        // Tenta trazer ou reiniciar o app
        assert getApplicationContext() != null;
        Intent intent = getApplicationContext()
                .getPackageManager()
                .getLaunchIntentForPackage(getApplicationContext().getPackageName());

        if (intent != null) {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            // 👉 Aqui adicionamos os dados da notificação ao Intent
            intent.putExtra("ti.pushwoosh.data", message.getCustomData());
            getApplicationContext().startActivity(intent);
            android.os.Process.killProcess(android.os.Process.myPid());
        }
    }
}