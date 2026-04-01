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
  echo "[*] Escaneando: $path"
  find "$path" -type f 2>/dev/null | grep -iE "$KEYWORDS" >> "$TMP"
done

sort -u "\( TMP" > " \){TMP}_clean"

if [ -s "${TMP}_clean" ]; then
  echo "🚨 DETECÇÕES ENCONTRADAS:"
  cat "${TMP}_clean"
  score=$((score+5))
else
  echo "✅ Nenhum arquivo suspeito encontrado"
fi

# =====================
# 🔧 KERNEL + ROOT + PROCESSOS (mantido igual)
# =====================
echo ""
echo "⚙️ [KERNEL]"
KERNEL=$(uname -a)
echo "$KERNEL"
if echo "$KERNEL" | grep -iqE "custom|perf|gaming"; then
  echo "⚠️ Kernel possivelmente modificada"; score=$((score+3))
else
  echo "✅ Kernel padrão"
fi

echo ""
echo "🔐 [ROOT]"
if su -c id >/dev/null 2>&1; then
  echo "❌ ROOT ATIVO"; score=$((score+8))
else
  echo "✅ Sem root ativo"
fi

echo ""
echo "🧠 [PROCESSOS]"
if ps | grep -E "frida-server|xposed|zygisk" >/dev/null; then
  echo "🚨 Processo suspeito em execução"; score=$((score+6))
else
  echo "✅ Processos limpos"
fi

# =====================
# 🔌 ADB / CONEXÕES
# =====================
echo ""
echo "🔌 [CONEXÕES / ADB]"
adb_flags=0
getprop | grep -i adb | grep -i running >/dev/null && { echo "⚠️ ADB ativo"; adb_flags=$((adb_flags+2)); } || echo "✅ ADB não ativo"
netstat -an 2>/dev/null | grep ":5555" >/dev/null && { echo "🚨 ADB via rede detectado"; adb_flags=$((adb_flags+4)); }
dumpsys usb 2>/dev/null | grep -i connected >/dev/null && echo "ℹ️ USB conectado recentemente"

logcat -d 2>/dev/null | grep -i adb | grep -i connect >/dev/null && { echo "🚨 Conexão ADB recente"; adb_flags=$((adb_flags+3)); }

if [ $adb_flags -ge 5 ]; then
  echo "❌ Conexão suspeita"; score=$((score+6))
elif [ $adb_flags -ge 2 ]; then
  echo "⚠️ Indícios de conexão"; score=$((score+2))
else
  echo "✅ Nenhuma evidência"
fi

# =====================
# 🔗 WIFI DEBUG / PAIRING RECENTE (MUITO MAIS COMPLETO)
# =====================
echo ""
echo "🔗 [WIFI DEBUG / PAIRING RECENTE - FULL SCAN]"

pairing_flags=0

# Coleta logs de TODOS os buffers
LOGCAT_FULL=$(logcat -b all -d 2>/dev/null)

# dumpsys oficial do ADB
DUMPSYS_ADB=$(dumpsys adb 2>/dev/null)

echo "📋 Eventos detectados:"

# 1. Logs de pareamento / desparelhamento
EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "AdbDebuggingManager|pairing|unpair|forget|remove.*device|paired.*device|WirelessDebug" | tail -n 25)

if [ -n "$EVENTS" ]; then
  echo "$EVENTS" | while read -r line; do
    timestamp=$(echo "$line" | awk '{print $1 " " $2}')
    if echo "$line" | grep -qiE "unpair|forget|remove|delete|apagado"; then
      echo "   🟥 [DESPARELHADO] $timestamp → $(echo "$line" | cut -d']' -f2- | sed 's/^[ \t]*//')"
      pairing_flags=$((pairing_flags+8))
    else
      echo "   🟨 [PAREADO]     $timestamp → $(echo "$line" | cut -d']' -f2- | sed 's/^[ \t]*//')"
      pairing_flags=$((pairing_flags+5))
    fi
  done
fi

# 2. Verifica chaves persistentes (mais difícil de apagar)
if [ -d "/data/misc/adb" ]; then
  echo "🔑 Chaves ADB persistentes encontradas em /data/misc/adb"
  ls -l /data/misc/adb/ 2>/dev/null | tail -n 10
  pairing_flags=$((pairing_flags+6))
fi

# 3. Dumpsys ADB
if echo "$DUMPSYS_ADB" | grep -iE "pair|connected|wireless" >/dev/null; then
  echo "📡 Informações de pairing no dumpsys adb detectadas"
  pairing_flags=$((pairing_flags+4))
fi

# Avaliação final
if [ $pairing_flags -ge 10 ]; then
  echo "🚨 SUSPEITA ALTA: Atividade de pareamento/desparelhamento detectada"
  score=$((score+10))
elif [ $pairing_flags -ge 5 ]; then
  echo "⚠️ Indícios de uso recente de Depuração WiFi"
  score=$((score+6))
else
  echo "✅ Nenhum pareamento ou desparelhamento detectado"
fi

# =====================
# 📊 RESULTADO FINAL
# =====================
echo ""
echo "════════ RESULTADO ════════"

if [ $score -ge 18 ]; then
  status="💀 CRITICO"
elif [ $score -ge 10 ]; then
  status="🚨 SUSPEITO"
elif [ $score -ge 5 ]; then
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
echo "Terminal limpo e resetado."
