cat > hooking.sh << 'EOL'
#!/bin/bash
# ================================================
# SCAN ANTI-CHEAT FREE FIRE - Versão Shell
# Autor: santos-ss + Grok
# Inclui: Root, Xposed, VirtualApp, GG, Lucky Patcher, Wallhack, MReplays
# ================================================

clear
echo -e "\e[36m"
echo "  KellerSS Android Fucking Cheaters"
echo "  discord.gg/allianceoficial"
echo -e "\e[0m"
echo "══════════════════════════════════════"
echo "     SCAN ANTI-CHEAT FREE FIRE"
echo "══════════════════════════════════════"
echo ""

RESULT="/sdcard/resultSCAN.txt"
DATE=$(date '+%Y-%m-%d %H:%M:%S')
score=0

echo "Data/Hora: $DATE" > "$RESULT"
echo "Dispositivo: $(getprop ro.product.model)" >> "$RESULT"
echo "" >> "$RESULT"

# Funções de cores
red() { echo -e "\e[31m$1\e[0m"; }
green() { echo -e "\e[32m$1\e[0m"; }
yellow() { echo -e "\e[33m$1\e[0m"; }
cyan() { echo -e "\e[36m$1\e[0m"; }

# 1. ROOT
echo "[1] VERIFICANDO ROOT"
if su -c id >/dev/null 2>&1 || [ -f /data/adb/magisk ]; then
    red "✗ ROOT DETECTADO ATIVO"
    echo "[ROOT] ROOT DETECTADO" >> "$RESULT"
    score=$((score + 15))
else
    green "✓ Sem root ativo"
fi
echo ""

# 2. XPOSED / LSPOSED
echo "[2] VERIFICANDO XPOSED / LSPOSED"
if [ -d /data/adb/lsposed ] || [ -d /data/adb/xposed ]; then
    red "✗ XPOSED/LSPOSED DETECTADO"
    echo "[XPOSED] Detectado" >> "$RESULT"
    echo "Xposed_Detectado.txt" > "/sdcard/Xposed_Detectado.txt"
    score=$((score + 12))
else
    green "✓ Sem Xposed/LSPosed"
fi
echo ""

# 3. VIRTUAL APPS
echo "[3] VERIFICANDO VIRTUAL APPS"
if [ -d /sdcard/Android/data/com.vmos ] || [ -d /sdcard/Android/data/com.f1vm ] || [ -d /sdcard/Android/data/io.virtualapp ]; then
    red "✗ VIRTUAL APP DETECTADO (VMOS/F1VM/etc)"
    echo "[VIRTUAL] Detectado" >> "$RESULT"
    echo "VirtualApp_Detectado.txt" > "/sdcard/VirtualApp_Detectado.txt"
    score=$((score + 15))
else
    green "✓ Sem Virtual Apps"
fi
echo ""

# 4. GAME GUARDIAN
echo "[4] VERIFICANDO GAME GUARDIAN"
if ps -ef 2>/dev/null | grep -E "gameguardian|ggapp" | grep -v grep >/dev/null; then
    red "✗ GAME GUARDIAN EM EXECUÇÃO"
    echo "GameGuardian_Detectado.txt" > "/sdcard/GameGuardian_Detectado.txt"
    score=$((score + 18))
else
    green "✓ Sem Game Guardian"
fi
echo ""

# 5. LUCKY PATCHER
echo "[5] VERIFICANDO LUCKY PATCHER"
if [ -d /sdcard/LuckyPatcher ]; then
    red "✗ LUCKY PATCHER DETECTADO"
    echo "LuckyPatcher_Detectado.txt" > "/sdcard/LuckyPatcher_Detectado.txt"
    score=$((score + 17))
else
    green "✓ Sem Lucky Patcher"
fi
echo ""

# 6. WALLHACK (Otimizado)
echo "[6] VERIFICANDO WALLHACK / HOLOGRAMA"
if [ -d "/sdcard/Android/data/$pacote/files/contentcache/Optional/android/gameassetbundles" ] 2>/dev/null; then
    yellow "⚠ Possível Wallhack - pasta de shaders encontrada"
    echo "Wallhack_Detectado.txt" > "/sdcard/Wallhack_Detectado.txt"
    score=$((score + 20))
else
    green "✓ Sem sinais claros de Wallhack"
fi
echo ""

# 7. MREPLAYS (Otimizado)
echo "[7] VERIFICANDO MREPLAYS"
mreplays_dir="/sdcard/Android/data/$pacote/files/MReplays"
if [ -d "$mreplays_dir" ]; then
    if ls "$mreplays_dir"/*.bin >/dev/null 2>&1; then
        red "✗ ARQUIVOS .bin encontrados em MReplays (Replay suspeito)"
        echo "MReplays_Detectado.txt" > "/sdcard/MReplays_Detectado.txt"
        score=$((score + 22))
    else
        yellow "⚠ Pasta MReplays existe, mas sem arquivos .bin"
    fi
else
    green "✓ MReplays normal"
fi
echo ""

# Resumo Final
echo "══════════════════════════════════════"
echo "               RESUMO FINAL"
echo "══════════════════════════════════════"
if [ $score -ge 60 ]; then
    red "💀 CRÍTICO - ALTO RISCO DE CHEAT"
elif [ $score -ge 40 ]; then
    yellow "🚨 SUSPEITO FORTE"
elif [ $score -ge 25 ]; then
    yellow "⚠️ ATENÇÃO"
else
    green "✅ DISPOSITIVO PARECE LIMPO"
fi

echo -e "\nScore de risco: $score"
echo "Relatório completo salvo em: /sdcard/resultSCAN.txt"
echo "Arquivos de detecção criados na pasta /sdcard/"

echo "" >> "$RESULT"
echo "Score final: $score" >> "$RESULT"
echo "=== FIM DO SCAN ===" >> "$RESULT"

echo -e "\nPressione ENTER para sair..."
read -r
clear
EOL

chmod +x scan_hooking.sh
echo "✅ Arquivo criado com sucesso!"
echo "Para rodar use o comando:"
echo -e "\e[32m./scan_hooking.sh\e[0m"
