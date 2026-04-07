#!/bin/bash

# 決策確認通知腳本
# 專門用於需要用戶確認決策時的隨機語音通知

# 定義決策確認訊息陣列
notifications=(
    "Sam，請確認一下"
    "Sam，需要你決定"
    "Sam，等你指示"
    "Sam，請過目"
    "Sam，該你出手了"
)

# 隨機選擇一個決策確認訊息
random_index=$((RANDOM % ${#notifications[@]}))
selected_message="${notifications[$random_index]}"

# Windows (PowerShell) - 語音 + 系統通知
if command -v powershell &> /dev/null; then
    powershell -Command "
        # 語音通知
        Add-Type -AssemblyName System.Speech;
        (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('$selected_message');

        # 系統通知
        Add-Type -AssemblyName System.Windows.Forms;
        Add-Type -AssemblyName System.Drawing;
        \$notification = New-Object System.Windows.Forms.NotifyIcon;
        \$notification.Icon = [System.Drawing.SystemIcons]::Question;
        \$notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Warning;
        \$notification.BalloonTipTitle = 'Claude Code - 需要確認';
        \$notification.BalloonTipText = '$selected_message';
        \$notification.Visible = \$true;
        \$notification.ShowBalloonTip(5000);
        Start-Sleep -Seconds 6;
        \$notification.Dispose();
    "
# macOS
elif command -v say &> /dev/null; then
    say "$selected_message"
    osascript -e "display notification \"$selected_message\" with title \"Claude Code - 需要確認\""
# Linux (espeak)
elif command -v espeak &> /dev/null; then
    espeak "$selected_message"
    if command -v notify-send &> /dev/null; then
        notify-send "Claude Code - 需要確認" "$selected_message" -t 5000
    fi
else
    # 如果沒有語音合成工具，就發出系統聲音
    echo -e "\a"
    echo "🚨 需要確認: $selected_message"
fi