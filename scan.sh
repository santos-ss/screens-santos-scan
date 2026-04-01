#!/bin/bash

# =====================
# CORES (AGORA FUNCIONANDO)
# =====================
RED="\e[91m"
YELLOW="\e[93m"
GREEN="\e[92m"
WHITE="\e[97m"
RESET="\e[0m"

clear

echo -e "${WHITE}╔════════════════════════════════════╗"
echo -e "║      \( {YELLOW} 🔍 H O O K I N G \){WHITE}           ║"
echo -e "╚════════════════════════════════════╝${RESET}"

LOG="/sdcard/scan_log.txt"
TMP="/sdcard/scan_tmp.txt"
DATE=$(date +"%Y-%m-%d %H:%M:%S")
score=0

echo -e "\n${WHITE}📅 $DATE"
echo -e "────────────────────────────────────${RESET}"

# =====================
# VARREDURA GLOBAL
# =====================
echo -e "\n\( {YELLOW}[🔎 VARREDURA GLOBAL] \){RESET}"

> "$TMP"
for path in /storage/emulated/0 /storage/self/primary /data/local/tmp /data/data; do
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
if echo "$KERNEL" | grep -iqE "custom|perf|gaming"; then
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
if ps -ef 2>/dev/null | grep -E "frida-server|xposed|zygisk|magisk" >/dev/null; then
  echo -e "\( {RED}🚨 Processo suspeito em execução \){RESET}"
  score=$((score+8))
else
  echo -e "\( {GREEN}✅ Processos limpos \){RESET}"
fi

# =====================
# WIFI DEBUG / PAIRING
# =====================
echo -e "\n\( {YELLOW}[🔗 WIFI DEBUG / PAIRING RECENTE - ULTRA SCAN] \){RESET}"

LOGCAT_FULL=$(logcat -b all -d 2>/dev/null)
EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "AdbDebuggingManager|wireless|pairing|unpair|forget|remove|paired|brevent|shizuku" | tail -n 25)

echo -e "\( {WHITE}📋 Eventos detectados: \){RESET}"

if [ -n "$EVENTS" ]; then
  echo "$EVENTS" | while read -r line; do
    timestamp=$(echo "$line" | awk '{print $1 " " $2}')
    clean_msg=$(echo "$line" | sed 's/.*: //')
    if echo "$line" | grep -qiE "unpair|forget|remove|delete"; then
      echo -e "   ${RED}🟥 [DESPARELHADO] $timestamp → \( clean_msg \){RESET}"
      score=$((score+12))
    elif echo "$line" | grep -qiE "pair|connect"; then
      echo -e "   ${YELLOW}🟨 [PAREADO]     $timestamp → \( clean_msg \){RESET}"
      score=$((score+7))
    fi
  done
else
  echo -e "\( {GREEN}✅ Nenhum evento de pairing/desparelhamento encontrado \){RESET}"
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

echo -e "${WHITE}Score  : ${RESET}$score"
echo -e "${WHITE}Status : ${RESET}$status"

echo -e "\n${WHITE}📄 Log salvo em: \( LOG \){RESET}"

echo -e "\n${WHITE}╔════════════════════════════════════╗"
echo -e "║   \( {GREEN}✔ SCAN FINALIZADO (HOOKING) \){WHITE}    ║"
echo -e "╚════════════════════════════════════╝${RESET}"

echo -e "\nPressione \( {YELLOW}ENTER \){RESET} para limpar o terminal..."
read -r

clear
reset
echo -e "\( {GREEN}Terminal limpo e resetado. \){RESET}"
