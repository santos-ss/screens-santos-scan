#!/data/data/com.termux/files/usr/bin/bash
# =============================================
# SCANNER BYPASS REMOTE v3.0
# Detecta root + ADB + ADB Wireless (método REMOTE)
# Gera logsSUS.txt na pasta /storage/emulated/0/
# =============================================
# Autor: Grok • Versão: 3.0 • Abril 2026
# =============================================

clear
echo -e "\e[1;36m🔍 SCANNER BYPASS REMOTE v3.0\e[0m"
echo -e "\e[1;33m===========================================\e[0m"

# Cores
GREEN="\e[1;32m"
RED="\e[1;31m"
YELLOW="\e[1;33m"
BLUE="\e[1;34m"
RESET="\e[0m"

# ====================== INFORMAÇÕES DO DISPOSITIVO ======================
echo -e "\( {BLUE}📱 Informações do dispositivo: \){RESET}"
echo -e "   Modelo     : $(getprop ro.product.model)"
echo -e "   Android    : $(getprop ro.build.version.release)"
echo -e "   Build      : $(getprop ro.build.id)"
echo -e "   Data/Hora  : $(date '+%d/%m/%Y %H:%M:%S')"
echo -e "\e[1;33m===========================================\e[0m"

# ====================== INICIALIZAÇÃO DO LOG ======================
LOG_DIR="/storage/emulated/0"
LOG_FILE="$LOG_DIR/logsSUS.txt"

# Cria pasta caso não exista (segurança)
mkdir -p "$LOG_DIR" 2>/dev/null

LOG_CONTENT="=== SCANNER BYPASS REMOTE v3.0 ===\n"
LOG_CONTENT+="Dispositivo: $(getprop ro.product.model) | Android $(getprop ro.build.version.release)\n"
LOG_CONTENT+="Data: $(date '+%d/%m/%Y %H:%M:%S')\n"
LOG_CONTENT+="===========================================\n\n"

# ====================== INÍCIO DO SCAN ======================
echo -e "${YELLOW}🔎 Iniciando verificação completa...\e[0m\n"

SUSPICIOUS=0

# 1. Root
echo -n "📌 Verificando ROOT... "
if command -v su >/dev/null 2>&1 && su -c 'id' 2>/dev/null | grep -q "uid=0"; then
    echo -e "\( {GREEN}✅ DETECTADO \){RESET}"
    LOG_CONTENT+="🚨 ROOT DETECTADO\n"
    ((SUSPICIOUS++))
else
    echo -e "\( {RED}❌ Não encontrado \){RESET}"
fi

# 2. Depuração USB
ADB_ENABLED=$(settings get global adb_enabled 2>/dev/null || echo "0")
echo -n "📌 Depuração USB (ADB) ativada... "
if [ "$ADB_ENABLED" = "1" ]; then
    echo -e "\( {GREEN}✅ SIM \){RESET}"
    LOG_CONTENT+="🚨 Depuração USB (ADB) ATIVADA\n"
    ((SUSPICIOUS++))
else
    echo -e "\( {RED}❌ NÃO \){RESET}"
fi

# 3. Serviço adbd
ADBD_STATUS=$(getprop init.svc.adbd 2>/dev/null || echo "parado")
echo -n "📌 Serviço adbd rodando... "
if [ "$ADBD_STATUS" = "running" ]; then
    echo -e "\( {GREEN}✅ SIM \){RESET}"
    LOG_CONTENT+="🚨 Serviço adbd RODANDO\n"
    ((SUSPICIOUS++))
else
    echo -e "${RED}❌ \( ADBD_STATUS \){RESET}"
fi

# 4. ADB Wireless (principal sinal do REMOTE)
TCP_PORT=$(getprop service.adb.tcp.port 2>/dev/null || echo "0")
echo -n "📌 ADB Wireless (porta TCP - REMOTE)... "
if [ "$TCP_PORT" != "0" ] && [ -n "$TCP_PORT" ]; then
    echo -e "${GREEN}✅ SIM (porta \( TCP_PORT) \){RESET}"
    LOG_CONTENT+="🚨 ADB WIRELESS ATIVO (porta $TCP_PORT) → SINAL FORTE DE REMOTE\n"
    ((SUSPICIOUS++))
else
    echo -e "\( {RED}❌ Não \){RESET}"
fi

# 5. Opções de Desenvolvedor
DEV=$(settings get global development_settings_enabled 2>/dev/null || echo "0")
echo -n "📌 Opções de Desenvolvedor... "
if [ "$DEV" = "1" ]; then
    echo -e "\( {GREEN}✅ Ativadas \){RESET}"
    LOG_CONTENT+="🚨 Opções de Desenvolvedor ATIVADAS\n"
    ((SUSPICIOUS++))
else
    echo -e "\( {RED}❌ Desativadas \){RESET}"
fi

# 6. Magisk / Root avançado
echo -n "📌 Magisk ou root avançado... "
if [ -d /data/adb/magisk ] || [ -f /data/adb/magisk.db ] || ls /data/adb/*magisk* >/dev/null 2>&1; then
    echo -e "\( {GREEN}✅ Detectado \){RESET}"
    LOG_CONTENT+="🚨 MAGISK / ROOT AVANÇADO DETECTADO\n"
    ((SUSPICIOUS++))
else
    echo -e "\( {RED}❌ Não encontrado \){RESET}"
fi

# 7. Processos ADB
echo -e "\n📌 Processos ADB em execução:"
ps -ef 2>/dev/null | grep -E 'adbd|adb' | grep -v grep || echo "   \( {YELLOW}Nenhum processo ADB encontrado \){RESET}"

echo -e "\n\e[1;33m===========================================\e[0m"

# ====================== RELATÓRIO FINAL ======================
echo -e "${BLUE}📋 RELATÓRIO FINAL\e[0m"

if [ $SUSPICIOUS -gt 0 ]; then
    echo -e "${RED}🚨 ALERTA: \( SUSPICIOUS sinal(is) de Bypass REMOTE detectado(s)! \){RESET}"
    echo -e "   O aparelho pode ter sido usado com método REMOTE."
else
    echo -e "\( {GREEN}✅ Nenhum sinal de Bypass REMOTE encontrado. \){RESET}"
fi

# ====================== SALVANDO LOG ======================
echo -e "\n💾 Salvando logs suspeitos..."
{
    echo -e "$LOG_CONTENT"
    echo -e "\n==========================================="
    echo -e "Fim do scan • Total de alertas: $SUSPICIOUS"
} > "$LOG_FILE"

if [ -f "$LOG_FILE" ]; then
    echo -e "\( {GREEN}✅ Arquivo criado com sucesso! \){RESET}"
    echo -e "📁 Local: ${YELLOW}\( LOG_FILE \){RESET}"
else
    echo -e "\( {RED}⚠️ Não foi possível criar o arquivo no armazenamento. \){RESET}"
    echo -e "   Rode: termux-setup-storage e tente novamente."
fi

echo -e "\e[1;33m===========================================\e[0m"
echo -e "Script v3.0 otimizado • Pronto para GitHub 🔥"
