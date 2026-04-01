#!/bin/bash

echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

TMP="/sdcard/scan_tmp.txt"
SCAN_FILE="/sdcard/hookingSCAN.txt"
RESULT_FILE="/sdcard/hooking_result.txt"   # ← Arquivo principal solicitado
DATE=$(date +"%Y-%m-%d %H:%M:%S")

score=0

echo ""
echo "📅 $DATE"
echo "──────────────────────────────"

# =====================
# KEYWORDS
# =====================
KEYWORDS="magisk|root|su|zygisk|frida|xposed|hook|inject|cheat|lsposed|shamiko|kernelsu|apatch|magiskhide|busybox|supersu|AdbDebuggingManager|wireless|pairing|pair|unpair|forget|remove|paired|bond|bonding|bluetooth|wifi|connect|disconnect|connection|debug|shizuku|brevent"

# =====================
# LIMPA ARQUIVO DE RESULTADO
# =====================
echo "=== H O O K I N G   R E S U L T   -   $DATE ===" > "$RESULT_FILE"
echo "Data do scan: $DATE" >> "$RESULT_FILE"
echo "══════════════════════════════════════════════════════════════" >> "$RESULT_FILE"
echo "" >> "$RESULT_FILE"

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

# Salva no hooking_result.txt
echo "🔍 ARQUIVOS SUSPEITOS ENCONTRADOS:" >> "$RESULT_FILE"
echo "────────────────────────────────────" >> "$RESULT_FILE"
if [ -s "${TMP}_clean" ]; then
  cat "${TMP}_clean" >> "$RESULT_FILE"
  echo "" >> "$RESULT_FILE"
  echo "Total de arquivos suspeitos: \( (wc -l < " \){TMP}_clean")" >> "$RESULT_FILE"
else
  echo "Nenhum arquivo suspeito encontrado." >> "$RESULT_FILE"
fi
echo "" >> "$RESULT_FILE"

if [ -s "${TMP}_clean" ]; then
  echo ""
  echo "🚨 DETECÇÕES DE ARQUIVOS:"
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
echo "$KERNEL" >> "$RESULT_FILE"
echo "" >> "$RESULT_FILE"

if echo "$KERNEL" | grep -iqE "custom|perf|gaming|overclock|kernelsu"; then
  echo "⚠️ Kernel possivelmente modificada" >> "$RESULT_FILE"
  score=$((score+4))
else
  echo "✅ Kernel padrão" >> "$RESULT_FILE"
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

LOGCAT_FULL=$(logcat -b all -d 2>/dev/null)
EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "$KEYWORDS" | tail -n 300)

echo "📋 Total de eventos suspeitos nas logs do sistema: $(echo "$LOGCAT_FULL" | grep -iE "$KEYWORDS" | wc -l)" >> "$RESULT_FILE"
echo "" >> "$RESULT_FILE"
echo "LOGS DO SISTEMA (EVENTOS SUSPEITOS):" >> "$RESULT_FILE"
echo "────────────────────────────────────" >> "$RESULT_FILE"

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

    # Salva TODA linha suspeita no arquivo principal
    echo "[$DATE] $line" >> "$RESULT_FILE"
  done
else
  echo "✅ Nenhuma atividade suspeita encontrada em TODAS as logs do sistema" >> "$RESULT_FILE"
fi

echo "" >> "$RESULT_FILE"
echo "=== FIM DO RELATÓRIO HOOKING ===" >> "$RESULT_FILE"

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
echo "📄 Relatório completo salvo em: $RESULT_FILE"

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
