import { preferences } from '@kit.ArkData';
import {
  createFenLiDemoData,
  FenLiBudgetSettings,
  FenLiCategory,
  FenLiLedger,
  FenLiReminderSettings,
  FenLiStoreData,
  FenLiTransaction
} from '../model/FenLiModels';

const STORE_NAME: string = 'fenli_store';
const STORE_KEY: string = 'store_data';
const FORMAT_VERSION: string = 'fenli-v1';

function encodeField(value: string): string {
  return encodeURIComponent(value);
}

function decodeField(value: string): string {
  return decodeURIComponent(value);
}

function numberOrDefault(value: string, fallback: number): number {
  const parsed: number = Number(value);
  if (Number.isFinite(parsed)) {
    return parsed;
  }
  return fallback;
}

function booleanToText(value: boolean): string {
  return value ? '1' : '0';
}

function textToBoolean(value: string, fallback: boolean): boolean {
  if (value === '1') {
    return true;
  }
  if (value === '0') {
    return false;
  }
  return fallback;
}

function encodeLedger(item: FenLiLedger): string {
  return [item.id, item.name, item.currencyCode, item.createdAt].map((value: string): string => encodeField(value)).join('|');
}

function encodeCategory(item: FenLiCategory): string {
  return [item.id, item.name, item.iconName, item.colorHex].map((value: string): string => encodeField(value)).join('|');
}

function encodeTransaction(item: FenLiTransaction): string {
  return [item.id, item.ledgerId, item.categoryId, String(item.amountCents), item.note, item.occurredOn, item.createdAt]
    .map((value: string): string => encodeField(value)).join('|');
}

function fieldsOf(line: string): string[] {
  return line.split('|').map((value: string): string => decodeField(value));
}

function parseLedger(line: string): FenLiLedger | null {
  const fields: string[] = fieldsOf(line);
  if (fields.length !== 4) {
    return null;
  }
  return { id: fields[0], name: fields[1], currencyCode: fields[2], createdAt: fields[3] };
}

function parseCategory(line: string): FenLiCategory | null {
  const fields: string[] = fieldsOf(line);
  if (fields.length !== 4) {
    return null;
  }
  return { id: fields[0], name: fields[1], iconName: fields[2], colorHex: fields[3] };
}

function parseTransaction(line: string): FenLiTransaction | null {
  const fields: string[] = fieldsOf(line);
  if (fields.length !== 7) {
    return null;
  }
  const amountCents: number = numberOrDefault(fields[3], -1);
  if (amountCents < 0) {
    return null;
  }
  return {
    id: fields[0],
    ledgerId: fields[1],
    categoryId: fields[2],
    amountCents,
    note: fields[4],
    occurredOn: fields[5],
    createdAt: fields[6]
  };
}

export class FenLiStorage {
  public static async load(context: Context): Promise<FenLiStoreData> {
    try {
      const store: preferences.Preferences = await preferences.getPreferences(context, STORE_NAME);
      const storedValue: preferences.ValueType = await store.get(STORE_KEY, '');
      if (typeof storedValue !== 'string' || storedValue.length === 0) {
        return createFenLiDemoData();
      }
      return FenLiStorage.deserialize(storedValue);
    } catch (error) {
      return createFenLiDemoData();
    }
  }

  public static async save(context: Context, data: FenLiStoreData): Promise<void> {
    const store: preferences.Preferences = await preferences.getPreferences(context, STORE_NAME);
    await store.put(STORE_KEY, FenLiStorage.serialize(data));
    await store.flush();
  }

  public static serialize(data: FenLiStoreData): string {
    const lines: string[] = [
      FORMAT_VERSION,
      `activeLedger|${encodeField(data.activeLedgerId)}`,
      `budget|${data.budget.monthlyLimitCents}|${data.budget.warningPercent}|${booleanToText(data.budget.enabled)}`,
      `reminder|${booleanToText(data.reminder.enabled)}|${data.reminder.hour}|${data.reminder.minute}|${data.reminder.reminderId}|${encodeField(data.reminder.message)}`
    ];
    data.ledgers.forEach((item: FenLiLedger): void => {
      lines.push(`ledger|${encodeLedger(item)}`);
    });
    data.categories.forEach((item: FenLiCategory): void => {
      lines.push(`category|${encodeCategory(item)}`);
    });
    data.transactions.forEach((item: FenLiTransaction): void => {
      lines.push(`transaction|${encodeTransaction(item)}`);
    });
    return lines.join('\n');
  }

  public static deserialize(raw: string): FenLiStoreData {
    try {
      const lines: string[] = raw.split('\n');
      if (lines.length < 4 || lines[0] !== FORMAT_VERSION) {
        return createFenLiDemoData();
      }
      const fallback: FenLiStoreData = createFenLiDemoData();
      let activeLedgerId: string = fallback.activeLedgerId;
      let budget: FenLiBudgetSettings = fallback.budget;
      let reminder: FenLiReminderSettings = fallback.reminder;
      const ledgers: FenLiLedger[] = [];
      const categories: FenLiCategory[] = [];
      const transactions: FenLiTransaction[] = [];
      lines.slice(1).forEach((line: string): void => {
        const parts: string[] = line.split('|');
        const kind: string = parts[0];
        if (kind === 'activeLedger' && parts.length === 2) {
          activeLedgerId = decodeField(parts[1]);
        } else if (kind === 'budget' && parts.length === 4) {
          budget = {
            monthlyLimitCents: numberOrDefault(parts[1], fallback.budget.monthlyLimitCents),
            warningPercent: numberOrDefault(parts[2], fallback.budget.warningPercent),
            enabled: textToBoolean(parts[3], fallback.budget.enabled)
          };
        } else if (kind === 'reminder' && (parts.length === 5 || parts.length === 6)) {
          reminder = {
            enabled: textToBoolean(parts[1], fallback.reminder.enabled),
            hour: numberOrDefault(parts[2], fallback.reminder.hour),
            minute: numberOrDefault(parts[3], fallback.reminder.minute),
            reminderId: parts.length === 6 ? numberOrDefault(parts[4], -1) : -1,
            message: decodeField(parts.length === 6 ? parts[5] : parts[4])
          };
        } else if (kind === 'ledger') {
          const item: FenLiLedger | null = parseLedger(line.substring(7));
          if (item !== null) {
            ledgers.push(item);
          }
        } else if (kind === 'category') {
          const item: FenLiCategory | null = parseCategory(line.substring(9));
          if (item !== null) {
            categories.push(item);
          }
        } else if (kind === 'transaction') {
          const item: FenLiTransaction | null = parseTransaction(line.substring(12));
          if (item !== null) {
            transactions.push(item);
          }
        }
      });
      if (ledgers.length === 0 || activeLedgerId.length === 0) {
        return fallback;
      }
      return {
        schemaVersion: 1,
        activeLedgerId,
        ledgers,
        categories,
        transactions,
        budget,
        reminder
      };
    } catch (error) {
      return createFenLiDemoData();
    }
  }
}
