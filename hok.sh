#!/bin/bash

echo "=============================="
echo "
H         H     OOOOO        OOOOO         K         K    ■   NN            N    GGGGGG
H         H   O               O   O              O      K    K                N   N         N    G
HHHHH   O               O   O              O      KK             II    N      N      N    G       GGG
H         H   O               O   O              O      K    K         II    N          N  N    G             G
H         H     OOOOO         OOOOO        K        K     II    N            NN    GGGGGG
"
echo "=============================="

pkg="com.dts.freefireth"

echo "OBB:"
latest_obb=$(ls -t /storage/emulated/0/Android/obb/$pkg/main.*.obb 2>/dev/null | head -1)
[ -n "$latest_obb" ] && stat "$latest_obb" | grep -E 'Access|Modify|Change'

echo "☆"
echo "Gameassetbundles:"
stat /storage/emulated/0/Android/data/$pkg/files/contentcache/Optional/android/gameassetbundles 2>/dev/null | grep -E 'Access|Modify|Change'

echo "☆"
echo "Shaders:"
latest_shader=$(ls -t /storage/emulated/0/Android/data/$pkg/files/contentcache/Optional/android/gameassetbundles/shaders* 2>/dev/null | head -1)
[ -n "$latest_shader" ] && stat "$latest_shader" | grep -E 'Access|Modify|Change'

echo "☆"
echo "Replay (.bin):"
latest_bin=$(ls -t /storage/emulated/0/Android/data/$pkg/files/MReplays/*.bin 2>/dev/null | head -1)
[ -n "$latest_bin" ] && stat "$latest_bin" | grep -E 'Access|Modify|Change'

echo "☆"
echo "Replay (.json):"
latest_json=$(ls -t /storage/emulated/0/Android/data/$pkg/files/MReplays/*.json 2>/dev/null | head -1)
[ -n "$latest_json" ] && stat "$latest_json" | grep -E 'Access|Modify|Change'

echo "☆"
versao=$(dumpsys package $pkg | grep versionName | cut -d= -f2)
echo "Versão instalada: $versao"
echo "Versão esperada: 1.120.1"

[ "$versao" = "1.120.1" ] && echo "Status versão: OK" || echo "Status versão: DIFERENTE"

echo "☆"
if [ -n "$latest_shader" ]; then
  size=$(du -m "$latest_shader" 2>/dev/null | awk '{print $1}')
  echo "Shaders: ${size}MB"
  [ "$size" -ge 1 ] && [ "$size" -le 3 ] && echo "Status shader: OK" || echo "Status shader: SUSPEITO"
else
  echo "Shaders não encontradas"
fi

echo "☆"
pid=$(pidof $pkg)
[ -n "$pid" ] && echo "Jogo rodando | PID: $pid" || echo "Jogo fechado"

echo "☆"
inst=$(pm list packages -i $pkg 2>/dev/null | sed -n 's/.*installer=\(.*\)/\1/p')
[ -z "$inst" ] && inst="desconhecido"
echo "Origem instalação: $inst"

echo "☆"
echo "USB / ADB:"
usb=$(getprop sys.usb.state)
adb=$(settings get global adb_enabled 2>/dev/null)
echo "USB: $usb"
[ "$adb" = "1" ] && echo "ADB: ATIVADO" || echo "ADB: DESATIVADO"

echo "☆"
echo "Scan apps suspeitos:"
pm list packages | grep -Ei "gameguardian|cheat|modmenu|lucky|virtual|parallel|xposed|magisk" \
&& echo "App suspeito encontrado" || echo "Nenhum app suspeito"

echo "☆"
echo "Replay recente:"
latest_replay=$(ls -t /storage/emulated/0/Android/data/$pkg/files/MReplays 2>/dev/null | head -1)
[ -n "$latest_replay" ] && echo "$latest_replay" || echo "Nenhum replay"

echo "==================================="
echo "
H         H     OOOOO        OOOOO         K         K    ■   NN            N    GGGGGG
H         H   O               O   O              O      K    K                N   N         N    G
HHHHH   O               O   O              O      KK             II    N      N      N    G       GGG
H         H   O               O   O              O      K    K         II    N          N  N    G             G
H         H     OOOOO         OOOOO        K        K     II    N            NN    GGGGGG
"
echo "==================================="
echo "developed by hooking"
