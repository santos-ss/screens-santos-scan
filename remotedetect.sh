cat > $HOME/scanner_remote.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# =============================================
# SCANNER BYPASS REMOTE v2 - Corrigido
# Detecta root + ADB + ADB Wireless (método REMOTE)
# =============================================

clear
echo "🔍 SCANNER BYPASS REMOTE v2 - Iniciando..."
echo "==========================================="

# 1. Root detection
echo -n "📌 Verificando ROOT... "
if command -v su >/dev/null 2>&1 && su -c 'id' 2>/dev/null | grep -q "uid=0"; then
    echo "✅ DETECTADO (root funcional)"
    ROOT=1
else
    echo "❌ Não encontrado"
    ROOT=0
fi

# 2. Depuração USB / ADB
ADB_ENABLED=$(settings get global adb_enabled 2>/dev/null || echo "0")
echo -n "📌 Depuração USB (ADB) ativada... "
[ "$ADB_ENABLED" = "1" ] && echo "✅ SIM" || echo "❌ NÃO"

# 3. Serviço adbd
ADBD_STATUS=$(getprop init.svc.adbd 2>/dev/null || echo "parado")
echo -n "📌 Serviço adbd rodando... "
[ "$ADBD_STATUS" = "running" ] && echo "✅ SIM" || echo "❌ $ADBD_STATUS"

# 4. ADB Wireless (porta TCP) - principal sinal do REMOTE
TCP_PORT=$(getprop service.adb.tcp.port 2>/dev/null || echo "0")
echo -n "📌 ADB Wireless (REMOTE) ativo... "
if [ "$TCP_PORT" != "0" ] && [ -n "$TCP_PORT" ]; then
    echo "✅ SIM (porta $TCP_PORT)"
    REMOTE_ALERT=1
else
    echo "❌ Não"
    REMOTE_ALERT=0
fi

# 5. Opções de Desenvolvedor
DEV=$(settings get global development_settings_enabled 2>/dev/null || echo "0")
echo -n "📌 Opções de Desenvolvedor... "
[ "$DEV" = "1" ] && echo "✅ Ativadas" || echo "❌ Desativadas"

# 6. Magisk ou root avançado
echo -n "📌 Magisk / Root avançado... "
if [ -d /data/adb/magisk ] || [ -f /data/adb/magisk.db ] || ls /data/adb/*magisk* >/dev/null 2>&1; then
    echo "✅ Detectado"
else
    echo "❌ Não encontrado"
fi

# 7. Processos ADB
echo -e "\n📌 Processos ADB em execução:"
ps -ef 2>/dev/null | grep -E 'adbd|adb' | grep -v grep || echo "   Nenhum processo ADB encontrado"

echo -e "\n==========================================="
echo "📋 RELATÓRIO FINAL"

if [ "$ROOT" = "1" ] || [ "$ADB_ENABLED" = "1" ] || [ "$ADBD_STATUS" = "running" ] || [ "$TCP_PORT" != "0" ]; then
    echo "🚨 ALERTA: Sinais de Bypass REMOTE detectados!"
    echo "   Isso é comum quando usam:"
    echo "   • Root avançado + ADB/USB"
    echo "   • Ou ADB Wireless (porta TCP aberta)"
    echo "   O aparelho pode ter sido usado com método REMOTE."
else
    echo "✅ Nenhum sinal claro do Bypass REMOTE encontrado."
fi

echo "==========================================="
echo "Script corrigido e melhorado ✅"
EOF

# Torna executável e cria link fácil
chmod +x $HOME/scanner_remote.sh

# Cria um link direto na pasta atual também (caso você esteja em outra pasta)
ln -sf $HOME/scanner_remote.sh ./scanner_remote.sh 2>/dev/null

echo "✅ Script criado com sucesso em: $HOME/scanner_remote.sh"
echo ""
echo "🚀 Como rodar agora:"
echo "   ./scanner_remote.sh          ← (se estiver na pasta home)"
echo "   ou"
echo "   $HOME/scanner_remote.sh"
echo ""
echo "Dica: Se quiser rodar de qualquer pasta, use:"
echo "   \~/scanner_remote.sh"
