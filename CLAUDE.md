# Claude Code AI Agent 設定

## 語音通知系統

### 通知模式設定

你現在擁有語音通知功能，請根據以下規則進行操作：

#### 預設模式（完整通知）
- 在執行每個重要操作前，使用語音通知用戶當前正在進行的動作
- 完成任務後，提供完成狀態的語音摘要
- 使用自然的中文語音通知，例如："正在分析代碼結構"、"開始執行測試"、"任務已完成"

#### 語音模式切換
當用戶輸入以下指令時，調整通知模式：

1. **精簡模式**：用戶輸入「語音模式：精簡」
   - 只在任務完成時提供語音通知
   - 不在過程中進行語音提示

2. **安靜模式**：用戶輸入「安靜」
   - 完全停止所有語音通知
   - 只進行文字回應

3. **恢復預設模式**：用戶輸入「語音模式：預設」或「語音模式：完整」
   - 恢復完整的語音通知功能

### 語音通知實作規則

1. **任務完成時**：使用 `bash notifications/task_complete_notify.sh "完成訊息"`
2. **遇到問題時**：使用 `bash notifications/task_complete_notify.sh "問題描述"`
3. **需要決策確認時**：通過 Notification Hook 自動觸發 `notifications/decision_notify.sh`（隨機播放「Sam，請確認一下」等訊息）
4. **一般語音通知**：使用 `bash notifications/speak_message.sh "任意訊息"`

### 跨平台語音通知函數

建立 `notifications/speak_message.sh` 腳本來處理跨平台語音：

```bash
#!/bin/bash
message="$1"

# Windows (PowerShell)
if command -v powershell &> /dev/null; then
    powershell -Command "Add-Type -AssemblyName System.Speech; (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('$message')"
# macOS
elif command -v say &> /dev/null; then
    say "$message"
# Linux (需要安裝 espeak)
elif command -v espeak &> /dev/null; then
    espeak "$message"
# 如果都沒有，使用系統提示音
else
    echo -e "\a"
    echo "$message"
fi
```

### 語音通知範例

```bash
# 任務完成通知
bash notifications/task_complete_notify.sh "代碼分析完成，發現3個需要優化的地方"

# 遇到問題通知
bash notifications/task_complete_notify.sh "編譯失敗，請檢查語法錯誤"

# 一般語音通知
bash notifications/speak_message.sh "正在分析專案架構"

# 決策確認（由 Notification Hook 自動觸發）
# 會隨機播放：「Sam，請確認一下」、「Sam，需要你決定」等
```

### 通知類型說明

1. **notifications/decision_notify.sh** - 決策確認通知
   - 用於需要用戶決策的情況
   - 隨機播放確認訊息
   - 通知標題：「Claude Code - 需要確認」
   - 圖示：問號 ❓

2. **notifications/task_complete_notify.sh** - 任務完成通知
   - 用於任務完成或問題回報
   - 播放傳入的具體訊息
   - 通知標題：「Claude Code - 任務完成」
   - 圖示：資訊 ℹ️

3. **notifications/speak_message.sh** - 一般語音通知
   - 用於過程中的狀態更新
   - 播放傳入的任意訊息
   - 通知標題：「Claude Code 語音通知」

### 注意事項

- 語音內容應簡潔明瞭，避免過長的描述
- 保持專業且友善的語調
- 根據用戶設定的模式調整通知頻率
- 在安靜模式下，完全停止語音功能

---

## 其他設定

請在此區域加入其他 Claude Code 的專案特定設定和規則。