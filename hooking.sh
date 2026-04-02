#!/bin/bash

echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

LOG="/sdcard/scan_log.txt"
TMP="/sdcard/scan_tmp.txt"
SCAN_FILE="/sdcard/hookingSCAN.txt"   # ← Novo arquivo solicitado
DATE=$(date +"%Y-%m-%d %H:%M:%S")

score=0

echo ""
echo "📅 $DATE"
echo "──────────────────────────────"

# =====================
# KEYWORDS
# =====================
KEYWORDS="magisk|root|su|zygisk|frida|xposed|hook|inject|cheat|lsposed|shamiko|kernelsu|apatch|magiskhide|busybox|supersu"

# =====================
# VARREDURA GLOBAL
# =====================
echo ""
echo "🔎 [VARREDURA GLOBAL - AGRESSIVA]"

> "$TMP"

PATHS="
/storage/emulated/0
/storage/self/primary
/sdcard
/data/local/tmp
/data/data
/data/app
/data/user
/data/misc/adb
"

for path in $PATHS; do
  if [ -d "$path" ]; then
    echo "[*] Escaneando: $path"
    find "$path" -type f 2>/dev/null | grep -iE "$KEYWORDS" >> "$TMP"
  fi
done

sort -u "\( TMP" > " \){TMP}_clean"

# =====================
# CRIAÇÃO DO ARQUIVO hookingSCAN.txt
# =====================
echo "🔍 Salvando lista de arquivos suspeitos em: $SCAN_FILE"
echo "=== H O O K I N G  SCAN  -  $DATE ===" > "$SCAN_FILE"
echo "Total de arquivos suspeitos encontrados: \( (wc -l < " \){TMP}_clean")" >> "$SCAN_FILE"
echo "────────────────────────────────────" >> "$SCAN_FILE"
cat "${TMP}_clean" >> "$SCAN_FILE"
echo "" >> "$SCAN_FILE"
echo "=== FIM DO SCAN ===" >> "$SCAN_FILE"

if [ -s "${TMP}_clean" ]; then
  echo ""
  echo "🚨 DETECÇÕES ENCONTRADAS:"
  cat "${TMP}_clean"
  score=$((score+8))
else
  echo "✅ Nenhum arquivo suspeito encontrado"
fi

# =====================
# KERNEL
# =====================
echo ""
echo "⚙️ [KERNEL]"
KERNEL=$(uname -a)
echo "$KERNEL"
if echo "$KERNEL" | grep -iqE "custom|perf|gaming|overclock|kernelsu"; then
  echo "⚠️ Kernel possivelmente modificada"
  score=$((score+4))
else
  echo "✅ Kernel padrão"
fi

# =====================
# ROOT + PROCESSOS + ADB (mantido resumido)
# =====================
echo ""
echo "🔐 [ROOT]"
if su -c id >/dev/null 2>&1; then
  echo "❌ ROOT ATIVO"
  score=$((score+10))
else
  echo "✅ Sem root ativo"
fi

echo ""
echo "🧠 [PROCESSOS]"
if ps -ef 2>/dev/null | grep -E "frida-server|xposed|zygisk|magisk|shizuku|brevent" >/dev/null; then
  echo "🚨 Processo suspeito em execução"
  score=$((score+8))
else
  echo "✅ Processos limpos"
fi

# =====================
# WIFI DEBUG
# =====================
echo ""
echo "🔗 [WIFI DEBUG / PAIRING RECENTE]"
# (mantido igual ao anterior - se quiser posso deixar mais curto)

pairing_flags=0
LOGCAT_FULL=$(logcat -b all -d 2>/dev/null)
EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "AdbDebuggingManager|wireless|pairing|unpair|forget|remove|paired|brevent|shizuku" | tail -n 25)

echo "📋 Eventos detectados:"
if [ -n "$EVENTS" ]; then
  echo "$EVENTS" | while read -r line; do
    timestamp=$(echo "$line" | awk '{print $1 " " $2}')
    clean_msg=$(echo "$line" | sed 's/.*: //')
    if echo "$line" | grep -qiE "unpair|forget|remove|delete"; then
      echo "   🟥 [DESPARELHADO] $timestamp → $clean_msg"
      score=$((score+12))
    elif echo "$line" | grep -qiE "pair|connect"; then
      echo "   🟨 [PAREADO]     $timestamp → $clean_msg"
      score=$((score+7))
    fi
  done
else
  echo "✅ Nenhum evento de pairing/desparelhamento encontrado"
fi

# =====================
# RESULTADO FINAL
# =====================
echo ""
echo "════════ RESULTADO ════════"

if [ $score -ge 25 ]; then
  status="💀 CRITICO"
elif [ $score -ge 15 ]; then
  status="🚨 SUSPEITO"
elif [ $score -ge 8 ]; then
  status="⚠️ ATENÇÃO"
else
  status="✅ LIMPO"
fi

echo "Score : $score"
echo "Status: $status"
echo ""
echo "📄 Lista completa de suspeitos salva em: $SCAN_FILE"

echo ""
echo "╔════════════════════════════════════╗"
echo "║     ✔ SCAN FINALIZADO (HOOKING)    ║"
echo "╚════════════════════════════════════╝"

echo ""
echo "Pressione ENTER para limpar o terminal..."
read -r

clear
reset
echo "Terminal limpo e resetado."
