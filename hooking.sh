#!/bin/bash

echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

TMP="/sdcard/scan_tmp.txt"
RESULT_FILE="/sdcard/hooking_result.txt"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

score=0

echo ""
echo "📅 $DATE"
echo "──────────────────────────────"

# =====================
# KEYWORDS
# =====================
FILE_KEYWORDS="magisk|root|su|zygisk|frida|xposed|hook|inject|cheat|lsposed|shamiko|kernelsu|apatch|magiskhide|busybox|supersu"

# Filtro ampliado para capturar QUALQUER pareamento/despareamento, inclusive "Esquecer" na Depuração WiFi/USB
LOG_KEYWORDS="AdbDebuggingManager|wireless.*debug|pairing|pair|unpair|forget|remove|delete|paired|connect|disconnect|bond|bonding|brevent|shizuku|adb.*debug|debugging.*forget|forget.*device|esquecer"

# =====================
# INICIALIZA ARQUIVO DE RESULTADO
# =====================
echo "=== H O O K I N G   R E S U L T   -   $DATE ===" > "$RESULT_FILE"
echo "Data do scan: $DATE" >> "$RESULT_FILE"
echo "══════════════════════════════════════════════════════════════" >> "$RESULT_FILE"
echo "" >> "$RESULT_FILE"

# =====================
# VARREDURA GLOBAL DE ARQUIVOS (mantida)
# =====================
echo ""
echo "🔎 [VARREDURA GLOBAL - AGRESSIVA]"

> "$TMP"

PATHS="/storage/emulated/0 /sdcard /data/local/tmp /data/data /data/app /data/user /data/misc/adb"

for path in $PATHS; do
  if [ -d "$path" ]; then
    echo "[*] Escaneando: $path"
    find "$path" -type f 2>/dev/null | grep -iE "$FILE_KEYWORDS" >> "$TMP"
  fi
done

sort -u "\( TMP" > " \){TMP}_clean"

echo "🔍 ARQUIVOS SUSPEITOS ENCONTRADOS:" >> "$RESULT_FILE"
echo "────────────────────────────────────" >> "$RESULT_FILE"
if [ -s "${TMP}_clean" ]; then
  cat "${TMP}_clean" >> "$RESULT_FILE"
  echo "Total: \( (wc -l < " \){TMP}_clean")" >> "$RESULT_FILE"
  score=$((score+8))
  echo "🚨 DETECÇÕES DE ARQUIVOS:" 
  cat "${TMP}_clean"
else
  echo "Nenhum arquivo suspeito encontrado." >> "$RESULT_FILE"
  echo "✅ Nenhum arquivo suspeito encontrado"
fi
echo "" >> "$RESULT_FILE"

# =====================
# KERNEL + ROOT + PROCESSOS (resumido)
# =====================
echo ""
echo "⚙️ [KERNEL] $(uname -a)" >> "$RESULT_FILE"

if uname -a | grep -iqE "custom|perf|gaming|overclock|kernelsu"; then
  echo "⚠️ Kernel possivelmente modificada" >> "$RESULT_FILE"
  score=$((score+4))
fi

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
# ANÁLISE DE LOGS - DETECÇÃO AMPLIADA DE PAREAMENTO/DESPAREAMENTO
# =====================
echo ""
echo "🔗 [ANÁLISE DE PAREAMENTOS / DESPAREAMENTOS / ESQUECER DISPOSITIVO]"

LOGCAT_FULL=$(logcat -b all -d 2>/dev/null)
EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "$LOG_KEYWORDS" | tail -n 300)

echo "📋 Total de eventos de pareamento/despareamento encontrados: $(echo "$EVENTS" | wc -l)" >> "$RESULT_FILE"
echo "" >> "$RESULT_FILE"
echo "LOGS DE PAREAMENTO / DESPAREAMENTO / ESQUECER:" >> "$RESULT_FILE"
echo "────────────────────────────────────" >> "$RESULT_FILE"

if [ -n "$EVENTS" ]; then
  echo "$EVENTS" | while read -r line; do
    timestamp=$(echo "$line" | awk '{print $1 " " $2}' 2>/dev/null || echo "$DATE")
    clean_msg=$(echo "$line" | sed 's/.*: //')

    if echo "$line" | grep -qiE "unpair|forget|remove|delete|esquecer|forget.*device"; then
      echo "   🟥 [DESPARELHADO / ESQUECIDO] $timestamp → $clean_msg"
      echo "[AVISO] DESPARELHADO / ESQUECIDO (Forget) → $timestamp | $clean_msg" >> "$RESULT_FILE"
      score=$((score+12))
    elif echo "$line" | grep -qiE "pair|paired|connect|bond"; then
      echo "   🟨 [PAREADO / CONECTADO]     $timestamp → $clean_msg"
      echo "[AVISO] PAREADO / CONECTADO     → $timestamp | $clean_msg" >> "$RESULT_FILE"
      score=$((score+7))
    elif echo "$line" | grep -qiE "brevent|shizuku"; then
      echo "   ⚠️  [BREVENT / SHIZUKU DETECTADO] $timestamp → $clean_msg"
      echo "[AVISO] BREVENT/SHIZUKU       → $timestamp | $clean_msg" >> "$RESULT_FILE"
      score=$((score+10))
    else
      echo "   🔵 [EVENTO DE CONEXÃO]       $timestamp → $clean_msg"
      echo "[EVENTO]                      → $timestamp | $clean_msg" >> "$RESULT_FILE"
    fi
  done
else
  echo "✅ Nenhum evento de pareamento/despareamento encontrado" >> "$RESULT_FILE"
  echo "✅ Nenhum evento de pareamento/despareamento encontrado"
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
