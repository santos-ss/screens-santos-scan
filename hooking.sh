#!/bin/bash

clear

echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

LOG="/sdcard/scan_log.txt"
SCAN_FILE="/sdcard/hookingSCAN.txt"
TMP="/sdcard/scan_tmp.txt"

# =====================
# FUNÇÃO DE CONEXÃO ADB
# =====================
conectar_adb() {
    clear
    echo "╔════════════════════════════════════╗"
    echo "║       🔌 CONEXÃO ADB - HOOKING     ║"
    echo "╚════════════════════════════════════╝"
    echo ""
    
    if ! command -v adb >/dev/null 2>&1; then
        echo "Instalando ADB..."
        pkg install android-tools -y
    fi

    echo "Digite a porta de pareamento (ex: 45678):"
    read -r pair_port

    echo "Agora digite o código de pareamento que aparece no celular:"
    adb pair localhost:"$pair_port"

    echo ""
    echo "Digite a porta de conexão (ex: 12345):"
    read -r connect_port

    echo "Conectando..."
    adb connect localhost:"$connect_port"
    
    echo ""
    echo "✅ Conexão finalizada. Pressione ENTER para voltar ao menu..."
    read -r
}

# =====================
# FUNÇÃO PRINCIPAL DE SCAN
# =====================
fazer_scan() {
    local pacote="$1"
    local nome="$2"
    
    clear
    echo "╔════════════════════════════════════╗"
    echo "║     ESCANEANDO: $nome              ║"
    echo "╚════════════════════════════════════╝"
    echo ""

    DATE=$(date +"%Y-%m-%d %H:%M:%S")
    score=0

    echo "📅 $DATE"
    echo "──────────────────────────────"

    # =====================
    # VARREDURA GLOBAL DE ARQUIVOS
    # =====================
    echo ""
    echo "🔎 [VARREDURA GLOBAL]"
    > "$TMP"

    PATHS="/storage/emulated/0 /sdcard /data/local/tmp /data/data /data/app /data/adb"
    for path in $PATHS; do
        if [ -d "$path" ]; then
            find "$path" -type f 2>/dev/null | grep -iE "magisk|root|su|zygisk|frida|xposed|hook|inject|cheat|lsposed|shamiko|kernelsu|apatch|shizuku|brevent" >> "$TMP"
        fi
    done

    sort -u "\( TMP" > " \){TMP}_clean"

    echo "🔍 Salvando lista em: $SCAN_FILE"
    echo "=== H O O K I N G SCAN - $DATE ===" > "$SCAN_FILE"
    echo "Total suspeitos: \( (wc -l < " \){TMP}_clean")" >> "$SCAN_FILE"
    cat "${TMP}_clean" >> "$SCAN_FILE"

    if [ -s "${TMP}_clean" ]; then
        echo "🚨 ARQUIVOS SUSPEITOS:"
        cat "${TMP}_clean"
        score=$((score+10))
    else
        echo "✅ Nenhum arquivo suspeito encontrado"
    fi

    # =====================
    # VERIFICAÇÕES MAGISK AVANÇADAS
    # =====================
    echo ""
    echo "🧬 [MAGISK - DETECÇÃO AVANÇADA]"

    magisk_detectado=0

    # 1. Pacotes Magisk
    pkgs=$(adb shell "pm list packages 2>/dev/null | grep -E 'magisk|io.github.huskydg.magisk'")
    if [ -n "$pkgs" ]; then
        echo "❌ Pacote Magisk encontrado:"
        echo "$pkgs"
        magisk_detectado=1
        score=$((score+15))
    fi

    # 2. Diretórios Magisk
    for dir in /data/adb/magisk /sbin/.magisk /data/adb/modules /data/adb/ksu /cache/magisk.log; do
        if adb shell "test -e $dir" 2>/dev/null; then
            echo "❌ Diretório Magisk: $dir"
            magisk_detectado=1
            score=$((score+12))
        fi
    done

    # 3. Processos Magisk
    procs=$(adb shell "ps -ef 2>/dev/null | grep -E 'magiskd|zygisk|magisk'" | grep -v grep)
    if [ -n "$procs" ]; then
        echo "❌ Processo Magisk em execução:"
        echo "$procs"
        magisk_detectado=1
        score=$((score+18))
    fi

    # 4. Mounts Magisk
    mounts=$(adb shell "cat /proc/mounts 2>/dev/null | grep -i magisk")
    if [ -n "$mounts" ]; then
        echo "❌ Mount Magisk detectado"
        echo "$mounts"
        magisk_detectado=1
        score=$((score+14))
    fi

    if [ $magisk_detectado -eq 0 ]; then
        echo "✅ Nenhum vestígio de Magisk encontrado"
    fi

    # =====================
    # WIFI DEBUG / PAIRING
    # =====================
    echo ""
    echo "🔗 [WIFI DEBUG / PAIRING RECENTE]"

    EVENTS=$(logcat -b all -d 2>/dev/null | grep -iE "pairing|unpair|forget|remove|AdbDebuggingManager|brevent|shizuku" | tail -n 15)
    if [ -n "$EVENTS" ]; then
        echo "$EVENTS" | while read -r line; do
            ts=$(echo "$line" | awk '{print $1 " " $2}')
            echo "   • $ts → $line"
        done
        score=$((score+15))
    else
        echo "✅ Nenhum pairing/desparelhamento recente"
    fi

    # =====================
    # RESULTADO FINAL
    # =====================
    echo ""
    echo "════════ RESULTADO ════════"

    if [ $score -ge 35 ]; then
        status="💀 CRITICO"
    elif [ $score -ge 20 ]; then
        status="🚨 SUSPEITO"
    elif [ $score -ge 12 ]; then
        status="⚠️ ATENÇÃO"
    else
        status="✅ LIMPO"
    fi

    echo "Score  : $score"
    echo "Status : $status"
    echo ""
    echo "📄 Relatório completo salvo em: $SCAN_FILE"

    echo ""
    echo "╔════════════════════════════════════╗"
    echo "║     ✔ SCAN FINALIZADO (HOOKING)    ║"
    echo "╚════════════════════════════════════╝"

    echo ""
    echo "Pressione ENTER para voltar ao menu..."
    read -r
}

# =====================
# MENU PRINCIPAL
# =====================
while true; do
    clear
    echo "╔════════════════════════════════════╗"
    echo "║         🔍 H O O K I N G           ║"
    echo "╚════════════════════════════════════╝"
    echo ""
    echo "   [0] 🔌 Conectar via ADB"
    echo "   [1] 🎮 Escanear Free Fire Normal"
    echo "   [2] 🎮 Escanear Free Fire MAX"
    echo "   [S] ❌ Sair"
    echo ""
    echo -n "   Escolha: "
    read -r opcao

    case "$opcao" in
        0) conectar_adb ;;
        1) fazer_scan "com.dts.freefireth" "Free Fire Normal" ;;
        2) fazer_scan "com.dts.freefiremax" "Free Fire MAX" ;;
        s|S) 
            echo "Obrigado por usar H O O K I N G!"
            exit 0 
            ;;
        *) 
            echo "Opção inválida!"
            read -r 
            ;;
    esac
done
