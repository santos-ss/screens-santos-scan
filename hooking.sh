#!/bin/bash

clear

echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

LOG="/sdcard/hookingLOG_log.txt"
SCAN_FILE="/sdcard/hookingSCAN.txt"
TMP="/sdcard/hookingTMP_tmp.txt"

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
# SCAN DE REPLAYS E MODIFICAÇÕES
# =====================
scan_freefire_replays() {
    local pkg="$1"
    local nome="$2"

    echo ""
    echo "🎮 [REPLAYS E MODIFICAÇÕES - $nome]"
    echo "══════════════════════════════════════"

    DIRS=(
        "/storage/emulated/0/Android/data/$pkg/files"
        "/storage/emulated/0/Android/data/$pkg"
        "/data/data/$pkg/files"
        "/data/data/$pkg/cache"
    )

    found=0

    for dir in "${DIRS[@]}"; do
        if [ -d "$dir" ]; then
            find "$dir" -type f \( -name "*replay*" -o -name "*record*" -o -name "*highlight*" -o -name "*.mp4" -o -name "*.replay" -o -name "FFReplay*" \) 2>/dev/null | while read -r file; do
                mod_date=$(stat -c "%y" "$file" 2>/dev/null | cut -d. -f1)
                echo "   📼 REPLAY → $mod_date | $file"
                found=1
            done

            echo "   📂 Arquivos modificados recentemente:"
            find "$dir" -type f -printf '%TY-%Tm-%Td %TH:%TM:%TS %p\n' 2>/dev/null | sort -r | head -n 25
            found=1
        fi
    done

    if [ $found -eq 0 ]; then
        echo "✅ Nenhum replay ou modificação recente encontrada para $nome"
    fi
}

# =====================
# FUNÇÃO PRINCIPAL DE SCAN
# =====================
fazer_scan() {
    clear
    echo "╔════════════════════════════════════╗"
    echo "║     ESCANEANDO AMBOS FREE FIRE     ║"
    echo "╚════════════════════════════════════╝"
    echo ""

    DATE=$(date +"%Y-%m-%d %H:%M:%S")
    score=0
    wo_recomendado=0

    echo "📅 $DATE"
    echo "──────────────────────────────"

    # =====================
    # VARREDURA GLOBAL
    # =====================
    echo ""
    echo "🔎 [VARREDURA GLOBAL - HOOKS / CHEATS]"
    > "$TMP"

    PATHS="/storage/emulated/0 /sdcard /data/local/tmp /data/data /data/app /data/adb"
    for path in $PATHS; do
        if [ -d "$path" ]; then
            find "$path" -type f 2>/dev/null | grep -iE "magisk|root|su|zygisk|frida|xposed|hook|inject|cheat|lsposed|shamiko|kernelsu|apatch|shizuku|brevent" >> "$TMP"
        fi
    done

    sort -u "\( TMP" > " \){TMP}_clean"

    echo "🔍 Salvando relatório em: $SCAN_FILE"
    echo "=== H O O K I N G SCAN - $DATE ===" > "$SCAN_FILE"
    echo "Total suspeitos: \( (wc -l < " \){TMP}_clean")" >> "$SCAN_FILE"
    cat "${TMP}_clean" >> "$SCAN_FILE"

    if [ -s "${TMP}_clean" ]; then
        echo "🚨 ARQUIVOS SUSPEITOS ENCONTRADOS:"
        cat "${TMP}_clean"
        score=$((score+15))
    else
        echo "✅ Nenhum arquivo suspeito global encontrado"
    fi

    # =====================
    # ARQUIVOS CRÍTICOS
    # =====================
    echo ""
    echo "☢️ [ALERTA ARQUIVOS CRÍTICOS - FREE FIRE]"

    CRITICAL_PATTERNS="libanort|libanort64|libhook|libcheat|libinject|libfrida|libzygisk|liblsposed|libmagisk|ffcheat|freefirehack|aimbot|wallhack|esp"

    critical_found=$(find /data/data/com.dts.freefireth /data/data/com.dts.freefiremax /storage/emulated/0/Android/data/com.dts.freefire* -type f 2>/dev/null | grep -iE "$CRITICAL_PATTERNS" | head -n 10)

    if [ -n "$critical_found" ]; then
        echo "💥 ARQUIVOS CRÍTICOS DETECTADOS:"
        echo "$critical_found"
        score=$((score+25))
        wo_recomendado=1
        echo "⚠️  ALERTA MÁXIMO: ARQUIVOS DE CHEAT NATIVOS ENCONTRADOS!"
    else
        echo "✅ Nenhum arquivo crítico encontrado"
    fi

    # =====================
    # MAGISK / ROOT
    # =====================
    echo ""
    echo "🧬 [MAGISK / ROOT DETECÇÃO AVANÇADA]"

    magisk_detectado=0

    if pm list packages 2>/dev/null | grep -qE 'magisk|io.github.huskydg.magisk'; then
        echo "❌ Pacote Magisk detectado"
        magisk_detectado=1
        score=$((score+20))
        wo_recomendado=1
    fi

    for dir in /data/adb/magisk /sbin/.magisk /data/adb/modules /data/adb/ksu; do
        if [ -e "$dir" ]; then
            echo "❌ Diretório root/magisk: $dir"
            magisk_detectado=1
            score=$((score+18))
            wo_recomendado=1
        fi
    done

    if [ $magisk_detectado -eq 0 ]; then
        echo "✅ Nenhum vestígio forte de Magisk/Root encontrado"
    fi

    # =====================
    # NOVA DETECÇÃO: ORIGEM + CERTIFICADO (APKMOD / METADATA)
    # =====================
    echo ""
    echo "📦 [ORIGEM REAL DE INSTALAÇÃO E CERTIFICADO]"
    echo "Verificando se é APKMOD ou certificado diferente..."

    for game in "com.dts.freefireth:Free Fire NORMAL" "com.dts.freefiremax:Free Fire MAX"; do
        pkg="${game%%:*}"
        nome="${game##*:}"

        echo ""
        echo "🎮 $nome ($pkg)"

        # Origem de instalação (primeira verdadeira)
        installer=$(pm get-installer "$pkg" 2>/dev/null || echo "NÃO DETECTADO")
        echo "   🔹 Primeira origem de instalação: $installer"

        if [[ "$installer" == "com.android.vending" ]]; then
            echo "   ✅ Oficial (Google Play Store)"
        else
            echo "   ⚠️  POSSÍVEL APKMOD / METADATA ALTERADO / SIDEDLOAD"
            score=$((score+20))
            wo_recomendado=1
        fi

        # Certificado SHA256 + metadados
        cert_sha=$(dumpsys package "$pkg" 2>/dev/null | grep -o 'sha256:[0-9a-fA-F]\{64\}' | head -n1)
        first_install=$(dumpsys package "$pkg" 2>/dev/null | grep -o 'firstInstallTime=[^ ]*' | cut -d= -f2)
        last_update=$(dumpsys package "$pkg" 2>/dev/null | grep -o 'lastUpdateTime=[^ ]*' | cut -d= -f2)

        echo "   📜 Certificado SHA256: ${cert_sha:-NÃO EXTRAÍDO}"
        echo "   📅 Primeira instalação: ${first_install:-N/A}"
        echo "   📅 Última atualização:  ${last_update:-N/A}"

        if [[ -z "$cert_sha" || "$installer" != "com.android.vending" ]]; then
            echo "   💥 ALERTA: Certificado ou origem diferente do oficial → APKMOD provável!"
        fi
    done

    # =====================
    # DETECÇÃO DE PAREAMENTO/DESPAREAMENTO (mantida)
    # =====================
    echo ""
    echo "🔗 [DETECÇÃO DE PAREAMENTO / DESPAREAMENTO WIFI DEBUG]"
    echo "Buscando em TODOS os logs do Android (logcat)..."

    EVENTS=$(logcat -d -v time -b all 2>/dev/null | grep -iE 'pairing|unpair|pareamento|despareamento|forget|remove|AdbDebuggingManager|wifi.*debug|adb.*wireless|WirelessDebug|adb.*pair' | tail -n 100)

    if [ -n "$EVENTS" ]; then
        echo "🚨 RELATOS DE PAREAMENTO/DESPAREAMENTO ENCONTRADOS:"
        echo "$EVENTS" | while read -r line; do
            ts=$(echo "$line" | awk '{print $1 " " $2}')
            if echo "$line" | grep -qiE "pairing|pareamento"; then
                tipo="PAREAMENTO (WiFi Debug)"
            elif echo "$line" | grep -qiE "unpair|despareamento|forget|remove"; then
                tipo="DESPAREAMENTO / REMOÇÃO"
            else
                tipo="EVENTO ADB/WIFI"
            fi
            relato=$(echo "$line" | cut -d' ' -f3-)
            echo "   📅 $ts → [$tipo] $relato"
        done
        score=$((score+20))
        wo_recomendado=1
    else
        echo "✅ Nenhum relato de pareamento/despareamento encontrado nos logs"
    fi

    # =====================
    # REPLAYS E MODIFICAÇÕES
    # =====================
    echo ""
    echo "🎥 [REPLAYS E ARQUIVOS MODIFICADOS PÓS-PARTIDA]"
    scan_freefire_replays "com.dts.freefireth" "Free Fire NORMAL"
    scan_freefire_replays "com.dts.freefiremax" "Free Fire MAX"

    # =====================
    # RESULTADO FINAL
    # =====================
    echo ""
    echo "═══════════════ RESULTADO FINAL ═══════════════"

    if [ $score -ge 40 ]; then
        status="💀 CRÍTICO - CHEAT PROVÁVEL"
    elif [ $score -ge 25 ]; then
        status="🚨 ALTAMENTE SUSPEITO"
    elif [ $score -ge 15 ]; then
        status="⚠️  SUSPEITO"
    else
        status="✅ LIMPO"
    fi

    echo "Score  : $score"
    echo "Status : $status"

    if [ $wo_recomendado -eq 1 ]; then
        echo ""
        echo "══════════════════════════════════════════════"
        echo "🚨 APLIQUE O W.O!"
        echo "Você caiu pro Santos e R3, HOOKING DOMINA!"
        echo "══════════════════════════════════════════════"
    fi

    echo ""
    echo "📄 Relatório completo salvo em: $SCAN_FILE"

    echo ""
    echo "╔════════════════════════════════════╗"
    echo "║     ✔ SCAN FINALIZADO (AMBOS FF)   ║"
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
    echo "   [1] 🎮 Escanear Free Fire (NORMAL + MAX)"
    echo "   [S] ❌ Sair"
    echo ""
    echo -n "   Escolha: "
    read -r opcao

    case "$opcao" in
        0) conectar_adb ;;
        1) fazer_scan ;;
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
