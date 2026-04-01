#!/data/data/com.termux/files/usr/bin/bash
# =============================================
# SCANNER BYPASS REMOTE v3.3
# + Logs do Android das últimas 12 horas
# + Logs claros de ADB pairing/unpairing, Bluetooth e USB (com data/hora)
# Gera: logsSUS.txt, logs_12h.txt e logs_conexoes_recentes.txt na pasta 0
# =============================================
# Autor: Grok • Versão: 3.3

clear
echo "🔍 SCANNER BYPASS REMOTE v3.3"
echo "==========================================="

# Cores estáveis
if [ -t 1 ]; then
    GREEN=$(printf '\e[1;32m')
    RED=$(printf '\e[1;31m')
    YELLOW=$(printf '\e[1;33m')
    BLUE=$(printf '\e[1;34m')
    RESET=$(printf '\e[0m')
else
    GREEN="" RED="" YELLOW="" BLUE="" RESET=""
fi

# Informações do dispositivo
echo "\( {BLUE}📱 Informações do dispositivo: \){RESET}"
echo "   Modelo     : $(getprop ro.product.model 2>/dev/null || echo 'Desconhecido')"
echo "   Android    : $(getprop ro.build.version.release 2>/dev/null || echo 'Desconhecido')"
echo "   Data atual : $(date '+%d/%m/%Y %H:%M:%S')"
echo "==========================================="

# Diretório de logs
LOG_DIR="/storage/emulated/0"
mkdir -p "$LOG_DIR" 2>/dev/null

LOG_SUS="$LOG_DIR/logsSUS.txt"
LOG_12H="$LOG_DIR/logs_12h.txt"
LOG_CONEXOES="$LOG_DIR/logs_conexoes_recentes.txt"

# ====================== COLETA DE LOGS DAS ÚLTIMAS 12 HORAS ======================
echo -e "\n📥 Coletando logs do sistema (últimas \~12h)..."

TWELVE_HOURS_AGO=$(date -d '12 hours ago' '+%m-%d %H:%M:%S' 2>/dev/null || date -v-12H '+%m-%d %H:%M:%S' 2>/dev/null)

echo "   Horário de referência: $TWELVE_HOURS_AGO"

logcat -d -v threadtime 2>/dev/null | awk -v ref="$TWELVE_HOURS_AGO" '
    {
        if (match($0, /^([0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})/, arr)) {
            ts = arr[1]
            if (ts >= ref) print $0
        } else {
            print $0
        }
    }
' > "$LOG_12H" 2>/dev/null

if [ -s "$LOG_12H" ]; then
    LINES=$(wc -l < "$LOG_12H")
    echo "${GREEN}✅ \( LINES linhas coletadas (últimas \~12h) \){RESET}"
else
    echo "\( {YELLOW}⚠️ Não foi possível coletar logs significativos. \){RESET}"
fi

# ====================== EXTRAÇÃO DE LOGS CLAROS (ADB, BLUETOOTH, USB) ======================
echo -e "\n🔎 Extraindo eventos de pareamento/desconexão (ADB / Bluetooth / USB)..."

cat > "$LOG_CONEXOES" << EOF
=== LOGS DE CONEXÕES RECENTES - SCANNER BYPASS REMOTE v3.3 ===
Dispositivo: $(getprop ro.product.model 2>/dev/null) | Android $(getprop ro.build.version.release 2>/dev/null)
Data da extração: $(date '+%d/%m/%Y %H:%M:%S')
===========================================

EVENTOS DE PAREAMENTO / DESPAREAMENTO / CONEXÃO:

EOF

# Filtro melhorado para eventos relevantes
logcat -d -v threadtime 2>/dev/null | grep -E -i \
    'adb|pairing|pair device|wireless debugging|bluetooth|bt_.*connect|bt_.*disconnect|usb|device connected|device disconnected|hidl|usb_device|bluetooth_manager' \
    | grep -E -i \
    'pair|connect|disconnect|unpair|bond|usb|adb.*connect|adb.*pair' \
    >> "$LOG_CONEXOES" 2>/dev/null || true

# Se não encontrou nada, adiciona aviso
if [ ! -s "$LOG_CONEXOES" ] || [ $(wc -l < "$LOG_CONEXOES") -le 8 ]; then
    echo -e "\nNenhum evento recente de pareamento/desconexão encontrado no buffer atual." >> "$LOG_CONEXOES"
    echo "   (O buffer do logcat é circular e pode não conter eventos antigos)" >> "$LOG_CONEXOES"
fi

echo "\( {GREEN}✅ Logs claros de conexões gerados \){RESET}"
echo "📁 Arquivo: $LOG_CONEXOES"

# ====================== SCAN DE BYPASS REMOTE (mantido igual) ======================
echo -e "\n🔎 Iniciando verificação de Bypass REMOTE..."

SUSPICIOUS=0
LOG_CONTENT="=== SCANNER BYPASS REMOTE v3.3 ===\n"
LOG_CONTENT+="Dispositivo: $(getprop ro.product.model 2>/dev/null) | Android $(getprop ro.build.version.release 2>/dev/null)\n"
LOG_CONTENT+="Data: $(date '+%d/%m/%Y %H:%M:%S')\n"
LOG_CONTENT+="===========================================\n\n"

# (Seu código de verificação continua igual aqui - root, adb, magisk, etc.)
# ... [mantive exatamente como estava nas verificações 1 a 6]

echo -n "📌 Verificando ROOT... "
if command -v su >/dev/null 2>&1 && su -c 'id' 2>/dev/null | grep -q "uid=0"; then
    echo "\( {GREEN}✅ DETECTADO \){RESET}"
    LOG_CONTENT+="🚨 ROOT DETECTADO\n"
    ((SUSPICIOUS++))
else
    echo "\( {RED}❌ Não encontrado \){RESET}"
fi

echo -n "📌 Depuração USB (ADB) ativada... "
ADB_ENABLED=$(settings get global adb_enabled 2>/dev/null || echo "0")
if [ "$ADB_ENABLED" = "1" ]; then
    echo "\( {GREEN}✅ SIM \){RESET}"
    LOG_CONTENT+="🚨 Depuração USB (ADB) ATIVADA\n"
    ((SUSPICIOUS++))
else
    echo "\( {RED}❌ NÃO \){RESET}"
fi

echo -n "📌 Serviço adbd rodando... "
ADBD_STATUS=$(getprop init.svc.adbd 2>/dev/null || echo "parado")
if [ "$ADBD_STATUS" = "running" ]; then
    echo "\( {GREEN}✅ SIM \){RESET}"
    LOG_CONTENT+="🚨 Serviço adbd RODANDO\n"
    ((SUSPICIOUS++))
else
    echo "${RED}❌ \( ADBD_STATUS \){RESET}"
fi

echo -n "📌 ADB Wireless (porta TCP - REMOTE)... "
TCP_PORT=$(getprop service.adb.tcp.port 2>/dev/null || echo "0")
if [ "$TCP_PORT" != "0" ] && [ -n "$TCP_PORT" ]; then
    echo "${GREEN}✅ SIM (porta \( TCP_PORT) \){RESET}"
    LOG_CONTENT+="🚨 ADB WIRELESS ATIVO (porta $TCP_PORT) → SINAL FORTE DE REMOTE\n"
    ((SUSPICIOUS++))
else
    echo "\( {RED}❌ Não \){RESET}"
fi

echo -n "📌 Opções de Desenvolvedor... "
DEV=$(settings get global development_settings_enabled 2>/dev/null || echo "0")
if [ "$DEV" = "1" ]; then
    echo "\( {GREEN}✅ Ativadas \){RESET}"
    LOG_CONTENT+="🚨 Opções de Desenvolvedor ATIVADAS\n"
    ((SUSPICIOUS++))
else
    echo "\( {RED}❌ Desativadas \){RESET}"
fi

echo -n "📌 Magisk ou root avançado... "
if [ -d /data/adb/magisk ] || [ -f /data/adb/magisk.db ] || ls /data/adb/*magisk* >/dev/null 2>&1; then
    echo "\( {GREEN}✅ Detectado \){RESET}"
    LOG_CONTENT+="🚨 MAGISK / ROOT AVANÇADO DETECTADO\n"
    ((SUSPICIOUS++))
else
    echo "\( {RED}❌ Não encontrado \){RESET}"
fi

echo -e "\n📌 Processos ADB em execução:"
ps -ef 2>/dev/null | grep -E 'adbd|adb' | grep -v grep || echo "   \( {YELLOW}Nenhum processo ADB encontrado \){RESET}"

echo "==========================================="

# Relatório Final
echo "📋 RELATÓRIO FINAL"
if [ $SUSPICIOUS -gt 0 ]; then
    echo "${RED}🚨 ALERTA: \( SUSPICIOUS sinal(is) de Bypass REMOTE detectado(s)! \){RESET}"
else
    echo "\( {GREEN}✅ Nenhum sinal de Bypass REMOTE encontrado. \){RESET}"
fi

# Salva o relatório SUS
{
    echo -e "$LOG_CONTENT"
    echo -e "\n==========================================="
    echo -e "Fim do scan • Total de alertas: $SUSPICIOUS"
} > "$LOG_SUS"

echo -e "\n💾 Arquivos gerados:"
echo "   • logsSUS.txt                → Relatório de suspeitas"
echo "   • logs_12h.txt               → Logs completos do sistema (\~12h)"
echo "   • logs_conexoes_recentes.txt → **Logs claros de ADB / Bluetooth / USB** (novo e recomendado)"
echo "📁 Local: $LOG_DIR/"

echo "==========================================="
echo "Scanner v3.3 completo ✅"
