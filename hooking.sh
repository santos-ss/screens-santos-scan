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
# KERNEL, ROOT, PROCESSOS
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
# ADB CONEXÕES
# =====================
echo ""
echo "🔌 [CONEXÕES / ADB]"
adb_flags=0
getprop | grep -i adb | grep -i running >/dev/null && { echo "⚠️ ADB ativo"; adb_flags=$((adb_flags+2)); } || echo "✅ ADB não ativo"
netstat -an 2>/dev/null | grep ":5555" >/dev/null && { echo "🚨 ADB via rede detectado"; adb_flags=$((adb_flags+4)); }

if [ $adb_flags -ge 5 ]; then
  echo "❌ Conexão suspeita"; score=$((score+6))
elif [ $adb_flags -ge 2 ]; then
  echo "⚠️ Indícios de conexão"; score=$((score+2))
else
  echo "✅ Nenhuma evidência"
fi

# =====================
# 🔗 WIFI DEBUG / PAIRING RECENTE (ULTRA SENSÍVEL)
# =====================
echo ""
echo "🔗 [WIFI DEBUG / PAIRING RECENTE - ULTRA SCAN]"

pairing_flags=0
LOGCAT_FULL=$(logcat -b all -d 2>/dev/null)

# Filtro bem amplo para pegar Brevent e outros
EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "AdbDebuggingManager|wireless|pairing|unpair|forget|remove.*device|paired|debugging|brevent|shizuku|adb" | tail -n 30)

echo "📋 Eventos detectados:"

if [ -n "$EVENTS" ]; then
  echo "$EVENTS" | while read -r line; do
    timestamp=$(echo "$line" | awk '{print $1 " " $2}')
    clean_msg=$(echo "$line" | sed 's/.*: //')
    
    if echo "$line" | grep -qiE "unpair|forget|remove|delete|apagado|remov"; then
      echo "   🟥 [DESPARELHADO] $timestamp → $clean_msg"
      pairing_flags=$((pairing_flags+10))
    elif echo "$line" | grep -qiE "pair|connect|paired"; then
      echo "   🟨 [PAREADO]     $timestamp → $clean_msg"
      pairing_flags=$((pairing_flags+6))
    else
      echo "   🔍 [EVENTO]      $timestamp → $clean_msg"
      pairing_flags=$((pairing_flags+3))
    fi
  done
else
  echo "✅ Nenhum evento de pairing/desparelhamento encontrado nos logs"
fi

# Verificação extra de pastas persistentes
if ls /data/misc/adb/* 2>/dev/null | grep -E "adb_keys|paired" >/dev/null; then
  echo "🔑 Arquivos persistentes de pairing encontrados"
  pairing_flags=$((pairing_flags+8))
fi

# Score final da seção
if [ $pairing_flags -ge 10 ]; then
  echo "🚨 SUSPEITA ALTA: Atividade de pareamento/desparelhamento detectada"
  score=$((score+12))
elif [ $pairing_flags -ge 5 ]; then
  echo "⚠️ Indícios de Depuração WiFi recente"
  score=$((score+7))
fi

# =====================
# RESULTADO FINAL
# =====================
echo ""
echo "════════ RESULTADO ════════"

if [ $score -ge 20 ]; then
  status="💀 CRITICO"
elif [ $score -ge 12 ]; then
  status="🚨 SUSPEITO"
elif [ $score -ge 6 ]; then
  status="⚠️ ATENCAO"
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
