#!/bin/bash

clear
echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

DATE=$(date +"%Y-%m-%d %H:%M:%S")
score=0

echo ""
echo "📅 Scan iniciado em: $DATE"
echo "══════════════════════════════════════"
echo ""

# =====================
# 1. ROOT DETECTION
# =====================
echo "🔐 [VERIFICANDO ROOT]"
if su -c id >/dev/null 2>&1 || [ -f /system/bin/su ] || [ -f /data/adb/magisk ] || [ -f /data/adb/ksu ]; then
  echo -e "\e[31m❌ ROOT DETECTADO ATIVO\e[0m"
  score=$((score + 10))
else
  echo "✅ Sem root ativo detectado"
fi
echo ""

# =====================
# 2. DETECÇÃO DE XPOSED / LSPOSED
# =====================
echo "🛠️ [VERIFICANDO XPOSED / LSPOSED]"
XPOSED_FOUND=0
XPOSED_PATHS="/data/adb/xposed /data/adb/lsposed /data/adb/modules/xposed /data/adb/modules/lsposed /data/system/xposed.prop /data/system/lsposed.prop"

for path in $XPOSED_PATHS; do
  if [ -e "$path" ] || [ -d "$path" ]; then
    echo -e "\e[31m[XPOSED/LSPOSED DETECTADO] → $path\e[0m"
    XPOSED_FOUND=1
    score=$((score + 12))
  fi
done

if ps -ef 2>/dev/null | grep -E "xposed|lsposed|edxp|sandhook" | grep -v grep >/dev/null; then
  ps -ef 2>/dev/null | grep -E "xposed|lsposed|edxp|sandhook" | grep -v grep | while read -r line; do
    echo -e "\e[31m[XPOSED PROCESSO] → $line\e[0m"
  done
  XPOSED_FOUND=1
  score=$((score + 10))
fi

if [ $XPOSED_FOUND -eq 0 ]; then
  echo "✅ Nenhum sinal de Xposed ou LSPosed detectado"
else
  echo -e "\e[31m⚠️  XPOSED/LSPOSED DETECTADO — RISCO ALTO\e[0m"
fi
echo ""

# =====================
# 3. DETECÇÃO DE VIRTUALAPP / SANDBOX
# =====================
echo "📱 [VERIFICANDO VIRTUAL APPS / SANDBOX]"
VIRTUAL_FOUND=0
VIRTUAL_PATHS="/sdcard/Android/data/io.virtualapp /sdcard/Android/data/com.vmos /sdcard/Android/data/com.f1vm /data/data/io.virtualapp /data/data/com.vmos /data/data/com.f1vm"

for path in $VIRTUAL_PATHS; do
  if [ -d "$path" ]; then
    echo -e "\e[31m[VIRTUAL APP DETECTADO] → $path\e[0m"
    VIRTUAL_FOUND=1
    score=$((score + 15))
  fi
done

if ps -ef 2>/dev/null | grep -E "virtualapp|vmos|f1vm|parallel" | grep -v grep >/dev/null; then
  ps -ef 2>/dev/null | grep -E "virtualapp|vmos|f1vm|parallel" | grep -v grep | while read -r line; do
    echo -e "\e[31m[VIRTUAL APP PROCESSO] → $line\e[0m"
  done
  VIRTUAL_FOUND=1
  score=$((score + 12))
fi

if [ $VIRTUAL_FOUND -eq 0 ]; then
  echo "✅ Nenhum VirtualApp / Sandbox detectado"
else
  echo -e "\e[31m⚠️  VIRTUAL APP DETECTADO — MUITO USADO PARA BYPASS\e[0m"
fi
echo ""

# =====================
# 4. DETECÇÃO DE GAME GUARDIAN
# =====================
echo "🎮 [VERIFICANDO GAME GUARDIAN]"
GG_FOUND=0

GG_PATHS="/sdcard/GameGuardian /sdcard/Android/data/com.gg* /data/data/com.gg* /storage/emulated/0/GameGuardian"

for path in $GG_PATHS; do
  if ls "$path" 2>/dev/null | grep -q .; then
    echo -e "\e[31m[GAME GUARDIAN DETECTADO] → $path\e[0m"
    GG_FOUND=1
    score=$((score + 18))
  fi
done

find /sdcard /storage/emulated/0 -type f \( -name "*.lua" -o -name "*gg*" -o -name "*gameguardian*" \) 2>/dev/null | grep -iE "gg|gameguardian|freefire" | while read -r file; do
  MOD_TIME=$(stat -c "%y" "$file" 2>/dev/null | cut -d. -f1 || echo "$DATE")
  echo -e "\e[31m[GAME GUARDIAN SCRIPT] $MOD_TIME → $file\e[0m"
  GG_FOUND=1
  score=$((score + 14))
done

if ps -ef 2>/dev/null | grep -E "gameguardian|ggapp|gg\.service" | grep -v grep >/dev/null; then
  ps -ef 2>/dev/null | grep -E "gameguardian|ggapp" | grep -v grep | while read -r line; do
    echo -e "\e[31m[GAME GUARDIAN PROCESSO] → $line\e[0m"
  done
  GG_FOUND=1
  score=$((score + 16))
fi

if [ $GG_FOUND -eq 0 ]; then
  echo "✅ Nenhum sinal de Game Guardian detectado"
else
  echo -e "\e[31m⚠️  GAME GUARDIAN DETECTADO — RISCO ALTO\e[0m"
fi
echo ""

# =====================
# 5. DETECÇÃO DE LUCKY PATCHER (NOVA SEÇÃO)
# =====================
echo "🔧 [VERIFICANDO LUCKY PATCHER]"
LP_FOUND=0

# Pastas e arquivos comuns do Lucky Patcher
LP_PATHS="
/sdcard/LuckyPatcher
/sdcard/Android/data/ru.yandex.lucky.patcher
/data/data/ru.yandex.lucky.patcher
/sdcard/Download/LuckyPatcher
/storage/emulated/0/LuckyPatcher
"

for path in $LP_PATHS; do
  if [ -d "$path" ] || ls "$path" 2>/dev/null | grep -q .; then
    echo -e "\e[31m[LUCKY PATCHER DETECTADO] → $path\e[0m"
    LP_FOUND=1
    score=$((score + 17))
  fi
done

# Arquivos .apk modificados ou com nome suspeito do Lucky Patcher
find /sdcard /storage/emulated/0 -type f -name "*.apk" 2>/dev/null | grep -iE "lucky|patch|modified|cracked|freefire" | while read -r file; do
  MOD_TIME=$(stat -c "%y" "$file" 2>/dev/null | cut -d. -f1 || echo "$DATE")
  echo -e "\e[31m[LUCKY PATCHER APK] $MOD_TIME → $file\e[0m"
  LP_FOUND=1
  score=$((score + 13))
done

# Processos do Lucky Patcher
if ps -ef 2>/dev/null | grep -E "lucky.patcher|luckypatcher|ru\.yandex" | grep -v grep >/dev/null; then
  ps -ef 2>/dev/null | grep -E "lucky.patcher|luckypatcher" | grep -v grep | while read -r line; do
    echo -e "\e[31m[LUCKY PATCHER PROCESSO] → $line\e[0m"
  done
  LP_FOUND=1
  score=$((score + 15))
fi

# Verificação no logcat
if logcat -d 2>/dev/null | grep -iE "luckypatcher|lucky.patcher" | tail -n 8 | grep -q .; then
  echo -e "\e[31m[LUCKY PATCHER] Sinais encontrados no logcat\e[0m"
  LP_FOUND=1
  score=$((score + 10))
fi

if [ $LP_FOUND -eq 0 ]; then
  echo "✅ Nenhum sinal de Lucky Patcher detectado"
else
  echo -e "\e[31m⚠️  LUCKY PATCHER DETECTADO — USADO PARA MODIFICAR APPS E BYPASS\e[0m"
fi
echo ""

# =====================
# 6. OUTROS PROCESSOS SUSPEITOS COM DATA E HORA
# =====================
echo "🧠 [OUTROS PROCESSOS SUSPEITOS - COM DATA/HORA]"
echo "Data/Hora do scan: $DATE"
echo "────────────────────────────────────"

SUSPICIOUS_PROCS="frida|inject|hook|cheat|aimbot|esp|magisk|zygisk|shamiko|kernelsu|apatch|su|busybox"

ps -ef 2>/dev/null | grep -E "$SUSPICIOUS_PROCS" | grep -v grep | while read -r line; do
  PID=$(echo "$line" | awk '{print $2}')
  CMD=$(echo "$line" | awk '{for(i=8;i<=NF;i++) printf $i " "; print ""}' | sed 's/^[ \t]*//')
  
  if [ -n "$PID" ] && [ -d "/proc/$PID" ]; then
    START_TIME=$(ps -p "$PID" -o lstart= 2>/dev/null | head -n 1)
    if [ -n "$START_TIME" ]; then
      echo -e "\e[31m[PROCESSO SUSPEITO] $START_TIME → PID: $PID | $CMD\e[0m"
    else
      echo -e "\e[31m[PROCESSO SUSPEITO] $DATE → PID: $PID | $CMD\e[0m"
    fi
  else
    echo -e "\e[31m[PROCESSO SUSPEITO] $DATE → $line\e[0m"
  fi
  score=$((score + 8))
done

if ! ps -ef 2>/dev/null | grep -E "$SUSPICIOUS_PROCS" | grep -v grep >/dev/null; then
  echo "✅ Nenhum outro processo suspeito em execução."
fi
echo ""

# =====================
# 7. ARQUIVOS SUSPEITOS GERAIS + FREE FIRE
# =====================
echo "🔎 [ARQUIVOS SUSPEITOS NA PASTA 0]"
KEYWORDS="magisk|root|su|zygisk|frida|xposed|lsposed|hook|inject|cheat|shamiko|kernelsu|apatch|vmos|f1vm|parallel|sandbox|aimbot|esp|bypass|gg|gameguardian|lucky|luckypatcher"

find /sdcard /storage/emulated/0 -type f 2>/dev/null | grep -iE "$KEYWORDS" | while read -r file; do
  MOD_TIME=$(stat -c "%y" "$file" 2>/dev/null | cut -d. -f1 || echo "$DATE")
  FILENAME=$(basename "$file")
  if echo "$FILENAME" | grep -Ei "frida|xposed|lsposed|inject|hook|bypass|cheat|aimbot|esp|magisk|root|gg|gameguardian|lucky|luckypatcher" >/dev/null; then
    echo -e "\e[31m[CRÍTICO] $MOD_TIME → $file\e[0m"
  else
    echo "$MOD_TIME → $file"
  fi
  score=$((score + 5))
done || echo "✅ Nenhum arquivo suspeito encontrado na pasta 0."
echo ""

echo "📁 [ARQUIVOS DO FREE FIRE - ÚLTIMA MODIFICAÇÃO]"
FF_PATHS="/sdcard/Android/data/com.dts.freefire /sdcard/Android/obb/com.dts.freefire /sdcard/Android/media/com.dts.freefire"

for dir in $FF_PATHS; do
  if [ -d "$dir" ]; then
    echo "📁 Pasta encontrada: $dir"
    find "$dir" -type f -exec stat -c "%y %n" {} + 2>/dev/null | head -n 60
  fi
done
[ "$(find $FF_PATHS -type d 2>/dev/null | wc -l)" -eq 0 ] && echo "Nenhuma pasta do Free Fire encontrada."
echo ""

# =====================
# 8. ADB + USB + BLUETOOTH
# =====================
echo "🔗 [CONEXÕES E PAIRING]"
[ "$(settings get global adb_enabled 2>/dev/null)" = "1" ] && echo -e "\e[31mADB ENABLED → Possível bypass remoto\e[0m" || echo "ADB desativado."

USB_STATE=$(getprop sys.usb.state 2>/dev/null)
echo "$USB_STATE" | grep -q "adb" && echo -e "\e[31mCONEXÃO USB/ADB DETECTADA → $USB_STATE\e[0m" || echo "Nenhuma conexão USB/ADB ativa."

echo ""
echo "📡 [DISPOSITIVOS BLUETOOTH PAREADOS]"
dumpsys bluetooth_manager | sed -n '/Bonded devices:/,/^$/p' 2>/dev/null || echo "Não foi possível listar Bluetooth."
echo ""

# =====================
# RESULTADO FINAL
# =====================
echo "════════ RESULTADO FINAL ════════"

if [ $score -ge 50 ]; then
  status="💀 CRÍTICO - ALTO RISCO DE CHEAT / BYPASS"
elif [ $score -ge 35 ]; then
  status="🚨 SUSPEITO FORTE"
elif [ $score -ge 25 ]; then
  status="⚠️ ATENÇÃO"
else
  status="✅ LIMPO"
fi

echo "Score de risco : $score"
echo "Status         : $status"
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
