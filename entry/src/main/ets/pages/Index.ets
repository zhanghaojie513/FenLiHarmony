import {
  createFenLiDemoData,
  FenLiCategory,
  FenLiLedger,
  FenLiStoreData,
  FenLiTransaction as FenLiStoredTransaction
} from '../model/FenLiModels';
import { FenLiStorage } from '../service/FenLiStorage';
import { FenLiExport } from '../service/FenLiExport';
import { FenLiReminder, FenLiReminderStatus } from '../service/FenLiReminder';

interface FenLiTransaction {
  id: string;
  number: string;
  title: string;
  category: string;
  detail: string;
  amount: number;
  time: string;
  date: string;
}

@CustomDialog
struct FenLiNameDialog {
  controller: CustomDialogController;
  @State inputText: string = '';
  titleText: string = '';
  initialText: string = '';
  onConfirm: (name: string) => void = (_name: string): void => {};

  aboutToAppear(): void {
    this.inputText = this.initialText;
  }

  build() {
    Column({ space: 18 }) {
      Text(this.titleText).fontSize(20).fontWeight(FontWeight.Bold).alignSelf(ItemAlign.Start)
      TextInput({ placeholder: '请输入名称', text: this.inputText })
        .width('100%')
        .onChange((value: string): void => {
          this.inputText = value;
        })
      Row({ space: 12 }) {
        Button('取消').layoutWeight(1).onClick(() => this.controller.close())
        Button('确定').layoutWeight(1).onClick(() => {
          const name: string = this.inputText.trim();
          if (name.length > 0) {
            this.onConfirm(name);
            this.controller.close();
          }
        })
      }
    }
    .padding(24)
    .width('88%')
    .backgroundColor('#FFFFFF')
  }
}

function fenliDateKey(value: Date): string {
  const year: string = '' + value.getFullYear();
  const month: string = value.getMonth() + 1 < 10 ? '0' + (value.getMonth() + 1) : '' + (value.getMonth() + 1);
  const day: string = value.getDate() < 10 ? '0' + value.getDate() : '' + value.getDate();
  return year + '-' + month + '-' + day;
}

@Entry
@Component
struct Index {
  @State currentTab: number = 0;
  private tabsController: TabsController = new TabsController();
  @State amountText: string = '0.00';
  private pendingAmount: number = 0;
  private pendingOperator: string = '';
  private replaceAmount: boolean = false;
  @State selectedCategory: string = '餐饮';
  @State noteText: string = '';
  @State savedMessage: string = '';
  @State selectedDate: Date = new Date();
  @State entryDate: Date = new Date();
  @State currentBookLabel: string = '默认账本';
  @State budgetLabel: string = '¥15,000 / 月';
  @State reminderLabel: string = '每日 22:00';
  @State storeData: FenLiStoreData = createFenLiDemoData();
  @State dataReady: boolean = false;
  @State editTransactionId: string = '';
  private saving: boolean = false;
  private reminderId: number = -1;
  @State transactions: FenLiTransaction[] = [
    { id: 'legacy-01', number: '01', title: '午餐', category: '餐饮', detail: '公司楼下沙拉轻食', amount: 42.00, time: '12:35', date: fenliDateKey(new Date()) },
    { id: 'legacy-02', number: '02', title: '咖啡', category: '餐饮', detail: 'Manner 冰美式', amount: 15.00, time: '09:20', date: fenliDateKey(new Date()) },
    { id: 'legacy-03', number: '03', title: '地铁', category: '交通', detail: '通勤往返', amount: 8.00, time: '08:15', date: fenliDateKey(new Date()) },
    { id: 'legacy-04', number: '04', title: '书籍', category: '学习', detail: '《设计心理学》', amount: 68.00, time: '14:50', date: fenliDateKey(new Date()) },
    { id: 'legacy-05', number: '05', title: '晚餐', category: '餐饮', detail: '海底捞（与朋友聚餐 AA）', amount: 156.50, time: '19:10', date: fenliDateKey(new Date()) },
    { id: 'legacy-06', number: '06', title: '水果', category: '日用', detail: '百果园 车厘子', amount: 558.00, time: '20:30', date: fenliDateKey(new Date()) }
  ];

  aboutToAppear(): void {
    this.loadStoredData();
  }

  private async loadStoredData(): Promise<void> {
    const context: Context = getContext(this);
    const loaded: FenLiStoreData = await FenLiStorage.load(context);
    this.storeData = loaded;
    this.currentBookLabel = this.activeLedgerName(loaded);
    this.budgetLabel = '¥' + (loaded.budget.monthlyLimitCents / 100).toFixed(0) + ' / 月';
    this.reminderLabel = loaded.reminder.enabled ? '每日 ' + this.pad2(loaded.reminder.hour) + ':' + this.pad2(loaded.reminder.minute) : '关闭提醒';
    this.reminderId = loaded.reminder.reminderId;
    this.transactions = this.legacyTransactions(loaded);
    this.dataReady = true;
  }

  private activeLedgerName(data: FenLiStoreData): string {
    for (const ledger of data.ledgers) {
      if (ledger.id === data.activeLedgerId) {
        return ledger.name;
      }
    }
    return data.ledgers.length > 0 ? data.ledgers[0].name : '默认账本';
  }

  private legacyTransactions(data: FenLiStoreData): FenLiTransaction[] {
    const result: FenLiTransaction[] = [];
    let number: number = 1;
    for (const stored of data.transactions) {
      if (stored.ledgerId !== data.activeLedgerId) {
        continue;
      }
      let categoryName: string = '其他';
      for (const category of data.categories) {
        if (category.id === stored.categoryId) {
          categoryName = category.name;
          break;
        }
      }
      result.push({
        id: stored.id,
        number: this.pad2(number),
        title: categoryName,
        category: categoryName,
        detail: stored.note,
        amount: stored.amountCents / 100,
        time: stored.createdAt.length >= 16 ? stored.createdAt.substring(11, 16) : '00:00',
        date: stored.occurredOn
      });
      number += 1;
    }
    return result;
  }

  private activeCategoryId(): string {
    for (const category of this.storeData.categories) {
      if (category.name === this.selectedCategory) {
        return category.id;
      }
    }
    return this.storeData.categories.length > 0 ? this.storeData.categories[0].id : 'category-other';
  }

  private hasCategory(name: string): boolean {
    for (const category of this.storeData.categories) {
      if (category.name === name) {
        return true;
      }
    }
    return false;
  }

  private async persistStoreData(): Promise<void> {
    if (this.saving) {
      throw new Error('保存正在进行');
    }
    this.saving = true;
    const context: Context = getContext(this);
    try {
      await FenLiStorage.save(context, this.storeData);
    } finally {
      this.saving = false;
    }
  }

  private applyReminderSettings(): void {
    if (!this.storeData.reminder.enabled && this.reminderId >= 0) {
      FenLiReminder.cancel(this.reminderId).then((result: FenLiReminderStatus): void => {
        this.savedMessage = result.message;
        this.reminderId = -1;
      });
      return;
    }
    if (this.storeData.reminder.enabled && this.reminderId >= 0) {
      FenLiReminder.cancel(this.reminderId).then((): void => {
        this.reminderId = -1;
        this.storeData.reminder.reminderId = -1;
        this.applyReminderSettings();
      });
      return;
    }
    FenLiReminder.scheduleDaily(this.storeData.reminder).then((result: FenLiReminderStatus): void => {
      this.savedMessage = result.message;
      if (result.reminderId >= 0) {
        this.reminderId = result.reminderId;
        this.storeData.reminder.reminderId = result.reminderId;
        this.persistStoreData().catch(() => {
          this.savedMessage = '提醒编号保存失败';
        });
      }
    });
  }

  private selectLedger(ledgerId: string): void {
    const previousId: string = this.storeData.activeLedgerId;
    this.storeData.activeLedgerId = ledgerId;
    this.currentBookLabel = this.activeLedgerName(this.storeData);
    this.transactions = this.legacyTransactions(this.storeData);
    this.persistStoreData().catch(() => {
      this.storeData.activeLedgerId = previousId;
      this.currentBookLabel = this.activeLedgerName(this.storeData);
      this.transactions = this.legacyTransactions(this.storeData);
      this.savedMessage = '账本切换保存失败';
    });
  }

  private async deleteTransaction(id: string): Promise<void> {
    const previous: FenLiStoreData = this.storeData;
    this.storeData = {
      schemaVersion: previous.schemaVersion,
      activeLedgerId: previous.activeLedgerId,
      ledgers: previous.ledgers,
      categories: previous.categories,
      transactions: previous.transactions.filter((item: FenLiStoredTransaction): boolean => item.id !== id),
      budget: previous.budget,
      reminder: previous.reminder
    };
    try {
      await this.persistStoreData();
      this.transactions = this.legacyTransactions(this.storeData);
      this.savedMessage = '记录已删除';
    } catch (_error) {
      this.storeData = previous;
      this.savedMessage = '删除记录保存失败';
    }
  }

  private confirmDeleteTransaction(id: string): void {
    this.getUIContext().showAlertDialog({
      title: '删除记录',
      message: '删除后无法恢复，确定继续吗？',
      buttons: [
        { value: '删除', action: () => { this.deleteTransaction(id); } },
        { value: '取消', action: () => {} }
      ]
    });
  }

  private dailyTotal(): number {
    let sumCents: number = 0;
    const key: string = fenliDateKey(this.selectedDate);
    for (const item of this.transactions) {
      if (item.date === key) {
        sumCents += Math.round(item.amount * 100);
      }
    }
    return sumCents / 100;
  }

  private dailyTransactions(): FenLiTransaction[] {
    const result: FenLiTransaction[] = [];
    const key: string = fenliDateKey(this.selectedDate);
    let number: number = 1;
    for (const item of this.transactions) {
      if (item.date === key) {
        result.push({
          id: item.id,
          number: this.pad2(number),
          title: item.title,
          category: item.category,
          detail: item.detail,
          amount: item.amount,
          time: item.time,
          date: item.date
        });
        number += 1;
      }
    }
    return result;
  }

  private daysInMonth(year: number, month: number): number {
    return new Date(year, month + 1, 0).getDate();
  }

  private weekStart(value: Date): Date {
    const start: Date = new Date(value.getFullYear(), value.getMonth(), value.getDate());
    const day: number = start.getDay();
    const distance: number = day === 0 ? 6 : day - 1;
    start.setDate(start.getDate() - distance);
    return start;
  }

  private weekEnd(value: Date): Date {
    const end: Date = this.weekStart(value);
    end.setDate(end.getDate() + 6);
    return end;
  }

  private periodTransactions(start: Date, end: Date): FenLiTransaction[] {
    const result: FenLiTransaction[] = [];
    const startKey: string = fenliDateKey(start);
    const endKey: string = fenliDateKey(end);
    for (const item of this.transactions) {
      if (item.date >= startKey && item.date <= endKey) {
        result.push(item);
      }
    }
    return result;
  }

  private totalFor(items: FenLiTransaction[]): number {
    let sumCents: number = 0;
    for (const item of items) {
      sumCents += Math.round(item.amount * 100);
    }
    return sumCents / 100;
  }

  private weeklyTransactions(): FenLiTransaction[] {
    return this.periodTransactions(this.weekStart(this.selectedDate), this.weekEnd(this.selectedDate));
  }

  private weeklyTotal(): number {
    return this.totalFor(this.weeklyTransactions());
  }

  private monthTransactions(): FenLiTransaction[] {
    const start: Date = new Date(this.selectedDate.getFullYear(), this.selectedDate.getMonth(), 1);
    const end: Date = new Date(this.selectedDate.getFullYear(), this.selectedDate.getMonth(), this.daysInMonth(this.selectedDate.getFullYear(), this.selectedDate.getMonth()));
    return this.periodTransactions(start, end);
  }

  private monthlyTotal(): number {
    return this.totalFor(this.monthTransactions());
  }

  private recordedDays(): number {
    const days: string[] = [];
    for (const item of this.transactions) {
      if (days.indexOf(item.date) < 0) {
        days.push(item.date);
      }
    }
    return days.length;
  }

  private monthlyCount(): number {
    return this.monthTransactions().length;
  }

  private shiftDays(amount: number): Date {
    const next: Date = new Date(this.selectedDate.getFullYear(), this.selectedDate.getMonth(), this.selectedDate.getDate());
    next.setDate(next.getDate() + amount);
    return next;
  }

  private shiftMonths(amount: number): Date {
    const targetYear: number = this.selectedDate.getFullYear();
    const targetMonth: number = this.selectedDate.getMonth() + amount;
    const targetDay: number = Math.min(this.selectedDate.getDate(), this.daysInMonth(targetYear, targetMonth));
    return new Date(targetYear, targetMonth, targetDay);
  }

  private changeDate(amount: number): void {
    this.selectedDate = this.shiftDays(amount);
  }

  private changeWeek(amount: number): void {
    this.selectedDate = this.shiftDays(amount * 7);
  }

  private changeMonth(amount: number): void {
    this.selectedDate = this.shiftMonths(amount);
  }

  private openDailyDatePicker(): void {
    this.getUIContext().showDatePickerDialog({
      start: new Date(2020, 0, 1),
      end: new Date(2100, 11, 31),
      selected: this.selectedDate,
      lunar: false,
      onDateAccept: (value: Date) => {
        this.selectedDate = value;
      }
    });
  }

  private pickerIndex(value: TextPickerResult): number {
    if (typeof value.index === 'number') {
      return value.index;
    }
    return value.index[0] ?? 0;
  }

  private weekPickerDate(index: number): Date {
    const start: Date = this.weekStart(this.selectedDate);
    start.setDate(start.getDate() + (index - 60) * 7);
    return start;
  }

  private weekPickerRange(): string[] {
    const range: string[] = [];
    for (let index: number = 0; index < 121; index++) {
      const start: Date = this.weekPickerDate(index);
      range.push(this.dateRangeLabel(start, this.weekEnd(start)));
    }
    return range;
  }

  private openWeekPicker(): void {
    this.getUIContext().showTextPickerDialog({
      range: this.weekPickerRange(),
      selected: 60,
      canLoop: false,
      onAccept: (value: TextPickerResult) => {
        this.selectedDate = this.weekPickerDate(this.pickerIndex(value));
      }
    });
  }

  private monthPickerDate(index: number): Date {
    return new Date(this.selectedDate.getFullYear(), this.selectedDate.getMonth() + index - 30, 1);
  }

  private monthPickerRange(): string[] {
    const range: string[] = [];
    for (let index: number = 0; index < 61; index++) {
      const value: Date = this.monthPickerDate(index);
      range.push('' + value.getFullYear() + '年' + (value.getMonth() + 1) + '月');
    }
    return range;
  }

  private openMonthPicker(): void {
    this.getUIContext().showTextPickerDialog({
      range: this.monthPickerRange(),
      selected: 30,
      canLoop: false,
      onAccept: (value: TextPickerResult) => {
        this.selectedDate = this.monthPickerDate(this.pickerIndex(value));
      }
    });
  }

  private weekdayLabel(value: Date): string {
    switch (value.getDay()) {
      case 0:
        return '星期日';
      case 1:
        return '星期一';
      case 2:
        return '星期二';
      case 3:
        return '星期三';
      case 4:
        return '星期四';
      case 5:
        return '星期五';
      default:
        return '星期六';
    }
  }

  private monthName(value: Date): string {
    switch (value.getMonth()) {
      case 0:
        return '一月';
      case 1:
        return '二月';
      case 2:
        return '三月';
      case 3:
        return '四月';
      case 4:
        return '五月';
      case 5:
        return '六月';
      case 6:
        return '七月';
      case 7:
        return '八月';
      case 8:
        return '九月';
      case 9:
        return '十月';
      case 10:
        return '十一月';
      default:
        return '十二月';
    }
  }

  private monthLabel(): string {
    return this.monthName(this.selectedDate);
  }

  private weekNumber(): number {
    const thursday: Date = new Date(this.weekStart(this.selectedDate).getTime());
    thursday.setDate(thursday.getDate() + 3);
    const firstThursday: Date = new Date(thursday.getFullYear(), 0, 4);
    return Math.floor((this.weekStart(this.selectedDate).getTime() - this.weekStart(firstThursday).getTime()) / 604800000) + 1;
  }

  private weekLabel(): string {
    const thursday: Date = new Date(this.weekStart(this.selectedDate).getTime());
    thursday.setDate(thursday.getDate() + 3);
    return '' + thursday.getFullYear() + ' · 第 ' + this.weekNumber() + ' 周（ISO 周一至周日）';
  }

  private dateRangeLabel(start: Date, end: Date): string {
    return (start.getMonth() + 1) + '.' + start.getDate() + ' — ' + (end.getMonth() + 1) + '.' + end.getDate();
  }

  private dailyDateLabel(): string {
    return (this.selectedDate.getMonth() + 1) + '月' + this.selectedDate.getDate() + '日';
  }

  private shortDateLabel(value: Date): string {
    return value.getFullYear() + '.' + this.pad2(value.getMonth() + 1) + '.' + this.pad2(value.getDate());
  }

  private weeklyAverage(): string {
    return (this.weeklyTotal() / 7).toFixed(2);
  }

  private monthlyAverage(): string {
    const monthDays: number = this.daysInMonth(this.selectedDate.getFullYear(), this.selectedDate.getMonth());
    return (this.monthlyTotal() / monthDays).toFixed(2);
  }

  private currentMonthDate(): Date {
    const now: Date = new Date();
    return new Date(now.getFullYear(), now.getMonth(), now.getDate());
  }

  private currentMonthTransactions(): FenLiTransaction[] {
    const now: Date = this.currentMonthDate();
    return this.periodTransactions(new Date(now.getFullYear(), now.getMonth(), 1), new Date(now.getFullYear(), now.getMonth(), this.daysInMonth(now.getFullYear(), now.getMonth())));
  }

  private currentMonthTotal(): number {
    return this.totalFor(this.currentMonthTransactions());
  }

  private currentMonthAverage(): string {
    const now: Date = this.currentMonthDate();
    return (this.currentMonthTotal() / this.daysInMonth(now.getFullYear(), now.getMonth())).toFixed(2);
  }

  private budgetUsedCents(): number {
    let cents: number = 0;
    for (const item of this.currentMonthTransactions()) { cents += Math.round(item.amount * 100); }
    return cents;
  }

  private budgetRemainingCents(): number {
    return this.storeData.budget.monthlyLimitCents - this.budgetUsedCents();
  }

  private budgetStatusLabel(): string {
    const remaining: number = this.budgetRemainingCents();
    return remaining < 0 ? '已超支 ¥' + (Math.abs(remaining) / 100).toFixed(2) : '剩余 ¥' + (remaining / 100).toFixed(2);
  }

  private comparisonText(current: number, previous: number): string {
    if (previous === 0) {
      return current === 0 ? '—' : '+' + current.toFixed(2);
    }
    const difference: number = current - previous;
    const percent: number = difference / previous * 100;
    const sign: string = difference >= 0 ? '+' : '−';
    return sign + Math.abs(difference).toFixed(2) + '  ' + sign + Math.abs(percent).toFixed(1) + '%';
  }

  private previousWeekTotal(): number {
    return this.weeklyTotalAt(this.shiftDays(-7));
  }

  private weeklyTotalAt(value: Date): number {
    return this.totalFor(this.periodTransactions(this.weekStart(value), this.weekEnd(value)));
  }

  private twoWeeksAgoTotal(): number {
    return this.weeklyTotalAt(this.shiftDays(-14));
  }

  private previousMonthWeekTotal(): number {
    return this.weeklyTotalAt(this.shiftMonths(-1));
  }

  private weekdayAmount(offset: number): number {
    const day: Date = this.weekStart(this.selectedDate);
    day.setDate(day.getDate() + offset);
    return this.totalFor(this.periodTransactions(day, day));
  }

  private trendHeight(amount: number): number {
    let max: number = 0;
    for (let index: number = 0; index < 7; index++) {
      max = Math.max(max, this.weekdayAmount(index));
    }
    return max === 0 ? 5 : 20 + amount / max * 90;
  }

  private weekdayIndex(): number {
    const day: number = this.selectedDate.getDay();
    return day === 0 ? 6 : day - 1;
  }

  private categoryAmount(category: string): number {
    let sumCents: number = 0;
    for (const item of this.monthTransactions()) {
      if (item.category === category) {
        sumCents += Math.round(item.amount * 100);
      }
    }
    return sumCents / 100;
  }

  private categoryRatio(category: string): number {
    const total: number = this.monthlyTotal();
    return total === 0 ? 0 : this.categoryAmount(category) / total * 100;
  }

  private categoryRatioLabel(category: string): string {
    return this.categoryRatio(category).toFixed(1) + '%';
  }

  private pad2(value: number): string {
    return value < 10 ? '0' + value : '' + value;
  }

  private currentTime(): string {
    const now: Date = new Date();
    return this.pad2(now.getHours()) + ':' + this.pad2(now.getMinutes());
  }

  private appendDigit(digit: string): void {
    if (this.replaceAmount || this.amountText === '0.00') {
      this.amountText = '';
      this.replaceAmount = false;
    }
    if (digit === '.') {
      if (this.amountText.indexOf('.') >= 0) {
        return;
      }
      this.amountText = this.amountText.length === 0 || this.amountText === '0.00' ? '0.' : this.amountText + '.';
      return;
    }
    if (this.amountText === '0.00' || this.amountText.length === 0) {
      this.amountText = digit;
      return;
    }
    const decimalIndex: number = this.amountText.indexOf('.');
    if (decimalIndex >= 0 && this.amountText.length - decimalIndex > 2) {
      return;
    }
    if (this.amountText === '0') {
      this.amountText = digit;
    } else if (this.amountText.length < 8) {
      this.amountText = this.amountText + digit;
    }
  }

  private removeDigit(): void {
    if (this.replaceAmount) {
      this.amountText = '';
      this.replaceAmount = false;
      return;
    }
    if (this.amountText.length <= 1) {
      this.amountText = '';
      return;
    }
    this.amountText = this.amountText.substring(0, this.amountText.length - 1);
  }

  private chooseCategory(category: string): void {
    this.selectedCategory = category;
  }

  private openTransactionDetail(item: FenLiTransaction): void {
    this.getUIContext().showAlertDialog({
      title: item.title + ' · ¥' + item.amount.toFixed(2),
      message: item.detail + '\n' + item.date + ' ' + item.time,
      buttons: [
        { value: '编辑', action: () => { this.editTransaction(item.id); } },
        { value: '删除', action: () => { this.confirmDeleteTransaction(item.id); } },
        { value: '关闭', action: () => {} }
      ]
    });
  }

  private editTransaction(id: string): void {
    for (const item of this.storeData.transactions) {
      if (item.id === id) {
        this.editTransactionId = item.id;
        this.amountText = (item.amountCents / 100).toFixed(2);
        this.selectedCategory = this.categoryName(item.categoryId);
        this.noteText = item.note;
        this.entryDate = new Date(item.occurredOn + 'T00:00:00');
        this.clearAmountOperation();
        this.switchTab(2);
        return;
      }
    }
  }

  private categoryName(id: string): string {
    for (const category of this.storeData.categories) {
      if (category.id === id) {
        return category.name;
      }
    }
    return this.storeData.categories.length > 0 ? this.storeData.categories[0].name : '其他';
  }

  private cancelEntry(): void {
    this.amountText = '0.00';
    this.clearAmountOperation();
    this.noteText = '';
    this.entryDate = new Date();
    this.editTransactionId = '';
    this.selectedCategory = this.storeData.categories.length > 0 ? this.storeData.categories[0].name : '其他';
    this.switchTab(0);
  }

  private updateAmountText(value: string): void {
    this.amountText = value;
    this.replaceAmount = false;
  }

  private resolveAmount(): number {
    const current: number = Number(this.amountText);
    if (this.pendingOperator.length === 0 || this.replaceAmount) {
      return current;
    }
    const cents: number = Math.round(current * 100);
    return (this.pendingOperator === '+' ? this.pendingAmount + cents : this.pendingAmount - cents) / 100;
  }

  private chooseAmountOperator(operator: string): void {
    const amount: number = this.resolveAmount();
    if (!Number.isFinite(amount) || amount < 0 || amount > 99999999) {
      this.getUIContext().showAlertDialog({
        title: '金额无效',
        message: '运算结果须在 0 到 99,999,999 之间。',
        buttons: [{ value: '知道了', action: () => {} }]
      });
      return;
    }
    this.pendingAmount = Math.round(amount * 100);
    this.pendingOperator = operator;
    this.amountText = amount.toFixed(2);
    this.replaceAmount = true;
  }

  private clearAmountOperation(): void {
    this.pendingAmount = 0;
    this.pendingOperator = '';
    this.replaceAmount = false;
  }

  private openEntryDatePicker(): void {
    this.getUIContext().showDatePickerDialog({
      start: new Date(2020, 0, 1),
      end: new Date(2100, 11, 31),
      selected: this.entryDate,
      lunar: false,
      onDateAccept: (value: Date) => {
        this.entryDate = value;
      }
    });
  }

  private showBookSettings(): void {
    const sheets: SheetInfo[] = [];
    for (const ledger of this.storeData.ledgers) {
      sheets.push({ title: (ledger.id === this.storeData.activeLedgerId ? '✓ ' : '') + ledger.name, action: () => { this.selectLedger(ledger.id); } });
    }
    sheets.push({ title: '新增账本', action: () => { this.openNameDialog('新增账本', '', (name: string): void => { this.addLedger(name); }); } });
    sheets.push({ title: '重命名当前账本', action: () => { this.openNameDialog('重命名账本', this.currentBookLabel, (name: string): void => { this.renameLedger(name); }); } });
    sheets.push({ title: '删除当前账本', action: () => { this.confirmDeleteLedger(); } });
    this.getUIContext().showActionSheet({
      title: '账本管理',
      message: '选择账本或管理当前账本',
      sheets
    });
  }

  private openNameDialog(title: string, initial: string, callback: (name: string) => void): void {
    const controller: CustomDialogController = new CustomDialogController({
      builder: FenLiNameDialog({ titleText: title, initialText: initial, onConfirm: callback }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: false
    });
    controller.open();
  }

  private addLedger(name: string): void {
    if (this.ledgerNameExists(name)) {
      this.savedMessage = '账本名称已存在';
      return;
    }
    const now: Date = new Date();
    const ledger: FenLiLedger = { id: 'ledger-' + now.getTime(), name, currencyCode: 'CNY', createdAt: fenliDateKey(now) };
    const previous: FenLiStoreData = this.storeData;
    this.storeData.ledgers = previous.ledgers.concat([ledger]);
    this.persistStoreData().then(() => { this.savedMessage = '已新增账本：' + name; }).catch(() => { this.storeData.ledgers = previous.ledgers; this.savedMessage = '账本保存失败'; });
  }

  private ledgerNameExists(name: string): boolean {
    for (const ledger of this.storeData.ledgers) {
      if (ledger.name === name) {
        return true;
      }
    }
    return false;
  }

  private renameLedger(name: string): void {
    if (this.ledgerNameExists(name)) {
      this.savedMessage = '账本名称已存在';
      return;
    }
    const previousName: string = this.currentBookLabel;
    for (const ledger of this.storeData.ledgers) {
      if (ledger.id === this.storeData.activeLedgerId) {
        ledger.name = name;
      }
    }
    this.currentBookLabel = name;
    this.persistStoreData().then(() => { this.savedMessage = '账本已重命名'; }).catch(() => {
      for (const ledger of this.storeData.ledgers) { if (ledger.id === this.storeData.activeLedgerId) { ledger.name = previousName; } }
      this.currentBookLabel = previousName;
      this.savedMessage = '账本重命名保存失败';
    });
  }

  private confirmDeleteLedger(): void {
    if (this.storeData.ledgers.length <= 1) {
      this.savedMessage = '至少保留一个账本';
      return;
    }
    this.getUIContext().showAlertDialog({
      title: '删除账本',
      message: '账本中的记录将迁移到另一个账本，确定删除吗？',
      buttons: [{ value: '删除并迁移', action: () => { this.deleteLedger(); } }, { value: '取消', action: () => {} }]
    });
  }

  private deleteLedger(): void {
    let targetId: string = '';
    for (const ledger of this.storeData.ledgers) {
      if (ledger.id !== this.storeData.activeLedgerId) {
        targetId = ledger.id;
        break;
      }
    }
    const previous: FenLiStoreData = this.storeData;
    const movedTransactions: FenLiStoredTransaction[] = previous.transactions.map((item: FenLiStoredTransaction): FenLiStoredTransaction => {
      if (item.ledgerId !== previous.activeLedgerId) {
        return item;
      }
      return { id: item.id, ledgerId: targetId, categoryId: item.categoryId, amountCents: item.amountCents, note: item.note, occurredOn: item.occurredOn, createdAt: item.createdAt };
    });
    this.storeData = {
      schemaVersion: previous.schemaVersion,
      activeLedgerId: targetId,
      ledgers: previous.ledgers.filter((ledger: FenLiLedger): boolean => ledger.id !== previous.activeLedgerId),
      categories: previous.categories,
      transactions: movedTransactions,
      budget: previous.budget,
      reminder: previous.reminder
    };
    this.currentBookLabel = this.activeLedgerName(this.storeData);
    this.persistStoreData().then(() => { this.transactions = this.legacyTransactions(this.storeData); this.savedMessage = '账本已删除，记录已迁移'; }).catch(() => { this.storeData = previous; this.currentBookLabel = this.activeLedgerName(previous); this.savedMessage = '账本删除保存失败'; });
  }

  private showCategorySettings(): void {
    const sheets: SheetInfo[] = [];
    for (const category of this.storeData.categories) {
      sheets.push({ title: category.name, action: () => { this.openCategoryActions(category); } });
    }
    sheets.push({ title: '新增分类', action: () => { this.openNameDialog('新增分类', '', (name: string): void => { this.addCategory(name); }); } });
    this.getUIContext().showActionSheet({
      title: '分类管理',
      message: '选择分类后重命名或删除',
      sheets
    });
  }

  private openCategoryActions(category: FenLiCategory): void {
    this.getUIContext().showActionSheet({ title: category.name, message: '管理分类', sheets: [
      { title: '重命名', action: () => { this.openNameDialog('重命名分类', category.name, (name: string): void => { this.renameCategory(category.id, name); }); } },
      { title: '删除', action: () => { this.confirmDeleteCategory(category.name); } }
    ] });
  }

  private addCategory(name: string): void {
    if (this.hasCategory(name)) { this.savedMessage = '分类名称已存在'; return; }
    const category: FenLiCategory = { id: 'category-' + new Date().getTime(), name, iconName: 'other', colorHex: '#888888' };
    const previous: FenLiCategory[] = this.storeData.categories;
    this.storeData.categories = previous.concat([category]);
    this.persistStoreData().then(() => { this.savedMessage = '已新增分类：' + name; }).catch(() => { this.storeData.categories = previous; this.savedMessage = '分类保存失败'; });
  }

  private renameCategory(id: string, name: string): void {
    for (const category of this.storeData.categories) {
      if (category.name === name && category.id !== id) { this.savedMessage = '分类名称已存在'; return; }
    }
    let oldName: string = '';
    for (const category of this.storeData.categories) { if (category.id === id) { oldName = category.name; category.name = name; } }
    if (this.selectedCategory === oldName) { this.selectedCategory = name; }
    this.persistStoreData().then(() => { this.savedMessage = '分类已重命名'; }).catch(() => {
      for (const category of this.storeData.categories) { if (category.id === id) { category.name = oldName; } }
      if (this.selectedCategory === name) { this.selectedCategory = oldName; }
      this.savedMessage = '分类重命名保存失败';
    });
  }

  private confirmDeleteCategory(name: string): void {
    this.getUIContext().showAlertDialog({
      title: '删除分类',
      message: '删除“' + name + '”后，已有记录会转入其他分类。',
      buttons: [
        { value: '删除', action: () => { this.deleteCategory(name); } },
        { value: '取消', action: () => {} }
      ]
    });
  }

  private deleteCategory(name: string): void {
    const previousSelectedCategory: string = this.selectedCategory;
    let categoryId: string = '';
    for (const category of this.storeData.categories) {
      if (category.name === name) {
        categoryId = category.id;
      }
    }
    let otherId: string = '';
    for (const category of this.storeData.categories) {
      if (category.name === '其他') {
        otherId = category.id;
      }
    }
    if (categoryId.length === 0 || otherId.length === 0 || categoryId === otherId) {
      this.savedMessage = '其他分类不能删除';
      return;
    }
    const nextCategories: FenLiCategory[] = [];
    for (const category of this.storeData.categories) {
      if (category.id !== categoryId) {
        nextCategories.push(category);
      }
    }
    const nextTransactions: FenLiStoredTransaction[] = [];
    for (const item of this.storeData.transactions) {
      if (item.categoryId === categoryId) {
        const moved: FenLiStoredTransaction = {
          id: item.id,
          ledgerId: item.ledgerId,
          categoryId: otherId,
          amountCents: item.amountCents,
          note: item.note,
          occurredOn: item.occurredOn,
          createdAt: item.createdAt
        };
        nextTransactions.push(moved);
      } else {
        nextTransactions.push(item);
      }
    }
    const previous: FenLiStoreData = this.storeData;
    this.storeData = {
      schemaVersion: previous.schemaVersion,
      activeLedgerId: previous.activeLedgerId,
      ledgers: previous.ledgers,
      categories: nextCategories,
      transactions: nextTransactions,
      budget: previous.budget,
      reminder: previous.reminder
    };
    if (this.selectedCategory === name) {
      this.selectedCategory = '其他';
    }
    this.transactions = this.legacyTransactions(this.storeData);
    this.persistStoreData().then(() => {
      this.savedMessage = '已删除分类：' + name;
    }).catch(() => {
      this.storeData = previous;
      this.selectedCategory = previousSelectedCategory;
      this.transactions = this.legacyTransactions(previous);
      this.savedMessage = '分类删除保存失败';
    });
  }

  private budgetOptions(): string[] {
    return ['¥3,000 / 月', '¥5,000 / 月', '¥10,000 / 月', '¥15,000 / 月', '¥20,000 / 月'];
  }

  private showBudgetSettings(): void {
    const options: string[] = this.budgetOptions();
    this.getUIContext().showTextPickerDialog({
      range: options,
      selected: options.indexOf(this.budgetLabel),
      canLoop: false,
      onAccept: (value: TextPickerResult) => {
        const previousLabel: string = this.budgetLabel;
        const previousLimit: number = this.storeData.budget.monthlyLimitCents;
        this.budgetLabel = options[this.pickerIndex(value)] ?? this.budgetLabel;
        const numericLabel: string = this.budgetLabel.replace('¥', '').replace(' / 月', '').replace(',', '');
        this.storeData.budget.monthlyLimitCents = Math.round(Number(numericLabel) * 100);
        this.persistStoreData().then(() => { this.savedMessage = '预算已更新'; }).catch(() => {
          this.budgetLabel = previousLabel;
          this.storeData.budget.monthlyLimitCents = previousLimit;
          this.savedMessage = '预算保存失败';
        });
      }
    });
  }

  private showReminderSettings(): void {
    const options: string[] = ['关闭提醒', '每日 20:00', '每日 21:00', '每日 22:00', '每日 23:00'];
    this.getUIContext().showTextPickerDialog({
      range: options,
      selected: Math.max(0, options.indexOf(this.reminderLabel)),
      canLoop: false,
      onAccept: (value: TextPickerResult) => {
        this.reminderLabel = options[this.pickerIndex(value)] ?? this.reminderLabel;
        if (this.reminderLabel === '关闭提醒') {
          this.storeData.reminder.enabled = false;
          this.storeData.reminder.reminderId = -1;
        } else {
          const time: string[] = this.reminderLabel.replace('每日 ', '').split(':');
          this.storeData.reminder.enabled = true;
          this.storeData.reminder.hour = Number(time[0]);
          this.storeData.reminder.minute = Number(time[1]);
        }
        this.persistStoreData().catch(() => {
          this.savedMessage = '提醒设置保存失败';
        });
        this.applyReminderSettings();
      }
    });
  }

  private showExportSettings(): void {
    this.getUIContext().showActionSheet({
      title: '数据导出',
      message: '导出为 CSV，Excel 可直接打开',
      sheets: [
        {
          title: '导出 CSV',
          action: () => {
            this.writeCsvExport();
          }
        },
        {
          title: '导出 Excel',
          action: () => {
            this.writeCsvExport();
          }
        }
      ]
    });
  }

  private writeCsvExport(): void {
    const context: Context = getContext(this);
    const path: string = context.getApplicationContext().filesDir + '/fenli-' + fenliDateKey(new Date()) + '.csv';
    FenLiExport.writeCsv(path, this.storeData).then(() => {
      this.savedMessage = 'CSV 文件已生成';
      this.getUIContext().showAlertDialog({
        title: '导出完成',
        message: '已生成兼容 Excel 的 CSV 文件：\n' + path,
        buttons: [{ value: '知道了', action: () => {} }]
      });
    }).catch(() => {
      this.savedMessage = 'CSV 导出失败';
      this.getUIContext().showAlertDialog({
        title: '导出失败',
        message: '无法生成 CSV 文件，请稍后重试。',
        buttons: [{ value: '知道了', action: () => {} }]
      });
    });
  }

  private resetDemoData(): void {
    const previous: FenLiStoreData = this.storeData;
    this.storeData = createFenLiDemoData();
    this.currentBookLabel = this.activeLedgerName(this.storeData);
    this.budgetLabel = '¥' + (this.storeData.budget.monthlyLimitCents / 100).toFixed(0) + ' / 月';
    this.reminderLabel = '每日 ' + this.pad2(this.storeData.reminder.hour) + ':' + this.pad2(this.storeData.reminder.minute);
    this.transactions = this.legacyTransactions(this.storeData);
    this.persistStoreData().then(() => {
      this.savedMessage = '已恢复演示数据';
    }).catch(() => {
      this.storeData = previous;
      this.currentBookLabel = this.activeLedgerName(previous);
      this.budgetLabel = '¥' + (previous.budget.monthlyLimitCents / 100).toFixed(0) + ' / 月';
      this.reminderLabel = previous.reminder.enabled ? '每日 ' + this.pad2(previous.reminder.hour) + ':' + this.pad2(previous.reminder.minute) : '关闭提醒';
      this.transactions = this.legacyTransactions(previous);
      this.savedMessage = '演示数据保存失败';
    });
  }

  private showGeneralSettings(): void {
    this.getUIContext().showAlertDialog({
      title: '通用设置',
      message: '分厘 v1.0.0\n记录、账本和设置保存在本机。恢复演示数据会清除当前新增记录。',
      buttons: [
        {
          value: '恢复演示数据',
          action: () => {
            this.getUIContext().showAlertDialog({
              title: '再次确认',
              message: '恢复演示数据会覆盖当前账本、分类和流水，确定继续吗？',
              buttons: [{ value: '确定恢复', action: () => { this.resetDemoData(); } }, { value: '取消', action: () => {} }]
            });
          }
        },
        {
          value: '取消',
          action: () => {
          }
        }
      ]
    });
  }

  private showAbout(): void {
    this.getUIContext().showAlertDialog({
      title: '关于分厘',
      message: '分厘\n一款专注日常记录的轻量记账工具\n版本 v1.0.0',
      buttons: [{ value: '知道了', action: () => { } }]
    });
  }

  private showWeeklyAnalysis(): void {
    let highestAmount: number = 0;
    let highestDay: string = '暂无';
    for (let index: number = 0; index < 7; index++) {
      const amount: number = this.weekdayAmount(index);
      if (amount > highestAmount) {
        highestAmount = amount;
        const day: Date = this.weekStart(this.selectedDate);
        day.setDate(day.getDate() + index);
        highestDay = (day.getMonth() + 1) + '月' + day.getDate() + '日';
      }
    }
    this.getUIContext().showAlertDialog({
      title: '本周分析',
      message: '最高支出日：' + highestDay + '\n最高支出：¥' + highestAmount.toFixed(2) + '\n本周总额：¥' + this.weeklyTotal().toFixed(2),
      buttons: [{ value: '知道了', action: () => {} }]
    });
  }

  private handleProfileSetting(title: string): void {
    if (title === '账本管理') {
      this.showBookSettings();
    } else if (title === '分类管理') {
      this.showCategorySettings();
    } else if (title === '预算设置') {
      this.showBudgetSettings();
    } else if (title === '记账提醒') {
      this.showReminderSettings();
    } else if (title === '数据导出') {
      this.showExportSettings();
    } else if (title === '通用设置') {
      this.showGeneralSettings();
    } else if (title === '关于分厘') {
      this.showAbout();
    }
  }

  private switchTab(tabIndex: number): void {
    this.currentTab = tabIndex;
    this.tabsController.changeIndex(tabIndex);
  }

  private async saveTransaction(): Promise<void> {
    const amount: number = this.resolveAmount();
    if (!Number.isFinite(amount) || amount <= 0 || amount > 99999999) {
      this.savedMessage = '请输入有效金额';
      this.getUIContext().showAlertDialog({
        title: '金额无效',
        message: '请输入大于 0 且不超过 99,999,999 的金额。',
        buttons: [{ value: '知道了', action: () => {} }]
      });
      return;
    }
    const detail: string = this.noteText.length > 0 ? this.noteText : '手动记账';
    const amountCents: number = Math.round(amount * 100);
    const previous: FenLiStoreData = this.storeData;
    let nextTransactions: FenLiStoredTransaction[] = previous.transactions;
    if (this.editTransactionId.length > 0) {
      nextTransactions = previous.transactions.map((item: FenLiStoredTransaction): FenLiStoredTransaction => {
        if (item.id !== this.editTransactionId) {
          return item;
        }
        return {
          id: item.id,
          ledgerId: item.ledgerId,
          categoryId: this.activeCategoryId(),
          amountCents,
          note: detail,
          occurredOn: fenliDateKey(this.entryDate),
          createdAt: item.createdAt
        };
      });
    } else {
      const now: Date = new Date();
      const stored: FenLiStoredTransaction = {
        id: 'transaction-' + now.getTime() + '-' + previous.transactions.length,
        ledgerId: previous.activeLedgerId,
        categoryId: this.activeCategoryId(),
        amountCents,
        note: detail,
        occurredOn: fenliDateKey(this.entryDate),
        createdAt: fenliDateKey(now) + 'T' + this.currentTime() + ':00'
      };
      nextTransactions = previous.transactions.concat([stored]);
    }
    this.storeData = {
      schemaVersion: previous.schemaVersion,
      activeLedgerId: previous.activeLedgerId,
      ledgers: previous.ledgers,
      categories: previous.categories,
      transactions: nextTransactions,
      budget: previous.budget,
      reminder: previous.reminder
    };
    try {
      await this.persistStoreData();
    } catch (_error) {
      this.storeData = previous;
      this.savedMessage = '记录保存失败，请重试';
      return;
    }
    this.transactions = this.legacyTransactions(this.storeData);
    this.clearAmountOperation();
    this.selectedDate = new Date(this.entryDate.getFullYear(), this.entryDate.getMonth(), this.entryDate.getDate());
    this.savedMessage = (this.editTransactionId.length > 0 ? '记录已更新 · ' : '记录成功 · ') + this.selectedCategory;
    this.amountText = '0.00';
    this.noteText = '';
    this.entryDate = new Date();
    this.editTransactionId = '';
    this.selectedCategory = this.storeData.categories.length > 0 ? this.storeData.categories[0].name : '其他';
    this.switchTab(0);
  }

  @Builder
  private labelText(content: string): void {
    Text(content)
      .fontSize(10)
      .fontColor('#999999')
      .fontFamily('monospace')
      .letterSpacing(1.2)
  }

  @Builder
  private dailyPage(): void {
    Scroll() {
      Column() {
        Blank().height(54)
        Row() {
          this.labelText(this.weekdayLabel(this.selectedDate))
          this.brandMark()
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Row({ space: 15 }) {
          Text('‹').fontSize(28).fontColor('#999999').onClick(() => {
            this.changeDate(-1)
          })
          Text(this.dailyDateLabel()).fontSize(30).fontWeight(FontWeight.Bold).onClick(() => {
            this.openDailyDatePicker()
          })
          Text('›').fontSize(28).fontColor('#999999').onClick(() => {
            this.changeDate(1)
          })
          Blank().layoutWeight(1)
          this.labelText('' + this.selectedDate.getFullYear())
        }
        .width('100%')
        .margin({ top: 18, bottom: 22 })

        Divider().color('#E5E5E5')
        Column() {
          this.labelText("TODAY'S SPENDING")
          Row({ space: 3 }) {
            Text('¥').fontSize(18).fontColor('#999999').fontFamily('monospace')
            Text(this.dailyTotal().toFixed(2)).fontSize(54).fontColor('#111111').fontFamily('monospace').fontWeight(FontWeight.Medium)
          }
          Row({ space: 8 }) {
            Text(this.dailyTransactions().length + ' 笔支出').fontSize(10).fontColor('#999999').fontFamily('monospace').letterSpacing(1.2)
            Text('·').fontSize(12).fontColor('#999999')
            Text('较昨日 ' + this.comparisonText(this.dailyTotal(), this.totalFor(this.periodTransactions(this.shiftDays(-1), this.shiftDays(-1))))).fontSize(10).fontColor('#7FA800').fontFamily('monospace').letterSpacing(1)
          }
          if (this.savedMessage.length > 0) {
            Text(this.savedMessage).fontSize(11).fontColor('#7FA800').margin({ top: 8 })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 26, bottom: 26 })

        Divider().color('#E5E5E5')
           Row() {
             this.labelText('TRANSACTIONS')
             Blank().layoutWeight(1)
           Text('NO. 01–' + this.pad2(this.dailyTransactions().length)).fontSize(10).fontColor('#999999').fontFamily('monospace').letterSpacing(1.2)
         }
        .width('100%')
        .margin({ top: 22, bottom: 2 })

          ForEach(this.dailyTransactions(), (item: FenLiTransaction) => {
            this.transactionRow(item.id, item.number, item.title, item.category, item.detail, item.amount, item.time)
         }, (item: FenLiTransaction) => item.number)
      }
      .alignItems(HorizontalAlign.Start)
        .padding({ left: 32, right: 32, top: 8, bottom: 24 })
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  private transactionRow(id: string, number: string, title: string, category: string, detail: string, amount: number, time: string): void {
    Column() {
      Row() {
        Column() {
          Row({ space: 8 }) {
            Text(number).fontSize(11).fontColor('#999999').fontFamily('monospace')
            Text(title).fontSize(14).fontWeight(FontWeight.Medium)
            Text(category).fontSize(11).fontColor('#999999')
          }
          Text(detail).fontSize(11).fontColor('#999999').margin({ top: 5, left: 20 })
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)
        Column() {
          Text('−' + amount.toFixed(2)).fontSize(17).fontColor('#111111').fontFamily('monospace')
          Text(time).fontSize(10).fontColor('#999999').fontFamily('monospace').margin({ top: 5 })
        }
        .alignItems(HorizontalAlign.End)
      }
      .width('100%')
      .padding({ top: 14, bottom: 14 })
      .onClick(() => {
        this.openTransactionDetail({ id, number, title, category, detail, amount, time, date: fenliDateKey(this.selectedDate) });
      })
      Divider().color('#E5E5E5')
    }
    .width('100%')
  }

  @Builder
  private weeklyPage(): void {
    Scroll() {
      Column() {
        Blank().height(54)
        Row() {
           this.labelText(this.weekLabel())
           this.brandMark()
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ bottom: 25 })
         Row({ space: 14 }) {
           Text('‹').fontSize(24).fontColor('#999999').onClick(() => {
             this.changeWeek(-1)
           })
           Text(this.dateRangeLabel(this.weekStart(this.selectedDate), this.weekEnd(this.selectedDate))).fontSize(25).fontWeight(FontWeight.Bold).onClick(() => {
             this.openWeekPicker()
           })
           Text('›').fontSize(24).fontColor('#999999').onClick(() => {
             this.changeWeek(1)
           })
         }
         Column() {
           this.labelText('WEEKLY TOTAL')
            Text('¥ ' + this.weeklyTotal().toFixed(2)).fontSize(52).fontFamily('monospace').fontWeight(FontWeight.Medium).margin({ top: 10, bottom: 8 })
            Text('日均 ¥' + this.weeklyAverage()).fontSize(11).fontColor('#999999').fontFamily('monospace')
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 28, bottom: 24 })
        Divider().color('#E5E5E5')
        Row() {
           this.labelText('COMPARISON')
           Blank().layoutWeight(1)
           Button('查看分析')
             .height(30)
             .fontSize(10)
             .fontColor('#111111')
             .backgroundColor('#FFFFFF')
             .borderWidth(1)
            .borderColor('#111111')
            .borderRadius(0)
              .onClick(() => {
                this.showWeeklyAnalysis();
              })
        }
        .width('100%')
        .margin({ top: 24, bottom: 18 })
          this.comparisonRow('对比上周', this.comparisonText(this.weeklyTotal(), this.previousWeekTotal()), '#111111')
          this.comparisonRow('对比两周前', this.comparisonText(this.weeklyTotal(), this.twoWeeksAgoTotal()), '#888888')
           this.comparisonRow('对比上月同周（同日所在 ISO 周）', this.comparisonText(this.weeklyTotal(), this.previousMonthWeekTotal()), '#888888')
        Divider().color('#E5E5E5').margin({ top: 18 })
        Row() {
           this.labelText('7-DAY TREND')
           Blank().layoutWeight(1)
            this.labelText('¥ ' + this.weeklyTotal().toFixed(2))
        }
        .width('100%')
        .margin({ top: 22, bottom: 18 })
         Row({ space: 7 }) {
            this.trendBar('一', this.trendHeight(this.weekdayAmount(0)), this.weekdayIndex() === 0)
            this.trendBar('二', this.trendHeight(this.weekdayAmount(1)), this.weekdayIndex() === 1)
            this.trendBar('三', this.trendHeight(this.weekdayAmount(2)), this.weekdayIndex() === 2)
            this.trendBar('四', this.trendHeight(this.weekdayAmount(3)), this.weekdayIndex() === 3)
            this.trendBar('五', this.trendHeight(this.weekdayAmount(4)), this.weekdayIndex() === 4)
            this.trendBar('六', this.trendHeight(this.weekdayAmount(5)), this.weekdayIndex() === 5)
            this.trendBar('日', this.trendHeight(this.weekdayAmount(6)), this.weekdayIndex() === 6)
         }
        .width('100%')
        .alignItems(VerticalAlign.Bottom)
        .height(150)
      }
      .alignItems(HorizontalAlign.Start)
        .padding({ left: 32, right: 32, top: 8, bottom: 24 })
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  private comparisonRow(label: string, value: string, color: ResourceColor): void {
    Row() {
      Text(label).fontSize(12).fontColor('#999999')
      Blank().layoutWeight(1)
      Text(value).fontSize(20).fontFamily('monospace').fontColor(color)
    }
    .width('100%')
    .padding({ top: 11, bottom: 11 })
  }

  @Builder
  private trendBar(label: string, barHeight: number, active: boolean): void {
    Column() {
      Blank().height(barHeight).width(20).backgroundColor(active ? '#CCFF00' : '#E5E5E5')
      Text(label).fontSize(10).fontColor(active ? '#111111' : '#999999').margin({ top: 8 })
    }
    .justifyContent(FlexAlign.End)
    .layoutWeight(1)
  }

  @Builder
  private monthlyPage(): void {
    Scroll() {
      Column() {
        Blank().height(54)
        Row() {
          this.labelText('' + this.selectedDate.getFullYear())
          this.brandMark()
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
         Row({ space: 14 }) {
           Text('‹').fontSize(24).fontColor('#999999').onClick(() => {
             this.changeMonth(-1)
           })
           Text(this.monthLabel()).fontSize(30).fontWeight(FontWeight.Bold).onClick(() => {
             this.openMonthPicker()
           })
           Text('›').fontSize(24).fontColor('#999999').onClick(() => {
             this.changeMonth(1)
           })
         }
        .margin({ top: 16 })
         Column() {
           this.labelText('MONTHLY TOTAL')
            Text('¥ ' + this.monthlyTotal().toFixed(2)).fontSize(52).fontFamily('monospace').fontWeight(FontWeight.Medium).margin({ top: 10, bottom: 8 })
             Text(this.monthTransactions().length + ' 笔支出  ·  日均 ¥' + this.monthlyAverage()).fontSize(10).fontColor('#999999').fontFamily('monospace')
             Text('本月预算 ¥' + (this.storeData.budget.monthlyLimitCents / 100).toFixed(2) + '  ·  已用 ¥' + (this.budgetUsedCents() / 100).toFixed(2) + '  ·  ' + this.budgetStatusLabel()).fontSize(11).fontColor(this.budgetRemainingCents() < 0 ? '#C85D6D' : '#7FA800').margin({ top: 10 })
        }
        .alignItems(HorizontalAlign.Start)
        .width('100%')
        .padding({ top: 28, bottom: 24 })
        Divider().color('#E5E5E5')
        Row() {
          this.labelText('CATEGORY BREAKDOWN')
          Blank().layoutWeight(1)
          this.labelText('100%')
        }
        .width('100%')
        .margin({ top: 24, bottom: 15 })
          ForEach(this.storeData.categories, (category: FenLiCategory) => {
            this.categoryRow(category.name, this.categoryAmount(category.name).toFixed(2), this.categoryRatioLabel(category.name), this.categoryRatio(category.name), this.categoryAmount(category.name) > 0)
          }, (category: FenLiCategory) => category.id)
      }
      .alignItems(HorizontalAlign.Start)
        .padding({ left: 32, right: 32, top: 8, bottom: 24 })
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  private categoryRow(name: string, amount: string, ratio: string, widthRatio: number, active: boolean): void {
    Column() {
      Row() {
        Text(name).fontSize(13).fontWeight(active ? FontWeight.Medium : FontWeight.Normal)
        Blank().layoutWeight(1)
        Text(amount).fontSize(13).fontFamily('monospace')
        Text(ratio).fontSize(10).fontColor('#999999').margin({ left: 10 })
      }
      .width('100%')
      Row() {
        Blank().width(widthRatio + '%').height(5).backgroundColor(active ? '#CCFF00' : '#DADADA')
        Blank().layoutWeight(1).height(5).backgroundColor('#F3F3F1')
      }
      .width('100%')
      .margin({ top: 9, bottom: 15 })
    }
    .width('100%')
  }

  @Builder
  private addPage(): void {
    Scroll() {
      Column() {
        Blank().height(54)
        Row() {
            Text('取消')
            .fontSize(14)
            .fontColor('#999999')
            .onClick(() => {
              this.cancelEntry();
            })
          Column({ space: 4 }) {
            Row({ space: 5 }) {
              Blank().width(5).height(5).borderRadius(3).backgroundColor('#CCFF00')
              this.labelText('记一笔')
            }
          }
          Button('保存')
            .height(34)
            .fontSize(13)
            .fontColor('#FFFFFF')
            .backgroundColor('#111111')
            .borderRadius(0)
            .padding({ left: 16, right: 16 })
            .onClick(() => {
              this.saveTransaction()
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)

        Divider().color('#E5E5E5').margin({ top: 16 })

        Column() {
          this.labelText('AMOUNT')
          Row({ space: 5 }) {
            Text('¥').fontSize(24).fontColor('#999999').fontFamily('monospace')
            TextInput({ placeholder: '0.00', text: this.amountText })
              .width(220)
              .height(76)
              .fontSize(54)
              .fontFamily('monospace')
              .fontWeight(FontWeight.Medium)
              .fontColor('#111111')
              .textAlign(TextAlign.Start)
              .type(InputType.NUMBER_DECIMAL)
              .maxLength(8)
              .inputFilter('^[0-9]*[.]?[0-9]{0,2}$')
              .showUnderline(false)
              .backgroundColor('#FFFFFF')
              .onChange((value: string) => {
                this.updateAmountText(value);
              })
          }
          Blank().width(64).height(2).backgroundColor('#CCFF00')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
        .padding({ top: 34, bottom: 32 })

        Divider().color('#E5E5E5')

        Column() {
          this.labelText('CATEGORY')
           Flex({ wrap: FlexWrap.Wrap }) {
             ForEach(this.storeData.categories, (category: FenLiCategory) => {
               this.categoryChip(category.name)
             }, (category: FenLiCategory) => category.id)
           }
           .width('100%')
           .margin({ top: 16, bottom: 12 })
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })

        Divider().color('#E5E5E5')

        Column() {
          Row() {
            Text('日期').fontSize(14).fontColor('#999999')
            Blank().layoutWeight(1)
             Text(this.shortDateLabel(this.entryDate)).fontSize(14).fontColor('#111111').fontFamily('monospace')
             Text('›').fontSize(20).fontColor('#999999').margin({ left: 8 })
           }
           .width('100%')
           .padding({ top: 12, bottom: 12 })
           .onClick(() => {
             this.openEntryDatePicker();
           })
          Divider().color('#E5E5E5')
          Row() {
            Text('备注').fontSize(14).fontColor('#999999')
            Blank().layoutWeight(1)
            TextInput({ placeholder: '添加备注', text: this.noteText })
              .width(170)
              .height(36)
              .fontSize(14)
              .fontColor('#111111')
              .textAlign(TextAlign.End)
              .showUnderline(false)
              .backgroundColor('#FFFFFF')
              .onChange((value: string) => {
                this.noteText = value
              })
            Text('›').fontSize(20).fontColor('#999999').margin({ left: 8 })
          }
          .width('100%')
          .padding({ top: 12, bottom: 12 })
        }
        .width('100%')
        .padding({ top: 8, bottom: 8 })

        Divider().color('#E5E5E5')

        Column() {
          this.labelText('KEYPAD')
          Row() {
            this.keypadButton('7')
            this.keypadButton('8')
            this.keypadButton('9')
            this.keypadButton('⌫')
          }
          Row() {
            this.keypadButton('4')
            this.keypadButton('5')
            this.keypadButton('6')
            this.keypadButton('+')
          }
          Row() {
            this.keypadButton('1')
            this.keypadButton('2')
            this.keypadButton('3')
            this.keypadButton('−')
          }
          Row() {
            this.keypadButton('0')
            this.keypadButton('00')
            this.keypadButton('.')
            this.keypadButton('确定')
          }
        }
        .width('100%')
        .padding({ top: 16, bottom: 24 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 32, right: 32, top: 8, bottom: 24 })
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  private categoryChip(category: string): void {
    Button(category)
      .height(44)
      .layoutWeight(1)
      .fontSize(12)
      .fontColor(this.selectedCategory === category ? '#FFFFFF' : '#111111')
      .backgroundColor(this.selectedCategory === category ? '#111111' : '#FFFFFF')
      .borderRadius(0)
      .borderWidth(1)
      .borderColor(this.selectedCategory === category ? '#111111' : '#E5E5E5')
      .stateEffect(false)
      .visibility(this.hasCategory(category) ? Visibility.Visible : Visibility.Hidden)
      .onClick(() => {
        this.chooseCategory(category)
      })
  }

  @Builder
  private keypadButton(key: string): void {
    Button(key)
      .layoutWeight(1)
      .height(58)
      .fontSize(key === '确定' ? 14 : 22)
      .fontColor(key === '确定' ? '#111111' : (key === '+' || key === '−' || key === '⌫' ? '#999999' : '#111111'))
      .backgroundColor(key === '确定' ? '#CCFF00' : '#FFFFFF')
      .borderRadius(0)
      .borderWidth(1)
      .borderColor('#E5E5E5')
      .stateEffect(true)
      .onClick(() => {
        if (key === '⌫') {
          this.removeDigit()
        } else if (key === '确定') {
          this.saveTransaction()
        } else if (key === '+' || key === '−') {
          this.chooseAmountOperator(key)
        } else if (key !== '+' && key !== '−' && key !== '00') {
          this.appendDigit(key)
        } else if (key === '00') {
          this.appendDigit('0')
          this.appendDigit('0')
        }
      })
  }

  @Builder
  private profilePage(): void {
    Scroll() {
      Column() {
        Blank().height(54)
        Row() {
          this.labelText('PROFILE')
          this.brandMark()
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ top: 8, bottom: 24 })

        Divider().color('#E5E5E5')

        Column() {
          Row({ space: 20 }) {
            Text('L.')
              .width(64)
              .height(64)
              .fontSize(22)
              .fontColor('#FFFFFF')
              .fontFamily('monospace')
              .textAlign(TextAlign.Center)
              .backgroundColor('#111111')
            Column() {
              Text('林小语').fontSize(21).fontWeight(FontWeight.Bold)
              Text('已记账 ' + this.recordedDays() + ' 天').fontSize(13).fontColor('#999999').margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          Row() {
              this.profileStat('本月支出', '¥' + this.currentMonthTotal().toFixed(2))
            Blank().width(1).height(40).backgroundColor('#E5E5E5')
              this.profileStat('本月笔数', '' + this.currentMonthTransactions().length)
            Blank().width(1).height(40).backgroundColor('#E5E5E5')
              this.profileStat('日均', '¥' + this.currentMonthAverage())
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ top: 24 })
        }
        .width('100%')
        .padding({ top: 28, bottom: 28 })

        Divider().color('#E5E5E5')

        Column() {
           this.labelText('SETTINGS')
           this.profileSettingRow($r('app.media.settings_book'), '账本管理', this.currentBookLabel)
            this.profileSettingRow($r('app.media.settings_category'), '分类管理', this.storeData.categories.length + ' 个分类')
           this.profileSettingRow($r('app.media.settings_budget'), '预算设置', this.budgetLabel)
           this.profileSettingRow($r('app.media.settings_reminder'), '记账提醒', this.reminderLabel)
          this.profileSettingRow($r('app.media.settings_export'), '数据导出', 'CSV / Excel')
          this.profileSettingRow($r('app.media.settings_settings'), '通用设置', '')
          this.profileSettingRow($r('app.media.settings_info'), '关于分厘', 'v1.0.0')
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })
      }
      .alignItems(HorizontalAlign.Start)
      .padding({ left: 32, right: 32, top: 8, bottom: 24 })
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  private profileStat(title: string, amount: string): void {
    Column({ space: 5 }) {
      this.labelText(title)
      Text(amount).fontSize(22).fontColor('#111111').fontFamily('monospace')
    }
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private profileSettingRow(icon: Resource, title: string, detail: string): void {
    Column() {
      Row() {
        Row({ space: 12 }) {
          Image(icon)
            .width(20)
            .height(20)
            .objectFit(ImageFit.Contain)
          Text(title).fontSize(14).fontColor('#111111')
        }
        .layoutWeight(1)
        Row({ space: 8 }) {
          Text(detail)
            .fontSize(11)
            .fontColor('#999999')
            .fontFamily('monospace')
            .visibility(detail.length > 0 ? Visibility.Visible : Visibility.Hidden)
          Text('›').fontSize(20).fontColor('#CCCCCC')
        }
      }
      .width('100%')
      .padding({ top: 15, bottom: 15 })
      .onClick(() => {
        this.handleProfileSetting(title);
      })
      Divider().color('#E5E5E5')
    }
    .width('100%')
  }

  @Builder
  private brandMark(): void {
    Row({ space: 5 }) {
      Image($r('app.media.fenli_mark'))
        .width(14)
        .height(14)
        .objectFit(ImageFit.Contain)
      Text('分厘')
        .fontSize(11)
        .fontColor('#111111')
        .fontFamily('monospace')
        .letterSpacing(0.5)
    }
  }

  @Builder
  private navTab(icon: Resource, title: string, tabIndex: number): void {
    Column({ space: 4 }) {
      Image(icon)
        .width(18)
        .height(18)
        .objectFit(ImageFit.Contain)
        .opacity(this.currentTab === tabIndex ? 1 : 0.35)
      Text(title)
        .fontSize(10)
        .fontColor(this.currentTab === tabIndex ? '#111111' : '#BBBBBB')
        .fontWeight(this.currentTab === tabIndex ? FontWeight.Medium : FontWeight.Normal)
      Blank()
        .width(4)
        .height(4)
        .borderRadius(2)
        .backgroundColor('#CCFF00')
        .visibility(this.currentTab === tabIndex ? Visibility.Visible : Visibility.Hidden)
    }
    .width(60)
    .height(56)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.switchTab(tabIndex)
    })
  }

  @Builder
  private addNavTab(): void {
    Column() {
      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.nav_add'))
          .width(18)
          .height(18)
          .objectFit(ImageFit.Contain)
      }
        .width(40)
        .height(40)
        .backgroundColor('#CCFF00')
    }
    .width(60)
    .height(56)
    .alignItems(HorizontalAlign.Center)
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.switchTab(2)
    })
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTab, controller: this.tabsController }) {
      TabContent() {
        this.dailyPage()
      }
      .tabBar(this.navTab($r('app.media.nav_daily'), '每日', 0))
      TabContent() {
        this.weeklyPage()
      }
      .tabBar(this.navTab($r('app.media.nav_weekly'), '每周', 1))
      TabContent() {
        this.addPage()
      }
      .tabBar(this.addNavTab())
      TabContent() {
        this.monthlyPage()
      }
      .tabBar(this.navTab($r('app.media.nav_monthly'), '每月', 3))
      TabContent() {
        this.profilePage()
      }
      .tabBar(this.navTab($r('app.media.nav_profile'), '我的', 4))
    }
    .barHeight(72)
    .barMode(BarMode.Fixed)
    .animationDuration(250)
    .onChange((index: number) => {
      this.currentTab = index
    })
    .backgroundColor('#FFFFFF')
    .width('100%')
    .height('100%')
  }
}
