#!/bin/bash

# 跨平台語音通知腳本
# 使用方法: bash speak_message.sh "要說的訊息"

message="$1"

# 如果沒有提供訊息，顯示使用方法
if [ -z "$message" ]; then
    echo "使用方法: bash speak_message.sh \"要說的訊息\""
    exit 1
fi

# Windows (PowerShell) - 語音 + 系統通知
if command -v powershell &> /dev/null; then
    powershell -Command "
        # 語音通知
        Add-Type -AssemblyName System.Speech;
        (New-Object System.Speech.Synthesis.SpeechSynthesizer).Speak('$message');

        # 系統通知
        Add-Type -AssemblyName System.Windows.Forms;
        Add-Type -AssemblyName System.Drawing;
        \$notification = New-Object System.Windows.Forms.NotifyIcon;
        \$notification.Icon = [System.Drawing.SystemIcons]::Information;
        \$notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info;
        \$notification.BalloonTipTitle = 'Claude Code 語音通知';
        \$notification.BalloonTipText = '$message';
        \$notification.Visible = \$true;
        \$notification.ShowBalloonTip(3000);
        Start-Sleep -Seconds 4;
        \$notification.Dispose();
    "
# macOS
elif command -v say &> /dev/null; then
    say "$message"
# Linux (espeak)
elif command -v espeak &> /dev/null; then
    espeak "$message"
# Linux (festival)
elif command -v festival &> /dev/null; then
    echo "$message" | festival --tts
# Linux (spd-say)
elif command -v spd-say &> /dev/null; then
    spd-say "$message"
# 如果都沒有語音工具，使用系統提示音和文字顯示
else
    echo -e "\a"
    echo "🔊 語音通知: $message"

    # 嘗試安裝建議
    echo ""
    echo "💡 建議安裝語音合成工具："
    echo "   Ubuntu/Debian: sudo apt-get install espeak"
    echo "   Fedora/CentOS: sudo dnf install espeak"
    echo "   macOS: 已內建 say 指令"
    echo "   Windows: 已內建 PowerShell 語音功能"
fi