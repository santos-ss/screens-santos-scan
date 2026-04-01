#!/bin/bash
echo -e "\e[97m╔════════════════════════════════════╗"
echo -e "║      \e[93m🔍 H O O K I N G\e[97m           ║"
echo -e "╚════════════════════════════════════╝\e[0m"

LOG="/sdcard/scan_log.txt"
TMP="/sdcard/scan_tmp.txt"
DATE=$(date +"%Y-%m-%d %H:%M:%S")

score=0

echo -e "\n\e[97m📅 $DATE"
echo -e "────────────────────────────────────\e[0m"

# =====================
# CORES
# =====================
YELLOW="\e[93m"
RED="\e[91m"
GREEN="\e[92m"
WHITE="\e[97m"
RESET="\e[0m"

# =====================
# VARREDURA GLOBAL
# =====================
echo -e "\n\( {YELLOW}[🔎 VARREDURA GLOBAL] \){RESET}"

> "$TMP"

for path in /storage/emulated/0 /storage/self/primary /data/local/tmp /data/data; do
  echo -e "${WHITE}   Escaneando: \( path \){RESET}"
  find "$path" -type f 2>/dev/null | grep -iE "magisk|root|su|zygisk|frida|xposed|hook|inject|cheat|lsposed" >> "$TMP"
done

sort -u "\( TMP" > " \){TMP}_clean"

if [ -s "${TMP}_clean" ]; then
  echo -e "\( {RED}🚨 DETECÇÕES ENCONTRADAS: \){RESET}"
  cat "${TMP}_clean"
  score=$((score+6))
else
  echo -e "\( {GREEN}✅ Nenhum arquivo suspeito encontrado \){RESET}"
fi

# =====================
# KERNEL
# =====================
echo -e "\n\( {YELLOW}[⚙️ KERNEL] \){RESET}"
KERNEL=$(uname -a)
echo -e "${WHITE}\( KERNEL \){RESET}"
if echo "$KERNEL" | grep -iqE "custom|perf|gaming|overclock"; then
  echo -e "\( {RED}⚠️ Kernel modificado detectado \){RESET}"
  score=$((score+4))
else
  echo -e "\( {GREEN}✅ Kernel padrão \){RESET}"
fi

# =====================
# ROOT
# =====================
echo -e "\n\( {YELLOW}[🔐 ROOT] \){RESET}"
if su -c id >/dev/null 2>&1; then
  echo -e "\( {RED}❌ ROOT ATIVO \){RESET}"
  score=$((score+10))
else
  echo -e "\( {GREEN}✅ Sem root ativo \){RESET}"
fi

# =====================
# PROCESSOS
# =====================
echo -e "\n\( {YELLOW}[🧠 PROCESSOS] \){RESET}"
if ps -ef 2>/dev/null | grep -E "frida-server|xposed|zygisk|magisk|lsposed" >/dev/null; then
  echo -e "\( {RED}🚨 Processo suspeito em execução \){RESET}"
  score=$((score+8))
else
  echo -e "\( {GREEN}✅ Processos limpos \){RESET}"
fi

# =====================
# CONEXÕES / ADB
# =====================
echo -e "\n\( {YELLOW}[🔌 CONEXÕES / ADB] \){RESET}"
adb_flags=0

getprop | grep -i adb | grep -i running >/dev/null && { echo -e "\( {YELLOW}⚠️ ADB ativo \){RESET}"; adb_flags=$((adb_flags+3)); }
netstat -an 2>/dev/null | grep ":5555" >/dev/null && { echo -e "\( {RED}🚨 ADB via rede (porta 5555) detectado \){RESET}"; adb_flags=$((adb_flags+6)); }
dumpsys usb 2>/dev/null | grep -i connected >/dev/null && echo -e "\( {YELLOW}ℹ️ USB conectado recentemente \){RESET}"

if [ $adb_flags -ge 8 ]; then
  echo -e "\( {RED}❌ Conexão suspeita detectada \){RESET}"
  score=$((score+7))
elif [ $adb_flags -ge 3 ]; then
  echo -e "\( {YELLOW}⚠️ Indícios de conexão \){RESET}"
  score=$((score+3))
else
  echo -e "\( {GREEN}✅ Nenhuma evidência de conexão \){RESET}"
fi

# =====================
# WIFI DEBUG / PAIRING (ULTRA SCAN)
# =====================
echo -e "\n\( {YELLOW}[🔗 WIFI DEBUG / PAIRING RECENTE - ULTRA SCAN] \){RESET}"

pairing_flags=0
LOGCAT_FULL=$(logcat -b all -d 2>/dev/null)

EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "AdbDebuggingManager|wireless|pairing|unpair|forget|remove.*device|paired|brevent|shizuku|adb.*debug|WirelessDebug" | tail -n 30)

echo -e "\( {WHITE}📋 Eventos detectados: \){RESET}"

if [ -n "$EVENTS" ]; then
  echo "$EVENTS" | while read -r line; do
    timestamp=$(echo "$line" | awk '{print $1 " " $2}')
    clean_msg=$(echo "$line" | sed 's/.*: //')
    if echo "$line" | grep -qiE "unpair|forget|remove|delete|apagado"; then
      echo -e "   ${RED}🟥 [DESPARELHADO] $timestamp → \( clean_msg \){RESET}"
      pairing_flags=$((pairing_flags+12))
    elif echo "$line" | grep -qiE "pair|connect|paired"; then
      echo -e "   ${YELLOW}🟨 [PAREADO]     $timestamp → \( clean_msg \){RESET}"
      pairing_flags=$((pairing_flags+7))
    fi
  done
else
  echo -e "\( {GREEN}✅ Nenhum evento de pairing/desparelhamento encontrado \){RESET}"
fi

# Verificação persistente
if [ -d "/data/misc/adb" ] && ls /data/misc/adb/ 2>/dev/null | grep -q "."; then
  echo -e "\( {RED}🔑 Arquivos persistentes de pairing detectados \){RESET}"
  pairing_flags=$((pairing_flags+9))
fi

if [ $pairing_flags -ge 12 ]; then
  echo -e "\( {RED}🚨 SUSPEITA ALTA: Pareamento/Desparelhamento detectado \){RESET}"
  score=$((score+13))
elif [ $pairing_flags -ge 7 ]; then
  echo -e "\( {YELLOW}⚠️ Indícios de Depuração WiFi recente \){RESET}"
  score=$((score+7))
fi

# =====================
# RESULTADO FINAL
# =====================
echo -e "\n\( {WHITE}════════════ RESULTADO ════════════ \){RESET}"

if [ $score -ge 25 ]; then
  status="\( {RED}💀 CRITICO \){RESET}"
elif [ $score -ge 15 ]; then
  status="\( {RED}🚨 SUSPEITO \){RESET}"
elif [ $score -ge 8 ]; then
  status="\( {YELLOW}⚠️ ATENÇÃO \){RESET}"
else
  status="\( {GREEN}✅ LIMPO \){RESET}"
fi

echo -e "Score  : ${WHITE}\( score \){RESET}"
echo -e "Status : $status"

echo -e "\n${WHITE}📄 Log salvo em: \( LOG \){RESET}"

echo -e "\n${WHITE}╔════════════════════════════════════╗"
echo -e "║   \( {GREEN}✔ SCAN FINALIZADO (HOOKING) \){WHITE}    ║"
echo -e "╚════════════════════════════════════╝${RESET}"

echo -e "\nPressione \( {YELLOW}ENTER \){RESET} para limpar o terminal..."
read -r

clear
reset
echo -e "\( {GREEN}Terminal limpo e resetado. \){RESET}"
