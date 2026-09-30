/*
 * Copyright (c) 2026 Huawei Device Co., Ltd.
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
import { FenLiStorage } from '../service/FenLiStorage';

const DOMAIN = 0x0000;

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup(): Promise<void> {
    await FenLiStorage.load(this.context);
    hilog.info(DOMAIN, 'FenLiBackup', 'onBackup snapshot prepared');
  }

  async onRestore(bundleVersion: BundleVersion): Promise<void> {
    const restoredData = await FenLiStorage.load(this.context);
    await FenLiStorage.save(this.context, restoredData);
    hilog.info(DOMAIN, 'FenLiBackup', 'onRestore snapshot restored for version %{public}d', bundleVersion.code);
  }
}
