#!/bin/bash

# ===================== CORES E FUNÇÕES COMPLETAS DO KELLERSS =====================
declare -A C
C['rst']="\e[0m"
C['bold']="\e[1m"
C['branco']="\e[97m"
C['cinza']="\e[37m"
C['vermelho']="\e[91m"
C['verde']="\e[92m"
C['fverde']="\e[32m"
C['amarelo']="\e[93m"
C['azul']="\e[34m"
C['ciano']="\e[36m"

function c() {
    local result=""
    for color in "$@"; do
        result+="${C[$color]:-}"
    done
    echo -ne "$result"
}

function rst() { echo -ne "${C['rst']}"; }

function linha() {
    echo -e "$(c bold "$1")  $2 $3$(rst)"
}

function ok()     { linha 'verde'    '✓' "$1"; }
function erro()   { linha 'vermelho' '✗' "$1"; }
function aviso()  { linha 'amarelo'  '⚠' "$1"; }
function info()   { linha 'fverde'   'ℹ' "$1"; }

function secao() {
    local sep=$(printf '─%.0s' $(seq 1 \( (( \){#2} + 6))))
    echo -e "\n$(c bold azul)  ► [$1] $2\n  \( sep \)(rst)\n"
}

function cabecalho() {
    echo -e "\n$(c bold ciano)  $1\n  $(printf '=%.0s' $(seq 1 \( {#1})) \)(rst)\n"
}

# ===================== BANNER GIGANTE =====================
clear
echo -e "$(c branco)"
cat << "EOF"
   ██████╗  ██████╗  ██████╗ ██╗  ██╗██╗███╗   ██╗ ██████╗ 
   ██╔══██╗██╔═══██╗██╔═══██╗██║ ██╔╝██║████╗  ██║██╔════╝ 
   ██████╔╝██║   ██║██║   ██║█████╔╝ ██║██╔██╗ ██║██║  ███╗
   ██╔══██╗██║   ██║██║   ██║██╔═██╗ ██║██║╚██╗██║██║   ██║
   ██║  ██║╚██████╔╝╚██████╔╝██║  ██╗██║██║ ╚████║╚██████╔╝
   ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ 
          H O O K I N G   S C A N N E R
   Powered by santos-ss + KellerSS Detection Methods
EOF
echo -e "\( (c ciano)  Fuck Cheaters & Hookers \)(rst)\n"

DATE=$(date +"%Y-%m-%d %H:%M:%S")
RESULT_FILE="/sdcard/hooking_result.txt"
score=0

echo "📅 $DATE" | tee -a "$RESULT_FILE"
echo "══════════════════════════════════════════════════════════════" | tee -a "$RESULT_FILE"
echo "" | tee -a "$RESULT_FILE"

cabecalho "ANÁLISE COMPLETA DE HOOKING E SEGURANÇA DO DISPOSITIVO"

# ===================== 1. VARREDURA GLOBAL DE ARQUIVOS =====================
secao 1 "VARREDURA GLOBAL DE ARQUIVOS SUSPEITOS"

KEYWORDS="magisk|root|su|zygisk|frida|xposed|hook|inject|cheat|lsposed|shamiko|kernelsu|apatch|magiskhide|busybox|supersu|brevent|shizuku"

> /sdcard/scan_tmp.txt
for path in /sdcard /data/local/tmp /data/data /data/app /data/user /data/misc/adb /storage/emulated/0; do
    if [ -d "$path" ]; then
        info "Escaneando: $path"
        find "$path" -type f 2>/dev/null | grep -iE "$KEYWORDS" >> /sdcard/scan_tmp.txt
    fi
done

sort -u /sdcard/scan_tmp.txt > /sdcard/scan_clean.txt

if [ -s /sdcard/scan_clean.txt ]; then
    erro "ARQUIVOS SUSPEITOS ENCONTRADOS!"
    cat /sdcard/scan_clean.txt | tee -a "$RESULT_FILE"
    score=$((score + 12))
else
    ok "Nenhum arquivo suspeito encontrado"
fi
echo "" | tee -a "$RESULT_FILE"

# ===================== 2. KERNEL + ROOT + PROCESSOS =====================
secao 2 "VERIFICAÇÃO DE KERNEL E ROOT"

KERNEL=$(uname -a)
echo "Kernel: $KERNEL" >> "$RESULT_FILE"

if echo "$KERNEL" | grep -iqE "custom|perf|gaming|overclock|kernelsu"; then
    erro "Kernel modificado detectado!"
    score=$((score + 8))
else
    ok "Kernel padrão"
fi

if su -c id >/dev/null 2>&1; then
    erro "ROOT ATIVO DETECTADO!"
    score=$((score + 15))
else
    ok "Sem root ativo visível"
fi

if ps -ef 2>/dev/null | grep -E "frida-server|magiskd|zygisk|shizuku|brevent" >/dev/null; then
    erro "Processos de hook/root em execução!"
    score=$((score + 12))
else
    ok "Processos limpos"
fi

# ===================== 3. PROPRIEDADES DO SISTEMA =====================
secao 3 "PROPRIEDADES DO SISTEMA (getprop)"

props=(
"ro.debuggable:1:Modo debug ativado"
"ro.secure:0:Segurança desativada"
"service.adb.root:1:ADB root ativo"
"ro.boot.veritymode:disabled:dm-verity desabilitado"
"ro.boot.verifiedbootstate:yellow:Boot modificado"
"ro.boot.flash.locked:0:Flash desbloqueado"
)

for p in "${props[@]}"; do
    prop=$(echo "$p" | cut -d: -f1)
    valor_sus=$(echo "$p" | cut -d: -f2)
    desc=$(echo "$p" | cut -d: -f3-)
    val=$(getprop "$prop" 2>/dev/null)
    if [ "$val" = "$valor_sus" ]; then
        erro "$desc → $prop = $val"
        score=$((score + 9))
    fi
done

# ===================== 4. DETECÇÃO AVANÇADA DE ROOT/HOOK =====================
secao 4 "DETECÇÃO DE MAGISK / KERNELSU / APATCH / HOOK"

for dir in /data/adb/magisk /sbin/.magisk /data/adb/ksu /data/adb/ap /data/adb/lspd /data/adb/modules; do
    if [ -e "$dir" ]; then
        erro "Diretório de root/hook encontrado: $dir"
        score=$((score + 10))
    fi
done

if pm list packages 2>/dev/null | grep -Ei "magisk|kernelsu|apatch|lsposed|frida|shamiko"; then
    erro "Pacotes de root/hook instalados detectados!"
    score=$((score + 10))
fi

# ===================== 5. LOGS DE PAREAMENTO / DESPAREAMENTO (seu foco principal) =====================
secao 5 "ANÁLISE COMPLETA DE LOGS DE PAREAMENTO / DESPAREAMENTO / ESQUECER"

LOGCAT_FULL=$(logcat -b all -d 2>/dev/null | tail -n 1000)
EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "AdbDebuggingManager|forget|unpair|remove|delete|esquecer|paired|connect|disconnect|brevent|shizuku|wireless.*debug|adb.*debug" | tail -n 500)

if [ -n "$EVENTS" ]; then
    echo "$EVENTS" | while read -r line; do
        ts=$(echo "$line" | awk '{print $1 " " $2}' 2>/dev/null || echo "$DATE")
        msg=$(echo "$line" | sed 's/.*: //')

        if echo "$line" | grep -qiE "forget|unpair|remove|delete|esquecer"; then
            erro "[DESPARELHADO / ESQUECIDO] $ts → $msg"
            echo "[AVISO FORTE] DESPARELHADO/ESQUECIDO → $ts | $line" >> "$RESULT_FILE"
            score=$((score + 15))
        elif echo "$line" | grep -qiE "pair|paired|connect"; then
            aviso "[PAREADO / CONECTADO] $ts → $msg"
            echo "[AVISO] PAREADO/CONECTADO → $ts | $line" >> "$RESULT_FILE"
            score=$((score + 8))
        elif echo "$line" | grep -qiE "brevent|shizuku"; then
            aviso "[BREVENT / SHIZUKU DETECTADO] $ts → $msg"
            echo "[AVISO] BREVENT/SHIZUKU → $ts | $line" >> "$RESULT_FILE"
            score=$((score + 12))
        else
            info "[EVENTO DE CONEXÃO] $ts → $msg"
            echo "[EVENTO] → $ts | $line" >> "$RESULT_FILE"
        fi
    done
else
    ok "Nenhum evento de pareamento/despareamento encontrado"
fi

# ===================== RESULTADO FINAL =====================
secao 6 "RESULTADO FINAL"

if [ $score -ge 40 ]; then
    status="💀 CRITICO - Dispositivo altamente comprometido"
elif [ $score -ge 25 ]; then
    status="🚨 SUSPEITO"
elif [ $score -ge 12 ]; then
    status="⚠️ ATENÇÃO"
else
    status="✅ LIMPO"
fi

echo -e "$(c bold branco)Score total: \( score \)(rst)"
echo -e "$(c bold)Status: \( status \)(rst)\n"

echo "📄 Relatório completo salvo em: $RESULT_FILE" | tee -a "$RESULT_FILE"

echo -e "\n\( (c bold ciano)╔════════════════════════════════════╗ \)(rst)"
echo -e "\( (c bold ciano)║         HOOKING DOMINA             ║ \)(rst)"
echo -e "\( (c bold ciano)╚════════════════════════════════════╝ \)(rst)"

echo ""
echo "Pressione ENTER para limpar o terminal..."
read -r

clear
reset
echo "Scan finalizado com sucesso."
