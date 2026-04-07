# Claude Code 語音通知系統

這個資料夾包含所有 Claude Code 語音通知相關的腳本檔案。

## 檔案說明

### 🔔 decision_notify.sh
- **用途**：決策確認通知
- **觸發**：由 Notification Hook 自動觸發
- **功能**：隨機播放確認訊息（如：「Sam，請確認一下」）
- **通知類型**：需要確認，黃色警告圖示

### ✅ task_complete_notify.sh
- **用途**：任務完成通知
- **觸發**：手動調用
- **功能**：播放傳入的具體完成訊息
- **使用方法**：`bash notifications/task_complete_notify.sh "任務訊息"`
- **通知類型**：任務完成，藍色資訊圖示

### 🔊 speak_message.sh
- **用途**：一般語音通知
- **觸發**：手動調用
- **功能**：播放任意傳入的訊息
- **使用方法**：`bash notifications/speak_message.sh "任意訊息"`
- **通知類型**：一般通知

## 跨平台支援

所有腳本都支援：
- **Windows**：PowerShell 語音合成 + 系統通知
- **macOS**：say 指令 + 系統通知
- **Linux**：espeak/festival/spd-say + notify-send

## Hook 配置

在 `.claude/settings.local.json` 中的配置：
```json
"hooks": {
  "Notification": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "bash notifications/decision_notify.sh"
        }
      ]
    }
  ]
}
```

## 使用範例

```bash
# 任務完成通知
bash notifications/task_complete_notify.sh "代碼分析完成"

# 一般語音提示
bash notifications/speak_message.sh "正在執行測試"

# 決策確認（自動觸發，無需手動調用）
```