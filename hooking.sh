#!/bin/bash

echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

LOG="/sdcard/scan_log.txt"
TMP="/sdcard/scan_tmp.txt"
SCAN_FILE="/sdcard/hookingSCAN.txt"
SUS_LOG="/sdcard/logsSUS.txt"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

score=0

echo ""
echo "📅 $DATE"
echo "──────────────────────────────"

# =====================
# KEYWORDS (ampliada para logs do sistema)
# =====================
KEYWORDS="magisk|root|su|zygisk|frida|xposed|hook|inject|cheat|lsposed|shamiko|kernelsu|apatch|magiskhide|busybox|supersu|AdbDebuggingManager|wireless|pairing|pair|unpair|forget|remove|paired|bond|bonding|bluetooth|wifi|connect|disconnect|connection|debug|root|su|magisk|frida|zygisk|xposed|shizuku|brevent"

# =====================
# VARREDURA GLOBAL DE ARQUIVOS
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
# SALVANDO hookingSCAN.txt
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
# ROOT + PROCESSOS
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
# ANÁLISE COMPLETA DE TODAS AS LOGS DO SISTEMA
# =====================
echo ""
echo "🔗 [ANÁLISE COMPLETA DE TODAS AS LOGS DO SISTEMA]"

# Captura TODAS as logs disponíveis no logcat (sem limite de linhas)
LOGCAT_FULL=$(logcat -b all -d 2>/dev/null)

# Busca por TODOS os eventos relacionados (arquivos + pairing + conexões)
EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "$KEYWORDS" | tail -n 200)

echo "📋 Total de eventos suspeitos encontrados nas logs do sistema: $(echo "$LOGCAT_FULL" | grep -iE "$KEYWORDS" | wc -l)"

if [ -n "$EVENTS" ]; then
  echo "$EVENTS" | while read -r line; do
    timestamp=$(echo "$line" | awk '{print $1 " " $2}' 2>/dev/null || echo "$DATE")
    clean_msg=$(echo "$line" | sed 's/.*: //')

    if echo "$line" | grep -qiE "unpair|forget|remove|delete|disconnect"; then
      echo "   🟥 [DESPARELHADO/DESCONECTADO] $timestamp → $clean_msg"
      score=$((score+12))
    elif echo "$line" | grep -qiE "pair|bond|connect|paired"; then
      echo "   🟨 [PAREADO/CONECTADO]     $timestamp → $clean_msg"
      score=$((score+7))
    else
      echo "   🔵 [EVENTO SUSPEITO]      $timestamp → $clean_msg"
    fi

    # Salva TODA linha encontrada no logsSUS.txt (histórico completo)
    echo "[$DATE] $line" >> "$SUS_LOG"
  done
else
  echo "✅ Nenhuma atividade suspeita encontrada em TODAS as logs do sistema"
fi

# Cabeçalho do logsSUS.txt (caso ainda não exista)
if [ ! -s "$SUS_LOG" ]; then
  echo "=== LOGS SUSPEITOS DE CONEXÃO / PAREAMENTO / HOOKING ===" > "$SUS_LOG"
  echo "Arquivo criado em: $DATE" >> "$SUS_LOG"
  echo "────────────────────────────────────────────" >> "$SUS_LOG"
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
echo "📄 Lista completa de arquivos suspeitos salva em: $SCAN_FILE"
echo "📋 Análise completa de TODAS as logs salva em: $SUS_LOG"

echo ""
echo "╔════════════════════════════════════╗"
echo "║     ✔ SCAN FINALIZADO (HOOKING)    ║"
echo "╚════════════════════════════════════╝"

echo "HOOKING DOMINA"

echo ""
echo "Pressione ENTER para limpar o terminal..."
read -r

clear
reset
echo "Terminal limpo e resetado."
