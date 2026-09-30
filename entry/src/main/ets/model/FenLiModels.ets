export interface FenLiTransaction {
  id: string;
  ledgerId: string;
  categoryId: string;
  amountCents: number;
  note: string;
  occurredOn: string;
  createdAt: string;
}

export interface FenLiLedger {
  id: string;
  name: string;
  currencyCode: string;
  createdAt: string;
}

export interface FenLiCategory {
  id: string;
  name: string;
  iconName: string;
  colorHex: string;
}

export interface FenLiBudgetSettings {
  monthlyLimitCents: number;
  warningPercent: number;
  enabled: boolean;
}

export interface FenLiReminderSettings {
  enabled: boolean;
  hour: number;
  minute: number;
  message: string;
  reminderId: number;
}

export interface FenLiStoreData {
  schemaVersion: number;
  activeLedgerId: string;
  ledgers: FenLiLedger[];
  categories: FenLiCategory[];
  transactions: FenLiTransaction[];
  budget: FenLiBudgetSettings;
  reminder: FenLiReminderSettings;
}

export function createFenLiDemoData(): FenLiStoreData {
  const today: Date = new Date();
  const todayKey: string = today.getFullYear() + '-' + (today.getMonth() + 1 < 10 ? '0' : '') + (today.getMonth() + 1) + '-' + (today.getDate() < 10 ? '0' : '') + today.getDate();
  const ledger: FenLiLedger = {
    id: 'ledger-demo',
    name: '日常账本',
    currencyCode: 'CNY',
    createdAt: '2026-01-01'
  };
  const personalLedger: FenLiLedger = {
    id: 'ledger-personal',
    name: '个人账本',
    currencyCode: 'CNY',
    createdAt: '2026-01-01'
  };
  const foodCategory: FenLiCategory = {
    id: 'category-food',
    name: '餐饮',
    iconName: 'restaurant',
    colorHex: '#E06B4F'
  };
  const transportCategory: FenLiCategory = {
    id: 'category-transport',
    name: '交通',
    iconName: 'directions_car',
    colorHex: '#4E7BAA'
  };
  const shoppingCategory: FenLiCategory = { id: 'category-shopping', name: '购物', iconName: 'shopping', colorHex: '#A26BB7' };
  const entertainmentCategory: FenLiCategory = { id: 'category-entertainment', name: '娱乐', iconName: 'entertainment', colorHex: '#D59B45' };
  const dailyCategory: FenLiCategory = { id: 'category-daily', name: '日用', iconName: 'daily', colorHex: '#6A9B73' };
  const studyCategory: FenLiCategory = { id: 'category-study', name: '学习', iconName: 'study', colorHex: '#5978A8' };
  const medicalCategory: FenLiCategory = { id: 'category-medical', name: '医疗', iconName: 'medical', colorHex: '#C85D6D' };
  const otherCategory: FenLiCategory = { id: 'category-other', name: '其他', iconName: 'other', colorHex: '#888888' };
  const transactions: FenLiTransaction[] = [
    {
      id: 'transaction-demo-1',
      ledgerId: ledger.id,
      categoryId: foodCategory.id,
      amountCents: 2800,
      note: '午餐',
       occurredOn: todayKey,
       createdAt: todayKey + 'T12:30:00'
    },
    {
      id: 'transaction-demo-2',
      ledgerId: ledger.id,
      categoryId: transportCategory.id,
      amountCents: 600,
      note: '地铁',
       occurredOn: todayKey,
       createdAt: todayKey + 'T08:10:00'
    }
  ];
  const budget: FenLiBudgetSettings = {
    monthlyLimitCents: 300000,
    warningPercent: 80,
    enabled: true
  };
  const reminder: FenLiReminderSettings = {
    enabled: true,
    hour: 21,
    minute: 0,
    message: '记得记录今天的支出',
    reminderId: -1
  };
  return {
    schemaVersion: 1,
    activeLedgerId: ledger.id,
    ledgers: [ledger, personalLedger],
    categories: [foodCategory, transportCategory, shoppingCategory, entertainmentCategory, dailyCategory, studyCategory, medicalCategory, otherCategory],
    transactions,
    budget,
    reminder
  };
}
