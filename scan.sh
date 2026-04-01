#!/data/data/com.termux/files/usr/bin/bash
echo "╔══════════════════════════════╗"
echo "║   🔍 ScreeS | Santos Scan    ║"
echo "╚══════════════════════════════╝"

LOG="/sdcard/scan_log.txt"
TMP="/sdcard/scan_tmp.txt"
DATE=$(date)

score=0

echo ""
echo "📅 $DATE"
echo "──────────────────────────────"

# =====================
# 🔍 KEYWORDS
# =====================
KEYWORDS="magisk|root|su|zygisk|frida|xposed|hook|kernel|inject|cheat"

# =====================
# 📂 CAMINHOS
# =====================
PATHS="
/storage/emulated/0
/storage/self/primary
/data/local/tmp
"

echo ""
echo "🔎 [VARREDURA GLOBAL]"

> "$TMP"

for path in $PATHS; do
  echo ""
  echo "[*] Escaneando: $path"

  find "$path" -type f 2>/dev/null | grep -iE "$KEYWORDS" >> "$TMP"
done

# remover duplicados
sort -u "$TMP" > "${TMP}_clean"

if [ -s "${TMP}_clean" ]; then
  echo ""
  echo "🚨 DETECÇÕES ENCONTRADAS:"
  cat "${TMP}_clean"
  score=$((score+5))
else
  echo "✅ Nenhum arquivo suspeito encontrado"
fi

# =====================
# 🔧 KERNEL
# =====================
echo ""
echo "⚙️ [KERNEL]"

KERNEL=$(uname -a)
echo "$KERNEL"

if echo "$KERNEL" | grep -iqE "custom|perf|gaming"; then
  echo "⚠️ Kernel possivelmente modificada"
  score=$((score+3))
else
  echo "✅ Kernel padrão"
fi

# =====================
# 🔐 ROOT
# =====================
echo ""
echo "🔐 [ROOT]"

if su -c id >/dev/null 2>&1; then
  echo "❌ ROOT ATIVO"
  score=$((score+8))
else
  echo "✅ Sem root ativo"
fi

# =====================
# 🧠 PROCESSOS
# =====================
echo ""
echo "🧠 [PROCESSOS]"

if ps | grep -E "frida-server|xposed|zygisk" >/dev/null; then
  echo "🚨 Processo suspeito em execução"
  score=$((score+6))
else
  echo "✅ Processos limpos"
fi

# =====================
# 🔌 ADB / CONEXÕES
# =====================
echo ""
echo "🔌 [CONEXÕES / ADB]"

adb_flags=0

getprop | grep -i adb | grep -i running >/dev/null && {
  echo "⚠️ ADB ativo"
  adb_flags=$((adb_flags+2))
} || echo "✅ ADB não ativo"

netstat -an 2>/dev/null | grep ":5555" >/dev/null && {
  echo "🚨 ADB via rede detectado"
  adb_flags=$((adb_flags+4))
}

dumpsys usb 2>/dev/null | grep -i connected >/dev/null && \
echo "ℹ️ USB conectado recentemente"

logcat -d 2>/dev/null | grep -i adb | grep -i connect >/dev/null && {
  echo "🚨 Conexão ADB recente (logs)"
  adb_flags=$((adb_flags+3))
}

if [ $adb_flags -ge 5 ]; then
  echo "❌ Conexão suspeita"
  score=$((score+6))
elif [ $adb_flags -ge 2 ]; then
  echo "⚠️ Indícios de conexão"
  score=$((score+2))
else
  echo "✅ Nenhuma evidência"
fi

# =====================
# 📊 RESULTADO FINAL
# =====================
echo ""
echo "════════ RESULTADO ════════"

if [ $score -ge 15 ]; then
  status="💀 CRITICO"
elif [ $score -ge 8 ]; then
  status="🚨 SUSPEITO"
elif [ $score -ge 4 ]; then
  status="⚠️ ATENCAO"
else
  status="✅ LIMPO"
fi

echo "Score : $score"
echo "Status: $status"

# =====================
# 📄 LOG
# =====================
echo "------------------------------" >> "$LOG"
echo "DATA: $DATE" >> "$LOG"
echo "SCORE: $score" >> "$LOG"
echo "STATUS: $status" >> "$LOG"

echo ""
echo "📄 Log salvo em: $LOG"

echo ""
echo "╔══════════════════════════════╗"
echo "║   ✔ SCAN FINALIZADO (ScreeS) ║"
echo "╚══════════════════════════════╝"
