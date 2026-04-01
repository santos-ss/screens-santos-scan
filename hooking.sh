#!/bin/bash

clear

echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

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

    echo "Digite o código de pareamento que aparece no celular:"
    adb pair localhost:"$pair_port"

    echo ""
    echo "Digite a porta de conexão (ex: 5555):"
    read -r connect_port

    echo "Conectando..."
    adb connect localhost:"$connect_port"
    
    echo ""
    echo "✅ Conexão finalizada. Pressione ENTER..."
    read -r
}

# =====================
# SCAN DE ARQUIVOS MODIFICADOS (MELHORADO)
# =====================
scan_freefire_files() {
    local pkg="$1"
    local nome="$2"

    echo ""
    echo "🎮 [ARQUIVOS E MODIFICAÇÕES - $nome]"
    echo "════════════════════════════════════════════════════"

    DIRS=(
        "/storage/emulated/0/Android/data/$pkg"
        "/storage/emulated/0/Android/data/$pkg/files"
        "/data/data/$pkg"
        "/data/data/$pkg/files"
        "/data/data/$pkg/cache"
    )

    found=0

    for dir in "${DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo "📁 Pasta analisada: $dir"

            # Arquivos modificados com data/hora completa + nome + caminho
            echo "   📂 Arquivos modificados (mais recentes primeiro):"
            find "$dir" -type f -printf '%TY-%Tm-%Td %TH:%TM:%TS  %p\n' 2>/dev/null | sort -r | head -n 30 | while read -r line; do
                echo "      $line"
                found=1
            done

            # Busca específica por replays
            echo "   🎥 Replays / Gravações encontrados:"
            find "$dir" -type f \( -iname "*replay*" -o -iname "*record*" -o -iname "*highlight*" -o -iname "*.mp4" -o -iname "FFReplay*" \) 2>/dev/null | while read -r file; do
                mod_date=$(stat -c "%Y-%m-%d %H:%M:%S" "$file" 2>/dev/null)
                echo "      📼 $mod_date  →  $file"
                found=1
            done
        fi
    done

    if [ $found -eq 0 ]; then
        echo "✅ Nenhum arquivo relevante encontrado para $nome"
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

    echo "📅 Scan iniciado em: $DATE"
    echo "──────────────────────────────"

    # Varredura global de hooks
    echo ""
    echo "🔎 [VARREDURA GLOBAL - HOOKS / CHEATS]"
    > "$TMP"

    PATHS="/storage/emulated/0 /sdcard /data/local/tmp /data/data /data/app /data/adb"
    for path in $PATHS; do
        if [ -d "$path" ]; then
            find "$path" -type f 2>/dev/null | grep -iE "magisk|root|su|zygisk|frida|xposed|hook|inject|cheat|lsposed|shamiko|kernelsu|apatch|shizuku|brevent" >> "$TMP"
        fi
    done

    sort -u "\( TMP" > " \){TMP}_clean" 2>/dev/null

    echo "Total suspeitos globais: \( (wc -l < " \){TMP}_clean" 2>/dev/null || echo 0)" >> "$SCAN_FILE"
    cat "${TMP}_clean" >> "$SCAN_FILE"

    if [ -s "${TMP}_clean" ]; then
        echo "🚨 ARQUIVOS SUSPEITOS:"
        cat "${TMP}_clean"
        score=$((score+15))
    else
        echo "✅ Nenhum arquivo suspeito global encontrado"
    fi

    # Arquivos críticos
    echo ""
    echo "☢️ [ARQUIVOS CRÍTICOS]"
    CRITICAL=$(find /data/data/com.dts.freefire* /storage/emulated/0/Android/data/com.dts.freefire* -type f 2>/dev/null | grep -iE "libhook|libcheat|libinject|aimbot|wallhack|esp|libanort" | head -n 10)
    if [ -n "$CRITICAL" ]; then
        echo "$CRITICAL"
        score=$((score+25))
        wo_recomendado=1
    else
        echo "✅ Nenhum arquivo crítico encontrado"
    fi

    # Origem de instalação (corrigido para reduzir falso positivo)
    echo ""
    echo "📦 [ORIGEM DE INSTALAÇÃO]"

    for game in "com.dts.freefireth:Free Fire NORMAL" "com.dts.freefiremax:Free Fire MAX"; do
        pkg="${game%%:*}"
        nome="${game##*:}"

        echo ""
        echo "🎮 $nome ($pkg)"

        installer=$(cmd package get-installer "$pkg" 2>/dev/null | sed -n 's/.*installerPackageName=\(.*\)/\1/p' | tr -d '[:space:]' || echo "")
        if [ -z "$installer" ]; then
            installer=$(pm get-installer "$pkg" 2>/dev/null | sed -n 's/.*installerPackageName=\(.*\)/\1/p' | tr -d '[:space:]' || echo "NÃO DETECTADO")
        fi

        echo "   🔹 Origem detectada : ${installer:-NÃO DETECTADO}"

        if [[ "$installer" == "com.android.vending" ]]; then
            echo "   ✅ Oficial - Google Play Store"
        elif [[ "$installer" == "NÃO DETECTADO" ]]; then
            echo "   ⚠️  Não foi possível detectar (comum no Termux sem root)"
            echo "   ℹ️  Não considerado APKMOD automaticamente"
        else
            echo "   ⚠️  POSSÍVEL APKMOD ou instalação sideload"
            score=$((score+18))
            wo_recomendado=1
        fi
    done

    # Pareamento WiFi Debug
    echo ""
    echo "🔗 [PAREAMENTO / DESPAREAMENTO WIFI DEBUG]"
    EVENTS=$(logcat -d -v time -b all 2>/dev/null | grep -iE 'pairing|unpair|pareamento|despareamento|forget|remove|AdbDebuggingManager|wifi.*debug|adb.*wireless' | tail -n 80)

    if [ -n "$EVENTS" ]; then
        echo "🚨 Registros encontrados:"
        echo "$EVENTS" | while read -r line; do
            ts=$(echo "$line" | awk '{print $1 " " $2}')
            tipo="EVENTO"
            if echo "$line" | grep -qiE "pairing|pareamento"; then tipo="PAREAMENTO"; fi
            if echo "$line" | grep -qiE "unpair|despareamento|forget|remove"; then tipo="DESPAREAMENTO"; fi
            relato=$(echo "$line" | cut -d' ' -f3-)
            echo "   📅 $ts → [$tipo] $relato"
        done
        score=$((score+20))
        wo_recomendado=1
    else
        echo "✅ Nenhum registro de pareamento/despareamento encontrado"
    fi

    # Arquivos e replays dos dois jogos
    echo ""
    echo "🎥 [ARQUIVOS MODIFICADOS E REPLAYS]"
    scan_freefire_files "com.dts.freefireth" "Free Fire NORMAL"
    scan_freefire_files "com.dts.freefiremax" "Free Fire MAX"

    # Resultado final
    echo ""
    echo "═══════════════ RESULTADO FINAL ═══════════════"
    if [ $score -ge 45 ]; then
        status="💀 CRÍTICO"
    elif [ $score -ge 30 ]; then
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
        echo "🚨 APLIQUE O W.O!"
        echo "Você caiu pro Santos e R3, HOOKING DOMINA!"
    fi

    echo ""
    echo "📄 Relatório salvo em: $SCAN_FILE"

    echo ""
    echo "Pressione ENTER para voltar ao menu..."
    read -r
}

# =====================
# MENU
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
