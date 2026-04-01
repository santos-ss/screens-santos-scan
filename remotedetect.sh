#!/data/data/com.termux/files/usr/bin/bash
# =============================================
# SCANNER BYPASS REMOTE v2.0
# Detecta sinais de bypass REMOTE (root + ADB + ADB Wireless)
# Ideal para Termux em Android
# =============================================
# Autor: Grok (ajudando você)
# Versão: 2.0
# Data: Abril 2026
# =============================================

clear
echo -e "\e[1;36m🔍 SCANNER BYPASS REMOTE v2.0\e[0m"
echo -e "\e[1;33m===========================================\e[0m"

# Cores para melhor visualização
GREEN="\e[1;32m"
RED="\e[1;31m"
YELLOW="\e[1;33m"
RESET="\e[0m"

# 1. Root detection
echo -n "📌 Verificando ROOT... "
if command -v su >/dev/null 2>&1 && su -c 'id' 2>/dev/null | grep -q "uid=0"; then
    echo -e "\( {GREEN}✅ DETECTADO (root funcional) \){RESET}"
    ROOT=1
else
    echo -e "\( {RED}❌ Não encontrado \){RESET}"
    ROOT=0
fi

# 2. Depuração USB / ADB
ADB_ENABLED=$(settings get global adb_enabled 2>/dev/null || echo "0")
echo -n "📌 Depuração USB (ADB) ativada... "
[ "\( ADB_ENABLED" = "1" ] && echo -e " \){GREEN}✅ SIM\( {RESET}" || echo -e " \){RED}❌ NÃO${RESET}"

# 3. Serviço adbd
ADBD_STATUS=$(getprop init.svc.adbd 2>/dev/null || echo "parado")
echo -n "📌 Serviço adbd rodando... "
[ "\( ADBD_STATUS" = "running" ] && echo -e " \){GREEN}✅ SIM\( {RESET}" || echo -e " \){RED}❌ \( ADBD_STATUS \){RESET}"

# 4. ADB Wireless (sinal mais forte do método REMOTE)
TCP_PORT=$(getprop service.adb.tcp.port 2>/dev/null || echo "0")
echo -n "📌 ADB Wireless (porta TCP - REMOTE)... "
if [ "$TCP_PORT" != "0" ] && [ -n "$TCP_PORT" ]; then
    echo -e "${GREEN}✅ SIM (porta \( TCP_PORT) \){RESET}"
    REMOTE_ALERT=1
else
    echo -e "\( {RED}❌ Não \){RESET}"
    REMOTE_ALERT=0
fi

# 5. Opções de Desenvolvedor
DEV=$(settings get global development_settings_enabled 2>/dev/null || echo "0")
echo -n "📌 Opções de Desenvolvedor... "
[ "\( DEV" = "1" ] && echo -e " \){GREEN}✅ Ativadas\( {RESET}" || echo -e " \){RED}❌ Desativadas${RESET}"

# 6. Magisk / Root avançado
echo -n "📌 Magisk ou root avançado... "
if [ -d /data/adb/magisk ] || [ -f /data/adb/magisk.db ] || ls /data/adb/*magisk* >/dev/null 2>&1; then
    echo -e "\( {GREEN}✅ Detectado \){RESET}"
else
    echo -e "\( {RED}❌ Não encontrado \){RESET}"
fi

# 7. Processos ADB ativos
echo -e "\n📌 Processos ADB em execução:"
ps -ef 2>/dev/null | grep -E 'adbd|adb' | grep -v grep || echo "   \( {YELLOW}Nenhum processo ADB encontrado \){RESET}"

echo -e "\n\e[1;33m===========================================\e[0m"
echo -e "\e[1;36m📋 RELATÓRIO FINAL\e[0m"

if [ "$ROOT" = "1" ] || [ "$ADB_ENABLED" = "1" ] || [ "$ADBD_STATUS" = "running" ] || [ "$TCP_PORT" != "0" ]; then
    echo -e "\( {RED}🚨 ALERTA: Sinais de Bypass REMOTE detectados! \){RESET}"
    echo -e "   Comum em métodos que usam:"
    echo -e "   • Root avançado + ADB/USB"
    echo -e "   • ADB Wireless (porta TCP aberta)"
    echo -e "   O dispositivo pode ter sido usado com bypass REMOTE."
else
    echo -e "\( {GREEN}✅ Nenhum sinal claro do Bypass REMOTE encontrado. \){RESET}"
fi

echo -e "\e[1;33m===========================================\e[0m"
echo -e "Script feito para Termux • v2.0"
