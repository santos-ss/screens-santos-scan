#!/bin/bash

clear
echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

DATE=$(date +"%Y-%m-%d %H:%M:%S")
RESULT_FILE="/sdcard/resultSCAN.txt"
score=0

echo ""
echo "📅 Scan iniciado em: $DATE"
echo "══════════════════════════════════════"
echo ""

# Limpa o arquivo de resultado
> "$RESULT_FILE"
echo "=== RESULT SCAN - ANTI CHEAT FREE FIRE ===" >> "$RESULT_FILE"
echo "Data/Hora: $DATE" >> "$RESULT_FILE"
echo "Dispositivo: $(getprop ro.product.model)" >> "$RESULT_FILE"
echo "════════════════════════════════════════════" >> "$RESULT_FILE"
echo "" >> "$RESULT_FILE"

# =====================
# 1. ROOT
# =====================
echo "🔐 [VERIFICANDO ROOT]"
if su -c id >/dev/null 2>&1 || [ -f /system/bin/su ] || [ -f /data/adb/magisk ] || [ -f /data/adb/ksu ]; then
  echo -e "\e[31m❌ ROOT DETECTADO ATIVO\e[0m"
  echo "[ROOT] ROOT DETECTADO ATIVO" >> "$RESULT_FILE"
  score=$((score + 10))
else
  echo "✅ Sem root ativo detectado"
fi
echo "" >> "$RESULT_FILE"

# =====================
# 2. XPOSED / LSPOSED
# =====================
echo "🛠️ [VERIFICANDO XPOSED / LSPOSED]"
XPOSED_FOUND=0
XPOSED_PATHS="/data/adb/xposed /data/adb/lsposed /data/adb/modules/xposed /data/adb/modules/lsposed /data/system/xposed.prop"

for path in $XPOSED_PATHS; do
  if [ -e "$path" ] || [ -d "$path" ]; then
    echo -e "\e[31m[XPOSED/LSPOSED] → $path\e[0m"
    echo "[XPOSED] $path" >> "$RESULT_FILE"
    XPOSED_FOUND=1
    score=$((score + 12))
  fi
done

if [ $XPOSED_FOUND -eq 1 ]; then
  echo "Xposed_Detectado.txt" > "/sdcard/Xposed_Detectado.txt"
fi

if [ $XPOSED_FOUND -eq 0 ]; then
  echo "✅ Nenhum sinal de Xposed/LSPosed"
fi
echo ""

# =====================
# 3. VIRTUAL APPS
# =====================
echo "📱 [VERIFICANDO VIRTUAL APPS]"
VIRTUAL_FOUND=0
VIRTUAL_PATHS="/sdcard/Android/data/io.virtualapp /sdcard/Android/data/com.vmos /sdcard/Android/data/com.f1vm /data/data/io.virtualapp"

for path in $VIRTUAL_PATHS; do
  if [ -d "$path" ]; then
    echo -e "\e[31m[VIRTUAL APP] → $path\e[0m"
    echo "[VIRTUAL APP] $path" >> "$RESULT_FILE"
    VIRTUAL_FOUND=1
    score=$((score + 15))
  fi
done

if [ $VIRTUAL_FOUND -eq 1 ]; then
  echo "VirtualApp_Detectado.txt" > "/sdcard/VirtualApp_Detectado.txt"
fi

if [ $VIRTUAL_FOUND -eq 0 ]; then
  echo "✅ Nenhum VirtualApp detectado"
fi
echo ""

# =====================
# 4. GAME GUARDIAN
# =====================
echo "🎮 [VERIFICANDO GAME GUARDIAN]"
GG_FOUND=0

find /sdcard /storage/emulated/0 -type f \( -name "*.lua" -o -name "*gg*" -o -name "*gameguardian*" \) 2>/dev/null | grep -iE "gg|gameguardian" | while read -r file; do
  MOD_TIME=$(stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)
  echo -e "\e[31m[GAME GUARDIAN] $MOD_TIME → $file\e[0m"
  echo "[GAME GUARDIAN] $MOD_TIME → $file" >> "$RESULT_FILE"
  GG_FOUND=1
  score=$((score + 16))
done

if ps -ef 2>/dev/null | grep -E "gameguardian|ggapp" | grep -v grep >/dev/null; then
  ps -ef 2>/dev/null | grep -E "gameguardian|ggapp" | grep -v grep | while read -r line; do
    echo -e "\e[31m[GAME GUARDIAN PROCESSO] → $line\e[0m"
    echo "[GAME GUARDIAN PROCESSO] $line" >> "$RESULT_FILE"
  done
  GG_FOUND=1
fi

if [ $GG_FOUND -eq 1 ]; then
  echo "GameGuardian_Detectado.txt" > "/sdcard/GameGuardian_Detectado.txt"
fi

if [ $GG_FOUND -eq 0 ]; then
  echo "✅ Nenhum Game Guardian detectado"
fi
echo ""

# =====================
# 5. LUCKY PATCHER
# =====================
echo "🔧 [VERIFICANDO LUCKY PATCHER]"
LP_FOUND=0

LP_PATHS="/sdcard/LuckyPatcher /sdcard/Android/data/ru.yandex.lucky.patcher /data/data/ru.yandex.lucky.patcher"

for path in $LP_PATHS; do
  if [ -d "$path" ]; then
    echo -e "\e[31m[LUCKY PATCHER] → $path\e[0m"
    echo "[LUCKY PATCHER] $path" >> "$RESULT_FILE"
    LP_FOUND=1
    score=$((score + 17))
  fi
done

find /sdcard /storage/emulated/0 -type f -name "*.apk" 2>/dev/null | grep -iE "lucky|luckypatcher|patch" | while read -r file; do
  MOD_TIME=$(stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)
  echo -e "\e[31m[LUCKY PATCHER APK] $MOD_TIME → $file\e[0m"
  echo "[LUCKY PATCHER APK] $MOD_TIME → $file" >> "$RESULT_FILE"
  LP_FOUND=1
  score=$((score + 13))
done

if [ $LP_FOUND -eq 1 ]; then
  echo "LuckyPatcher_Detectado.txt" > "/sdcard/LuckyPatcher_Detectado.txt"
fi

if [ $LP_FOUND -eq 0 ]; then
  echo "✅ Nenhum Lucky Patcher detectado"
fi
echo ""

# =====================
# RESULTADO FINAL
# =====================
echo "════════ RESULTADO FINAL ════════"

if [ $score -ge 50 ]; then
  status="💀 CRÍTICO - ALTO RISCO"
elif [ $score -ge 35 ]; then
  status="🚨 SUSPEITO FORTE"
elif [ $score -ge 20 ]; then
  status="⚠️ ATENÇÃO"
else
  status="✅ LIMPO"
fi

echo "Score de risco : $score"
echo "Status         : $status"
echo ""
echo "📄 Relatório completo salvo em: /sdcard/resultSCAN.txt"
echo "📁 Arquivos de detecção criados na pasta 0:"
ls /sdcard/*Detectado.txt 2>/dev/null || echo "Nenhum arquivo de detecção criado."

echo "" >> "$RESULT_FILE"
echo "Score final: $score" >> "$RESULT_FILE"
echo "Status: $status" >> "$RESULT_FILE"
echo "=== FIM DO SCAN ===" >> "$RESULT_FILE"

echo ""
echo "╔════════════════════════════════════╗"
echo "║     ✔ SCAN FINALIZADO (HOOKING)    ║"
echo "╚════════════════════════════════════╝"

echo ""
echo "Pressione ENTER para limpar o terminal..."
read -r

clear
reset
echo "Terminal limpo."
