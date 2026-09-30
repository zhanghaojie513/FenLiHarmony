import { reminderAgentManager } from '@kit.BackgroundTasksKit';
import { notificationManager } from '@kit.NotificationKit';
import { FenLiReminderSettings } from '../model/FenLiModels';

export enum FenLiReminderState {
  READY = 'ready',
  DISABLED = 'disabled',
  CAPABILITY_UNAVAILABLE = 'capability_unavailable',
  PERMISSION_REQUIRED = 'permission_required',
  FAILED = 'failed'
}

export interface FenLiReminderStatus {
  state: FenLiReminderState;
  reminderId: number;
  message: string;
}

function status(state: FenLiReminderState, reminderId: number, message: string): FenLiReminderStatus {
  return { state, reminderId, message };
}

export class FenLiReminder {
  public static capabilityAvailable(): boolean {
    return canIUse('SystemCapability.Notification.ReminderAgent');
  }

  public static async requestNotificationPermission(): Promise<FenLiReminderStatus> {
    if (!FenLiReminder.capabilityAvailable()) {
      return status(FenLiReminderState.CAPABILITY_UNAVAILABLE, -1, '系统不支持后台代理提醒能力');
    }
    try {
      await notificationManager.requestEnableNotification();
      return status(FenLiReminderState.PERMISSION_REQUIRED, -1, '已发起通知授权请求，请以系统设置中的实际状态为准');
    } catch (error) {
      return status(FenLiReminderState.PERMISSION_REQUIRED, -1, '通知权限请求失败，请在系统设置中允许通知');
    }
  }

  public static async scheduleDaily(settings: FenLiReminderSettings): Promise<FenLiReminderStatus> {
    if (!settings.enabled) {
      return status(FenLiReminderState.DISABLED, -1, '账本提醒已关闭');
    }
    if (!FenLiReminder.capabilityAvailable()) {
      return status(FenLiReminderState.CAPABILITY_UNAVAILABLE, -1, '系统不支持后台代理提醒能力');
    }
    if (settings.hour < 0 || settings.hour > 23 || settings.minute < 0 || settings.minute > 59) {
      return status(FenLiReminderState.FAILED, -1, '提醒时间无效');
    }
    const request: reminderAgentManager.ReminderRequestAlarm = {
      reminderType: reminderAgentManager.ReminderType.REMINDER_TYPE_ALARM,
      hour: settings.hour,
      minute: settings.minute,
      title: '分厘记账提醒',
      content: settings.message
    };
    try {
      const reminderId: number = await reminderAgentManager.publishReminder(request);
      return status(FenLiReminderState.READY, reminderId, '后台代理提醒已由系统接受');
    } catch (error) {
      return status(FenLiReminderState.FAILED, -1, '后台代理提醒未发布，请确认通知和代理提醒权限');
    }
  }

  public static async cancel(reminderId: number): Promise<FenLiReminderStatus> {
    if (!FenLiReminder.capabilityAvailable()) {
      return status(FenLiReminderState.CAPABILITY_UNAVAILABLE, reminderId, '系统不支持后台代理提醒能力');
    }
    try {
      await reminderAgentManager.cancelReminder(reminderId);
      return status(FenLiReminderState.READY, reminderId, '后台代理提醒已取消');
    } catch (error) {
      return status(FenLiReminderState.FAILED, reminderId, '后台代理提醒取消失败');
    }
  }
}
