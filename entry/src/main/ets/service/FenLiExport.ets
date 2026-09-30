import { fileIo } from '@kit.CoreFileKit';
import {
  FenLiLedger,
  FenLiStoreData,
  FenLiTransaction
} from '../model/FenLiModels';

const CSV_HEADER: string = 'ledger_id,ledger_name,currency,transaction_id,category_id,amount_cents,note,occurred_on,created_at';

function csvCell(value: string): string {
  const escaped: string = value.replace(/"/g, '""');
  return '"' + escaped + '"';
}

function ledgerFor(data: FenLiStoreData, ledgerId: string): FenLiLedger {
  const fallback: FenLiLedger = {
    id: ledgerId,
    name: '',
    currencyCode: '',
    createdAt: ''
  };
  const found: FenLiLedger | undefined = data.ledgers.find((item: FenLiLedger): boolean => item.id === ledgerId);
  return found ?? fallback;
}

function transactionRow(data: FenLiStoreData, item: FenLiTransaction): string {
  const ledger: FenLiLedger = ledgerFor(data, item.ledgerId);
  return [
    csvCell(ledger.id),
    csvCell(ledger.name),
    csvCell(ledger.currencyCode),
    csvCell(item.id),
    csvCell(item.categoryId),
    String(item.amountCents),
    csvCell(item.note),
    csvCell(item.occurredOn),
    csvCell(item.createdAt)
  ].join(',');
}

export class FenLiExport {
  public static toCsv(data: FenLiStoreData): string {
    const rows: string[] = [CSV_HEADER];
    data.transactions.forEach((item: FenLiTransaction): void => {
      if (item.ledgerId === data.activeLedgerId) {
        rows.push(transactionRow(data, item));
      }
    });
    return rows.join('\r\n') + '\r\n';
  }

  public static async writeCsv(path: string, data: FenLiStoreData): Promise<number> {
    const file: fileIo.File = await fileIo.open(path, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC);
    try {
      return await fileIo.write(file.fd, FenLiExport.toCsv(data));
    } finally {
      await fileIo.close(file);
    }
  }
}
