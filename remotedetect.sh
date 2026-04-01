#!/bin/bash

echo "╔════════════════════════════════════╗"
echo "║         🔍 H O O K I N G           ║"
echo "╚════════════════════════════════════╝"

RESULT_FILE="/sdcard/hooking_result.txt"
DATE=$(date +"%Y-%m-%d %H:%M:%S")
score=0

echo ""
echo "📅 $DATE"
echo "──────────────────────────────"

# =====================
# KEYWORDS MELHORADOS
# =====================
LOG_KEYWORDS="AdbDebuggingManager|forget|unpair|remove.*device|delete.*device|forget.*device|paired.*device|wireless.*debug|brevent|shizuku|pairing|paired|connect|disconnect"

# =====================
# INICIALIZA RESULTADO
# =====================
echo "=== H O O K I N G   R E S U L T   -   $DATE ===" > "$RESULT_FILE"
echo "Data do scan: $DATE" >> "$RESULT_FILE"
echo "" >> "$RESULT_FILE"

# =====================
# ANÁLISE DE LOGS (mostra tudo na tela)
# =====================
echo ""
echo "🔗 [BUSCANDO PAREAMENTOS, DESPAREAMENTOS E ESQUECER DISPOSITIVO]"

LOGCAT_FULL=$(logcat -b all -d 2>/dev/null)
EVENTS=$(echo "$LOGCAT_FULL" | grep -iE "$LOG_KEYWORDS" | tail -n 500)

if [ -n "$EVENTS" ]; then
  echo "$EVENTS" | while read -r line; do
    timestamp=$(echo "$line" | awk '{print $1 " " $2}' 2>/dev/null || echo "$DATE")
    clean_msg=$(echo "$line" | sed 's/.*: //')

    if echo "$line" | grep -qiE "forget|unpair|remove.*device|delete.*device|esquecer"; then
      echo "   🟥 [DESPARELHADO / ESQUECIDO] $timestamp → $clean_msg"
      echo "[AVISO FORTE] DESPARELHADO / ESQUECIDO → $timestamp | $clean_msg" >> "$RESULT_FILE"
      score=$((score+15))
    elif echo "$line" | grep -qiE "brevent|shizuku"; then
      echo "   ⚠️  [BREVENT / SHIZUKU] $timestamp → $clean_msg"
      echo "[AVISO] BREVENT/SHIZUKU → $timestamp | $clean_msg" >> "$RESULT_FILE"
      score=$((score+10))
    elif echo "$line" | grep -qiE "pair|paired|connect"; then
      echo "   🟨 [PAREADO / CONECTADO] $timestamp → $clean_msg"
      echo "[AVISO] PAREADO/CONECTADO → $timestamp | $clean_msg" >> "$RESULT_FILE"
      score=$((score+7))
    else
      echo "   🔵 [EVENTO] $timestamp → $clean_msg"
      echo "[EVENTO] → $timestamp | $clean_msg" >> "$RESULT_FILE"
    fi
  done
else
  echo "✅ Nenhum evento de pareamento/despareamento encontrado no momento."
fi

echo "" >> "$RESULT_FILE"
echo "=== FIM DO RELATÓRIO ===" >> "$RESULT_FILE"

# Resultado final
echo ""
echo "════════ RESULTADO ════════"
echo "Score : $score"
if [ $score -ge 20 ]; then
  echo "Status: 💀 CRITICO"
elif [ $score -ge 10 ]; then
  echo "Status: 🚨 SUSPEITO"
else
  echo "Status: ✅ LIMPO"
fi

echo ""
echo "📄 Relatório salvo em: $RESULT_FILE"
echo "HOOKING DOMINA"

echo ""
echo "Pressione ENTER para sair..."
read -r
