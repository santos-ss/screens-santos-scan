echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

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

sort -u "\( TMP" > " \){TMP}_clean"

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
# 🔗 WIFI DEBUG / PAIRING RECENTE (RESUMIDO)
# =====================
echo ""
echo "🔗 [WIFI DEBUG / PAIRING RECENTE]"

pairing_flags=0
LOGCAT=$(logcat -d 2>/dev/null)

# Filtra apenas eventos relevantes de pairing e unpairing
PAIR_LOGS=$(echo "$LOGCAT" | grep -iE "AdbDebuggingManager|pairing|unpair|forget|remove.*device|paired.*device|device.*removed|pair.*code" | tail -n 15)

if [ -n "$PAIR_LOGS" ]; then
  echo "📋 Eventos recentes detectados:"
  echo "$PAIR_LOGS" | while read -r line; do
    echo "   • $line"
  done
  pairing_flags=$((pairing_flags+6))
else
  echo "✅ Nenhum pareamento ou despareamento recente detectado"
fi

# Avaliação final
if echo "$PAIR_LOGS" | grep -iE "unpair|forget|remove|delete|apagado" >/dev/null; then
  echo "🚨 Dispositivo FOI DESPARElhADO recentemente"
  score=$((score+9))
elif echo "$PAIR_LOGS" | grep -iE "pairing|pair.*device|pair.*code" >/dev/null; then
  echo "⚠️ Dispositivo foi pareado recentemente"
  score=$((score+5))
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
echo "╔════════════════════════════════════╗"
echo "║     ✔ SCAN FINALIZADO (HOOKING)    ║"
echo "╚════════════════════════════════════╝"

echo ""
echo "Pressione ENTER para limpar/resetar o terminal..."
read -r

clear
reset
echo "Terminal limpo."if echo "$KERNEL" | grep -iqE "custom|perf|gaming"; then
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
# 🔗 WIFI DEBUG / PAIRING RECENTE (VERSÃO MELHORADA)
# =====================
echo ""
echo "🔗 [WIFI DEBUG / PAIRING RECENTE]"

pairing_flags=0
LOGCAT=$(logcat -d 2>/dev/null)

# 1. Pareamento recente
if echo "$LOGCAT" | grep -iE "AdbDebuggingManager|pairing|pair.*device|wireless.*debug|pair.*code|Received public key" >/dev/null 2>&1; then
  echo "⚠️ Pareamento WiFi detectado nos logs recentes"
  pairing_flags=$((pairing_flags+4))
fi

# 2. Remoção / Desparelhamento
if echo "$LOGCAT" | grep -iE "AdbDebuggingManager|unpair|forget|remove|delete|removendo|apagado|paired.*device|device.*removed|device.*forget" >/dev/null 2>&1; then
  echo "🚨 Dispositivo pareado FOI DESPARElhADO / APAGADO na Depuração WiFi"
  pairing_flags=$((pairing_flags+6))
  
  echo "   → Últimas linhas relevantes:"
  echo "$LOGCAT" | grep -iE "AdbDebuggingManager|unpair|forget|remove|paired|device" | tail -n 10
fi

# Avaliação final da seção
if [ $pairing_flags -ge 9 ]; then
  echo "❌ SUSPEITA ALTA: Pareou + removeu/apagou evidência"
  score=$((score+9))
elif [ $pairing_flags -ge 4 ]; then
  echo "⚠️ Indícios de uso recente de Depuração WiFi"
  score=$((score+4))
else
  echo "✅ Nenhum pairing ou remoção WiFi detectada nos logs"
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
echo "╔════════════════════════════════════╗"
echo "║     ✔ SCAN FINALIZADO (HOOKING)    ║"
echo "╚════════════════════════════════════╝"

# =====================
# 🛠️ LIMPAR TERMINAL AO PRESSIONAR ENTER
# =====================
echo ""
echo "Pressione ENTER para limpar/resetar o terminal..."
read -r

clear
reset
echo "Terminal limpo e resetado."
