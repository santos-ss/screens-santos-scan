cat > \~/scanner_remote.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# =============================================
# SCANNER DE BYPASS REMOTE (FRP / Conta Google)
# Feito para Termux - Detecta root + ADB + USB
# =============================================

clear
echo "🔍 SCANNER BYPASS REMOTE - Iniciando..."
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

# 2. ADB / Depuração USB
ADB_ENABLED=$(settings get global adb_enabled 2>/dev/null || echo "0")
echo -n "📌 Depuração USB (ADB) ativada... "
[ "$ADB_ENABLED" = "1" ] && echo "✅ SIM" || echo "❌ NÃO"

# 3. Serviço adbd
ADBD_STATUS=$(getprop init.svc.adbd 2>/dev/null || echo "parado")
echo -n "📌 Serviço adbd rodando... "
[ "$ADBD_STATUS" = "running" ] && echo "✅ SIM" || echo "❌ $ADBD_STATUS"

# 4. ADB Wireless (muito usado no REMOTE)
TCP_PORT=$(getprop service.adb.tcp.port 2>/dev/null || echo "0")
echo -n "📌 ADB Wireless (REMOTE) ativo... "
if [ "$TCP_PORT" != "0" ] && [ -n "$TCP_PORT" ]; then
    echo "✅ SIM (porta $TCP_PORT)"
else
    echo "❌ Não"
fi

# 5. Opções de Desenvolvedor
DEV=$(settings get global development_settings_enabled 2>/dev/null || echo "0")
echo -n "📌 Opções de Desenvolvedor... "
[ "$DEV" = "1" ] && echo "✅ Ativadas" || echo "❌ Desativadas"

# 6. Magisk / Root avançado (comum no "root muito bom")
echo -n "📌 Magisk / Root avançado... "
if [ -d /data/adb/magisk ] || ls /data/adb/*magisk* >/dev/null 2>&1 || [ -f /data/adb/magisk.db ]; then
    echo "✅ Detectado"
else
    echo "❌ Não encontrado"
fi

# 7. Processos ADB ativos
echo -e "\n📌 Processos ADB em execução:"
ps -ef | grep -E 'adbd|adb' | grep -v grep || echo "   Nenhum processo ADB encontrado"

echo -e "\n==========================================="
echo "📋 RELATÓRIO FINAL"

if [ "$ROOT" = "1" ] || [ "$ADB_ENABLED" = "1" ] || [ "$ADBD_STATUS" = "running" ] || [ "$TCP_PORT" != "0" ]; then
    echo "🚨 ALERTA: Possível Bypass REMOTE detectado!"
    echo "   O método REMOTE normalmente usa:"
    echo "   • Root avançado + ADB/USB ou"
    echo "   • ADB Wireless (porta TCP)"
    echo "   Dispositivo parece vulnerável ou já foi usado com o bypass."
else
    echo "✅ Nenhum sinal claro do Bypass REMOTE encontrado."
fi

echo "==========================================="
echo "Script feito por Grok para você 🔥"
EOF

# Torna executável
chmod +x \~/scanner_remote.sh
echo "✅ Script criado com sucesso!"
echo "🚀 Para rodar agora: ./scanner_remote.sh"
echo "   Ou depois: cd \~ && ./scanner_remote.sh"
