cat > hooking_sys.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
# =============================================
# HOOKING_SYS SCANNER
# Detecta Proxy, VPN, Jailbreak, Tweaks e Cheats
# =============================================

clear
echo -e "\e[1;36m🔍 HOOKING_SYS SCANNER\e[0m"
echo -e "\e[1;33m==========================================\e[0m"

REPORT="sysdiagnose_report_$(date +%Y%m%d_%H%M).txt"

echo "🔍 Iniciando análise completa..." | tee "$REPORT"

echo -e "\n📡 === PROXY ===" | tee -a "$REPORT"
grep -r -i -E "http_proxy|https_proxy|proxy|GlobalProxy|HTTPProxy" . --include="*.plist" --include="*.txt" --include="*.log" 2>/dev/null | head -20 | tee -a "$REPORT"

echo -e "\n🔒 === VPN / TUNNEL ===" | tee -a "$REPORT"
grep -r -i -E "VPN|NetworkExtension|tunnel|ikev2|wireguard|openvpn" . --include="*.plist" --include="*.log" 2>/dev/null | head -15 | tee -a "$REPORT"

echo -e "\n📋 === PERFIS DE CONFIGURAÇÃO ===" | tee -a "$REPORT"
grep -r -l "PayloadType" . --include="*.mobileconfig" --include="*.plist" 2>/dev/null | tee -a "$REPORT"

echo -e "\n🚩 === JAILBREAK / CHEATS / HOOKS ===" | tee -a "$REPORT"
grep -r -i -E "Cydia|Sileo|Zebra|substrate|MobileSubstrate|frida|dylib|gameguardian|lucky|cheat|hook|inject|tweak" . --include="*.log" --include="*.plist" 2>/dev/null | head -15 | tee -a "$REPORT"

echo -e "\n⚠️  === DYLIBS INJETADAS ===" | tee -a "$REPORT"
grep -r -i "\.dylib" . --include="*.log" 2>/dev/null | head -10 | tee -a "$REPORT"

echo -e "\n✅ Análise finalizada!" | tee -a "$REPORT"
echo -e "\e[1;32m📄 Relatório salvo: $REPORT\e[0m"
EOF
