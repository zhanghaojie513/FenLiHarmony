interface FenLiTransaction {
  number: string;
  title: string;
  category: string;
  detail: string;
  amount: number;
  time: string;
  date: string;
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
  @State transactions: FenLiTransaction[] = [
    { number: '01', title: '午餐', category: '餐饮', detail: '公司楼下沙拉轻食', amount: 42.00, time: '12:35', date: fenliDateKey(new Date()) },
    { number: '02', title: '咖啡', category: '餐饮', detail: 'Manner 冰美式', amount: 15.00, time: '09:20', date: fenliDateKey(new Date()) },
    { number: '03', title: '地铁', category: '交通', detail: '通勤往返', amount: 8.00, time: '08:15', date: fenliDateKey(new Date()) },
    { number: '04', title: '书籍', category: '学习', detail: '《设计心理学》', amount: 68.00, time: '14:50', date: fenliDateKey(new Date()) },
    { number: '05', title: '晚餐', category: '餐饮', detail: '海底捞（与朋友聚餐 AA）', amount: 156.50, time: '19:10', date: fenliDateKey(new Date()) },
    { number: '06', title: '水果', category: '日用', detail: '百果园 车厘子', amount: 558.00, time: '20:30', date: fenliDateKey(new Date()) }
  ];

  private dailyTotal(): number {
    let sum: number = 0;
    const key: string = fenliDateKey(this.selectedDate);
    for (const item of this.transactions) {
      if (item.date === key) {
        sum += item.amount;
      }
    }
    return sum;
  }

  private dailyTransactions(): FenLiTransaction[] {
    const result: FenLiTransaction[] = [];
    const key: string = fenliDateKey(this.selectedDate);
    for (const item of this.transactions) {
      if (item.date === key) {
        result.push(item);
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
    let sum: number = 0;
    for (const item of items) {
      sum += item.amount;
    }
    return sum;
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
    const yearStart: Date = new Date(this.selectedDate.getFullYear(), 0, 1);
    const firstMondayDistance: number = yearStart.getDay() === 0 ? 6 : yearStart.getDay() - 1;
    const firstMonday: Date = new Date(this.selectedDate.getFullYear(), 0, 1 - firstMondayDistance);
    const difference: number = this.weekStart(this.selectedDate).getTime() - firstMonday.getTime();
    return Math.floor(difference / 604800000) + 1;
  }

  private weekLabel(): string {
    return '' + this.selectedDate.getFullYear() + ' · 第 ' + this.weekNumber() + ' 周';
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
    return (this.monthlyTotal() / this.selectedDate.getDate()).toFixed(2);
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
    let sum: number = 0;
    for (const item of this.monthTransactions()) {
      if (item.category === category) {
        sum += item.amount;
      }
    }
    return sum;
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
    this.getUIContext().showActionSheet({
      title: '账本管理',
      message: '选择账本显示名称',
      sheets: [
        {
          title: '默认账本',
          action: () => {
            this.currentBookLabel = '默认账本';
            this.savedMessage = '已切换到默认账本';
          }
        },
        {
          title: '个人账本',
          action: () => {
            this.currentBookLabel = '个人账本';
            this.savedMessage = '已切换到个人账本';
          }
        }
      ]
    });
  }

  private showCategorySettings(): void {
    this.getUIContext().showAlertDialog({
      title: '分类管理',
      message: '当前分类\n餐饮 · 交通 · 购物 · 娱乐\n日用 · 学习 · 医疗 · 其他',
      buttons: [
        {
          value: '知道了',
          action: () => {
            this.savedMessage = '分类共 8 个';
          }
        }
      ]
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
        this.budgetLabel = options[this.pickerIndex(value)] ?? this.budgetLabel;
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
      }
    });
  }

  private showExportSettings(): void {
    this.getUIContext().showActionSheet({
      title: '数据导出',
      message: '文件导出功能暂不可用',
      sheets: [
        {
          title: '导出 CSV',
          action: () => {
            this.getUIContext().showAlertDialog({
              title: 'CSV 导出',
               message: 'CSV 文件导出暂不可用，当前未生成文件。',
               buttons: [{ value: '知道了', action: () => {} }]
            });
          }
        },
        {
          title: '导出 Excel',
          action: () => {
            this.getUIContext().showAlertDialog({
              title: 'Excel 导出',
               message: 'Excel 文件导出暂不可用，当前未生成文件。',
               buttons: [{ value: '知道了', action: () => {} }]
            });
          }
        }
      ]
    });
  }

  private resetDemoData(): void {
    this.transactions = [
      { number: '01', title: '午餐', category: '餐饮', detail: '公司楼下沙拉轻食', amount: 42.00, time: '12:35', date: fenliDateKey(new Date()) },
      { number: '02', title: '咖啡', category: '餐饮', detail: 'Manner 冰美式', amount: 15.00, time: '09:20', date: fenliDateKey(new Date()) },
      { number: '03', title: '地铁', category: '交通', detail: '通勤往返', amount: 8.00, time: '08:15', date: fenliDateKey(new Date()) },
      { number: '04', title: '书籍', category: '学习', detail: '《设计心理学》', amount: 68.00, time: '14:50', date: fenliDateKey(new Date()) },
      { number: '05', title: '晚餐', category: '餐饮', detail: '海底捞（与朋友聚餐 AA）', amount: 156.50, time: '19:10', date: fenliDateKey(new Date()) },
      { number: '06', title: '水果', category: '日用', detail: '百果园 车厘子', amount: 558.00, time: '20:30', date: fenliDateKey(new Date()) }
    ];
    this.savedMessage = '已恢复演示数据';
  }

  private showGeneralSettings(): void {
    this.getUIContext().showAlertDialog({
      title: '通用设置',
      message: '分厘 v1.0.0\n当前记录仅保存在本次运行中，重启后会重置。恢复演示数据会清除当前新增记录。',
      buttons: [
        {
          value: '恢复演示数据',
          action: () => {
            this.resetDemoData();
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

  private saveTransaction(): void {
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
    this.clearAmountOperation();
    const nextNumber: string = this.pad2(this.transactions.length + 1);
    const detail: string = this.noteText.length > 0 ? this.noteText : '手动记账';
    const nextTransaction: FenLiTransaction = {
      number: nextNumber,
      title: this.selectedCategory,
      category: this.selectedCategory,
      detail: detail,
      amount: amount,
      time: this.currentTime(),
      date: fenliDateKey(this.entryDate)
    };
    this.transactions = this.transactions.concat([nextTransaction]);
    this.selectedDate = new Date(this.entryDate.getFullYear(), this.entryDate.getMonth(), this.entryDate.getDate());
    this.savedMessage = '记录成功 · ' + this.selectedCategory;
    this.amountText = '0.00';
    this.noteText = '';
    this.entryDate = new Date();
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
           this.transactionRow(item.number, item.title, item.category, item.detail, item.amount, item.time)
         }, (item: FenLiTransaction) => item.number)
      }
      .alignItems(HorizontalAlign.Start)
        .padding({ left: 32, right: 32, top: 8, bottom: 24 })
    }
    .scrollBar(BarState.Off)
  }

  @Builder
  private transactionRow(number: string, title: string, category: string, detail: string, amount: number, time: string): void {
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
        }
        .width('100%')
        .margin({ top: 24, bottom: 18 })
          this.comparisonRow('对比上周', this.comparisonText(this.weeklyTotal(), this.previousWeekTotal()), '#111111')
          this.comparisonRow('对比两周前', this.comparisonText(this.weeklyTotal(), this.twoWeeksAgoTotal()), '#888888')
          this.comparisonRow('对比上月同周', this.comparisonText(this.weeklyTotal(), this.previousMonthWeekTotal()), '#888888')
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
           Text('已过 ' + this.selectedDate.getDate() + ' 天  ·  ' + this.monthTransactions().length + ' 笔支出  ·  日均 ¥' + this.monthlyAverage()).fontSize(10).fontColor('#999999').fontFamily('monospace')
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
         this.categoryRow('餐饮', this.categoryAmount('餐饮').toFixed(2), this.categoryRatioLabel('餐饮'), this.categoryRatio('餐饮'), this.categoryAmount('餐饮') > 0)
         this.categoryRow('购物', this.categoryAmount('购物').toFixed(2), this.categoryRatioLabel('购物'), this.categoryRatio('购物'), this.categoryAmount('购物') > 0)
         this.categoryRow('交通', this.categoryAmount('交通').toFixed(2), this.categoryRatioLabel('交通'), this.categoryRatio('交通'), this.categoryAmount('交通') > 0)
         this.categoryRow('娱乐', this.categoryAmount('娱乐').toFixed(2), this.categoryRatioLabel('娱乐'), this.categoryRatio('娱乐'), this.categoryAmount('娱乐') > 0)
         this.categoryRow('学习', this.categoryAmount('学习').toFixed(2), this.categoryRatioLabel('学习'), this.categoryRatio('学习'), this.categoryAmount('学习') > 0)
         this.categoryRow('日用', this.categoryAmount('日用').toFixed(2), this.categoryRatioLabel('日用'), this.categoryRatio('日用'), this.categoryAmount('日用') > 0)
         this.categoryRow('其他', this.categoryAmount('其他').toFixed(2), this.categoryRatioLabel('其他'), this.categoryRatio('其他'), this.categoryAmount('其他') > 0)
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
              this.amountText = '0.00'
              this.clearAmountOperation();
              this.noteText = '';
              this.entryDate = new Date();
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
          Row({ space: 8 }) {
            this.categoryChip('餐饮')
            this.categoryChip('交通')
            this.categoryChip('购物')
            this.categoryChip('娱乐')
          }
          .width('100%')
          .margin({ top: 16, bottom: 12 })
          Row({ space: 8 }) {
            this.categoryChip('日用')
            this.categoryChip('学习')
            this.categoryChip('医疗')
            this.categoryChip('其他')
          }
          .width('100%')
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
              Text('已记账 128 天').fontSize(13).fontColor('#999999').margin({ top: 6 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          Row() {
            this.profileStat('本月支出', '¥12,680')
            Blank().width(1).height(40).backgroundColor('#E5E5E5')
            this.profileStat('本月笔数', '86')
            Blank().width(1).height(40).backgroundColor('#E5E5E5')
            this.profileStat('日均', '¥793')
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
           this.profileSettingRow($r('app.media.settings_category'), '分类管理', '8 个分类')
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
