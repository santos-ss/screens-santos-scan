#!/bin/bash

echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

LOG="/sdcard/scan_log.txt"
TMP="/sdcard/scan_tmp.txt"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

score=0

echo ""
echo "📅 $DATE"
echo "──────────────────────────────"

# =====================
# KEYWORDS (mais completas)
# =====================
KEYWORDS="magisk|root|su|zygisk|frida|xposed|hook|inject|cheat|lsposed|shamiko|kernelsu|apatch|magiskhide|hide|substratum|busybox|supersu"

# =====================
# PASTAS PARA BUSCA (MUITO MAIS AMPLA)
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
/system
"

for path in $PATHS; do
  if [ -d "$path" ]; then
    echo "[*] Escaneando: $path"
    find "$path" -type f 2>/dev/null | grep -iE "$KEYWORDS" >> "$TMP"
  fi
done

# Remover duplicados
sort -u "\( TMP" > " \){TMP}_clean"

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
# ROOT
# =====================
echo ""
echo "🔐 [ROOT]"
if su -c id >/dev/null 2>&1; then
  echo "❌ ROOT ATIVO"
  score=$((score+10))
else
  echo "✅ Sem root ativo"
fi

# =====================
# PROCESSOS
# =====================
echo ""
echo "🧠 [PROCESSOS]"
if ps -ef 2>/dev/null | grep -E "frida-server|xposed|zygisk|magisk|shizuku|brevent" >/dev/null; then
  echo "🚨 Processo suspeito em execução"
  score=$((score+8))
else
  echo "✅ Processos limpos"
fi

# =====================
# ADB / CONEXÕES
# =====================
echo ""
echo "🔌 [CONEXÕES / ADB]"
adb_flags=0
getprop | grep -i adb | grep -i running >/dev/null && { echo "⚠️ ADB ativo"; adb_flags=$((adb_flags+3)); }
netstat -an 2>/dev/null | grep ":5555" >/dev/null && { echo "🚨 ADB via rede detectado"; adb_flags=$((adb_flags+6)); }

if [ $adb_flags -ge 6 ]; then
  echo "❌ Conexão suspeita"
  score=$((score+7))
elif [ $adb_flags -ge 3 ]; then
  echo "⚠️ Indícios de conexão"
  score=$((score+3))
else
  echo "✅ Nenhuma evidência"
fi

# =====================
# WIFI DEBUG / PAIRING (ULTRA)
# =====================
echo ""
echo "🔗 [WIFI DEBUG / PAIRING RECENTE - ULTRA SCAN]"

pairing_flags=0
LOGCAT_FULL=$(logcat -b all -d 2>/dev/null)

EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "AdbDebuggingManager|wireless|pairing|unpair|forget|remove.*device|paired|brevent|shizuku|adb.*debug" | tail -n 30)

echo "📋 Eventos detectados:"

if [ -n "$EVENTS" ]; then
  echo "$EVENTS" | while read -r line; do
    timestamp=$(echo "$line" | awk '{print $1 " " $2}')
    clean_msg=$(echo "$line" | sed 's/.*: //')
    if echo "$line" | grep -qiE "unpair|forget|remove|delete|apagado"; then
      echo "   🟥 [DESPARELHADO] $timestamp → $clean_msg"
      pairing_flags=$((pairing_flags+12))
    elif echo "$line" | grep -qiE "pair|connect|paired"; then
      echo "   🟨 [PAREADO]     $timestamp → $clean_msg"
      pairing_flags=$((pairing_flags+7))
    fi
  done
else
  echo "✅ Nenhum evento de pairing/desparelhamento encontrado"
fi

# Verificação de arquivos persistentes
if [ -d "/data/misc/adb" ] && ls /data/misc/adb/ 2>/dev/null | grep -q "."; then
  echo "🔑 Arquivos persistentes de pairing encontrados"
  pairing_flags=$((pairing_flags+9))
fi

if [ $pairing_flags -ge 12 ]; then
  echo "🚨 SUSPEITA ALTA: Pareamento/Desparelhamento detectado"
  score=$((score+13))
elif [ $pairing_flags -ge 7 ]; then
  echo "⚠️ Indícios de Depuração WiFi recente"
  score=$((score+7))
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

# =====================
# LOG
# =====================
echo "------------------------------" >> "$LOG"
echo "DATA: $DATE" >> "$LOG"
echo "SCORE: $score" >> "$LOG"
echo "STATUS: $status" >> "$LOG"

echo ""
echo "📄 Log salvo em: $LOG"

echo ""
echo "╔════════════════════════════════════╗"
echo "║     ✔ SCAN FINALIZADO (HOOKING)    ║"
echo "╚════════════════════════════════════╝"

echo ""
echo "Pressione ENTER para limpar/resetar o terminal..."
read -r

clear
reset
echo "Terminal limpo e resetado."
