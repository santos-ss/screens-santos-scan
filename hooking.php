<?php

declare(strict_types=1);


const C = [
    'rst'      => "\e[0m",
    'bold'     => "\e[1m",
    'branco'   => "\e[97m",
    'cinza'    => "\e[37m",
    'preto'    => "\e[30m\e[1m",
    'vermelho' => "\e[91m",
    'verde'    => "\e[92m",
    'fverde'   => "\e[32m",
    'amarelo'  => "\e[93m",
    'laranja'  => "\e[38;5;208m",
    'azul'     => "\e[34m",
    'ciano'    => "\e[36m",
    'magenta'  => "\e[35m",
];



function c(string ...$nomes): string
{
    return implode('', array_map(fn($n) => C[$n] ?? '', $nomes));
}

function rst(): string
{
    return C['rst'];
}

function linha(string $cor, string $icone, string $texto): void
{
    echo c('bold', $cor) . "  $icone $texto\n" . rst();
}

function ok(string $texto): void     { linha('verde',    '✓', $texto); }
function erro(string $texto): void   { linha('vermelho', '✗', $texto); }
function aviso(string $texto): void  { linha('amarelo',  '⚠', $texto); }
function info(string $texto): void   { linha('fverde',   'ℹ', $texto); }
function detalhe(string $texto): void
{
    echo c('bold', 'amarelo') . "    $texto\n" . rst();
}

function secao(int $num, string $titulo): void
{
    $sep = str_repeat('─', mb_strlen($titulo) + 4);
    echo "\n" . c('bold', 'azul') . "  ► [$num] $titulo\n  $sep\n" . rst();
}

function cabecalho(string $titulo): void
{
    echo "\n" . c('bold', 'ciano') . "  $titulo\n  " . str_repeat('=', mb_strlen($titulo)) . "\n\n" . rst();
}

function inputUsuario(string $mensagem): void
{
    echo c('rst', 'bold', 'ciano') . "  ▸ $mensagem: " . c('fverde');
}


function kellerBanner(): void
{
    echo c('branco') . "
  " . c('branco') . "KellerSS Android " . c('ciano') . "Fucking Cheaters" . c('branco') . "
  " . c('cinza') . "discord.gg/allianceoficial" . c('branco') . "

  )       (     (          (
  ( /(       )\ )  )\ )       )\ )
  )\()) (   (()/( (()/(  (   (()/(
  |((_)\  )\   /(_)) /(_)) )\   /(_))
  |_ ((_)((_) (_))  (_))  ((_) (_))
  | |/ / | __|| |   | |   | __|| _ \\
  ' <  | _| | |__ | |__ | _| |   /
  _|\_\\ |___||____||____||___||_|_\\

  " . c('ciano') . "Coded By: KellerSS | Credits: Sheik" . rst() . "\n\n";
}



function garantirPermissoesBinarios(): void
{
    $binarios = [
        '/data/data/com.termux/files/usr/bin/adb',
        '/data/data/com.termux/files/usr/bin/clear',
    ];
    foreach ($binarios as $bin) {
        if (file_exists($bin)) {
            @chmod($bin, 0755);
        }
    }
}



function adb(string $cmd): string
{
    return trim((string) shell_exec($cmd . ' 2>/dev/null'));
}



function statTimestamps(string $caminho): ?array
{
    $raw = adb('adb shell "stat ' . escapeshellarg($caminho) . '"');
    if (empty($raw)) return null;

    $limpar = fn(string $v): string => trim(preg_replace('/ [+-]\d{4}$/', '', $v));

    preg_match('/Access: (.*?)\n/', $raw, $mA);
    preg_match('/Modify: (.*?)\n/', $raw, $mM);
    preg_match('/Change: (.*?)\n/', $raw, $mC);

    if (!isset($mA[1], $mM[1], $mC[1])) return null;

    return [
        'access' => $limpar($mA[1]),
        'modify' => $limpar($mM[1]),
        'change' => $limpar($mC[1]),
    ];
}


function atualizar(): void
{
    echo "\n" . c('bold', 'azul') . "  ┌─ KELLERSS UPDATER\n" . rst();
    echo c('vermelho') . "  ⟳ Atualizando, aguarde...\n\n" . rst();
    system('git fetch origin && git reset --hard origin/master && git clean -f -d');
    echo c('bold', 'fverde') . "  ✓ Atualização concluída! Reinicie o scanner\n" . rst();
    exit;
}



function verificarDispositivoADB(): bool
{
    garantirPermissoesBinarios();

    $output  = (string) shell_exec('adb devices');
    $linhas  = array_slice(explode("\n", trim($output)), 1);
    $devices = [];

    foreach ($linhas as $linha) {
        $linha = trim($linha);
        if (!empty($linha) && strpos($linha, 'device') !== false) {
            $partes = preg_split('/\s+/', $linha);
            if (isset($partes[0])) {
                $devices[] = $partes[0];
            }
        }
    }

    $total = count($devices);

    if ($total === 0) {
        erro("Nenhum dispositivo encontrado.");
        erro("Faça o pareamento de IP ou conecte um dispositivo via USB.");
        exit(1);
    }

    if ($total > 1) {
        erro("Mais de um dispositivo/emulador conectado.");
        erro("Desconecte os outros dispositivos e mantenha apenas um.");
        foreach ($devices as $dev) {
            echo "    - $dev\n";
        }
        exit(1);
    }

    shell_exec('adb shell "chmod 755 /data/data/com.termux/files/usr/bin/clear 2>/dev/null"');
    return true;
}


function detectarBypassShell(): bool
{
    $bypassDetectado   = false;
    $totalVerificacoes = 0;
    $problemasTotal    = 0;

    cabecalho('ANÁLISE COMPLETA DE SEGURANÇA DO DISPOSITIVO');

    secao(1, 'VERIFICANDO DISPOSITIVO CONECTADO');

    $devices = adb('adb devices');
    if (empty($devices) || strpos($devices, 'device') === false || strpos($devices, 'unauthorized') !== false) {
        erro("Nenhum dispositivo detectado ou sem autorização!");
        return false;
    }

    $check = adb('adb shell "ls /sdcard"');
    if (strpos($check, 'Permission denied') !== false) {
        erro("ADB sem permissões suficientes!");
        return false;
    }

    ok("Dispositivo conectado com permissões adequadas");

    secao(2, 'VERIFICANDO ESTADO DE BOOT VERIFICADO');

    $bootState = adb('adb shell getprop ro.boot.verifiedbootstate');
    $totalVerificacoes++;

    match ($bootState) {
        'yellow' => (function () use (&$bypassDetectado, &$problemasTotal) {
            aviso("Boot State: YELLOW — Suspeita de modificação no sistema");
            $bypassDetectado = true; $problemasTotal++;
        })(),
        'orange' => (function () use (&$bypassDetectado, &$problemasTotal) {
            erro("Boot State: ORANGE — Bootloader desbloqueado detectado");
            $bypassDetectado = true; $problemasTotal++;
        })(),
        'green'  => ok("Boot State: GREEN — Sistema verificado"),
        default  => aviso("Boot State: $bootState (Desconhecido)"),
    };


    secao(3, 'VERIFICANDO STATUS DO SELINUX');

    $selinux = adb('adb shell getenforce');
    $totalVerificacoes++;

    match ($selinux) {
        'Permissive' => (function () use (&$bypassDetectado, &$problemasTotal) {
            erro("SELinux: PERMISSIVE — Modo permissivo detectado (comum em dispositivos rooteados)");
            $bypassDetectado = true; $problemasTotal++;
        })(),
        'Enforcing'  => ok("SELinux: ENFORCING — Modo de segurança ativo"),
        default      => aviso("SELinux: $selinux (Status desconhecido)"),
    };


    secao(4, 'VERIFICANDO PROPRIEDADES DO SISTEMA');

    $propriedades = [
        'ro.debuggable'           => ['1',        'Modo debug ativado'],
        'ro.secure'               => ['0',        'Segurança desativada'],
        'service.adb.root'        => ['1',        'ADB root ativo'],
        'ro.build.selinux'        => ['0',        'SELinux desabilitado'],
        'ro.boot.flash.locked'    => ['0',        'Flash desbloqueado'],
        'ro.boot.veritymode'      => ['disabled', 'dm-verity desabilitado'],
        'sys.oem_unlock_allowed'  => ['1',        'OEM unlock permitido'],
        'persist.sys.usb.config'  => ['adb',      'ADB persistente ativo'],
        'ro.kernel.qemu'          => ['1',        'Emulador detectado'],
    ];

    foreach ($propriedades as $prop => [$valorSuspeito, $descricao]) {
        $valor = adb("adb shell getprop " . escapeshellarg($prop));
        if ($valor === $valorSuspeito) {
            erro("Propriedade suspeita: $prop = $valor ($descricao)");
            $bypassDetectado = true;
            $problemasTotal++;
        }
        $totalVerificacoes++;
    }

    ok("Verificação de propriedades concluída");

    secao(5, 'VERIFICANDO BINÁRIOS SU (SUPERUSUÁRIO)');

    $binariosSU = [
        '/system/bin/su', '/system/xbin/su', '/sbin/su', '/system/su',
        '/system/bin/.ext/.su', '/data/local/su', '/data/local/bin/su',
        '/data/local/xbin/su', '/su/bin/su', '/system/sbin/su',
        '/vendor/bin/su', '/system/app/Superuser.apk',
        '/data/adb/magisk', '/data/adb/ksu', '/data/adb/ap',
        '/cache/su', '/dev/com.koushikdutta.superuser.daemon',
    ];

    $suEncontrado = false;
    foreach ($binariosSU as $bin) {
        $r = adb('adb shell "test -f ' . escapeshellarg($bin) . ' && echo FOUND || echo NOTFOUND"');
        if ($r === 'FOUND') {
            erro("Binário SU encontrado: $bin");
            $bypassDetectado = true;
            $suEncontrado    = true;
            $problemasTotal++;
        }
        $totalVerificacoes++;
    }

    if (!$suEncontrado) ok("Nenhum binário SU encontrado");


    secao(6, 'DETECÇÃO AVANÇADA DE MAGISK');

    $magiskDetectado = false;

    $pkgs = adb(
        'adb shell "found=; for p in com.topjohnwu.magisk io.github.huskydg.magisk io.github.magisk; do' .
        ' r=\$(pm path \"\$p\" 2>/dev/null); case \"\$r\" in package:*) found=\"\$found|\$p\";; esac; done; echo \"\$found\""'
    );
    if (!empty(trim($pkgs, "| \n"))) {
        erro("Pacote Magisk encontrado:");
        detalhe(trim($pkgs, "| \n"));
        $bypassDetectado = $magiskDetectado = true;
        $problemasTotal++;
    }

    foreach (['/data/adb/magisk', '/sbin/.magisk', '/data/adb/modules', '/cache/magisk.log'] as $dir) {
        $r = adb('adb shell "test -e ' . escapeshellarg($dir) . ' && echo FOUND || echo NOTFOUND"');
        if ($r === 'FOUND') {
            erro("Diretório/arquivo Magisk encontrado: $dir");
            $bypassDetectado = $magiskDetectado = true;
            $problemasTotal++;
        }
        $totalVerificacoes++;
    }

   
    $procs = adb(
        'adb shell "found=; for f in /proc/[0-9]*/comm; do' .
        ' [ -r \"\$f\" ] || continue; read -r n < \"\$f\" 2>/dev/null;' .
        ' case \"\$n\" in *magisk*|*magiskd*) found=\"\$found|\$n\";; esac;' .
        ' done; echo \"\$found\""'
    );
    if (!empty(trim($procs, "| \n"))) {
        erro("Processo Magisk em execução:");
        detalhe(trim($procs, "| \n"));
        $bypassDetectado = $magiskDetectado = true;
        $problemasTotal++;
    }

  
    $mounts = adb(
        'adb shell "found=; while IFS= read -r line; do' .
        ' case \"\$line\" in *magisk*) found=\"\$line\"; break;; esac;' .
        ' done < /proc/mounts; echo \"\$found\""'
    );
    if (!empty($mounts)) {
        erro("Mountpoint Magisk detectado:");
        detalhe($mounts);
        $bypassDetectado = $magiskDetectado = true;
        $problemasTotal++;
    }

    if (!$magiskDetectado) ok("Nenhum vestígio de Magisk encontrado");


    secao(7, 'DETECÇÃO DE KERNELSU');

    $ksuDetectado = false;

   
    $kmod = adb(
        'adb shell "found=; while IFS= read -r line; do' .
        ' case \"\$line\" in *[Kk]ernel[Ss][Uu]*|*ksu_*) found=\"\$line\"; break;; esac;' .
        ' done < /proc/modules; echo \"\$found\""'
    );
    if (!empty($kmod)) {
        erro("Módulo KernelSU no kernel:");
        detalhe($kmod);
        $bypassDetectado = $ksuDetectado = true;
        $problemasTotal++;
    }

    foreach (['/data/adb/ksud', '/data/adb/ksu', '/proc/kernelsu'] as $file) {
        $r = adb('adb shell "test -e ' . escapeshellarg($file) . ' && echo FOUND || echo NOTFOUND"');
        if ($r === 'FOUND') {
            erro("Arquivo/diretório KernelSU encontrado: $file");
            $bypassDetectado = $ksuDetectado = true;
            $problemasTotal++;
        }
        $totalVerificacoes++;
    }

 
    $kver = adb(
        'adb shell "read -r ver < /proc/version 2>/dev/null;' .
        ' case \"\$ver\" in *ksu*|*KSU*|*KernelSU*) echo \"\$ver\";; esac"'
    );
    if (!empty($kver)) {
        erro("Kernel modificado com KernelSU:");
        detalhe($kver);
        $bypassDetectado = $ksuDetectado = true;
        $problemasTotal++;
    }

    if (!$ksuDetectado) ok("Nenhum vestígio de KernelSU encontrado");


    secao(8, 'DETECÇÃO DE APATCH');

    $apatchDetectado = false;

    $apPkgs = adb(
        'adb shell "found=; for p in me.bmax.apatch me.bmax.apatch.release; do' .
        ' r=\$(pm path \"\$p\" 2>/dev/null); case \"\$r\" in package:*) found=\"\$found|\$p\";; esac; done; echo \"\$found\""'
    );
    if (!empty(trim($apPkgs, "| \n"))) {
        erro("Pacote APatch encontrado:");
        detalhe(trim($apPkgs, "| \n"));
        $bypassDetectado = $apatchDetectado = true;
        $problemasTotal++;
    }

    if (adb('adb shell "test -d /data/adb/ap && echo FOUND || echo NOTFOUND"') === 'FOUND') {
        erro("Diretório APatch encontrado: /data/adb/ap");
        $bypassDetectado = $apatchDetectado = true;
        $problemasTotal++;
    }

   
    $apProp = adb(
        'adb shell "getprop 2>/dev/null | { found=; while IFS= read -r l; do' .
        ' case \"\$l\" in *[Aa]patch*) found=\"\$l\"; break;; esac;' .
        ' done; echo \"\$found\"; }"'
    );
    if (!empty($apProp)) {
        erro("Propriedade APatch encontrada:");
        detalhe($apProp);
        $bypassDetectado = $apatchDetectado = true;
        $problemasTotal++;
    }

    if (!$apatchDetectado) ok("Nenhum vestígio de APatch encontrado");


    secao(9, 'ANÁLISE DE LOGS DO KERNEL E SISTEMA');

   
    $logChecks = [
        'Logcat Kernel'     =>
            'adb shell "logcat -b kernel -d 2>/dev/null |' .
            ' { while IFS= read -r l; do case \"\$l\" in' .
            ' *kernelsu*|*KernelSU*|*magisk*|*Magisk*|*apatch*|*APatch*)' .
            ' printf \'%s\\n\' \"\$l\"; break;; esac; done; }"',

        'Dumpsys Package'   =>
            'adb shell "dumpsys package 2>/dev/null |' .
            ' { while IFS= read -r l; do case \"\$l\" in' .
            ' *kernelsu*|*KernelSU*|*magisk*|*Magisk*|*apatch*|*APatch*)' .
            ' case \"\$l\" in *queriesPackages*|*KernelSupport*|*Freecess*|*ChinaPolicy*) ;;' .
            ' *) printf \'%s\\n\' \"\$l\"; break;; esac;; esac; done; }"',

        'Dumpsys Activity'  =>
            'adb shell "dumpsys activity 2>/dev/null |' .
            ' { while IFS= read -r l; do case \"\$l\" in' .
            ' *kernelsu*|*KernelSU*|*magisk*|*Magisk*|*apatch*|*APatch*)' .
            ' case \"\$l\" in *queriesPackages*|*KernelSupport*|*Freecess*|*ChinaPolicy*) ;;' .
            ' *) printf \'%s\\n\' \"\$l\"; break;; esac;; esac; done; }"',

        'Dumpsys Processes' =>
            'adb shell "dumpsys activity processes 2>/dev/null |' .
            ' { while IFS= read -r l; do case \"\$l\" in' .
            ' *kernelsu*|*KernelSU*|*magisk*|*Magisk*|*apatch*|*APatch*)' .
            ' printf \'%s\\n\' \"\$l\"; break;; esac; done; }"',
    ];

    $logDetectado = false;
    foreach ($logChecks as $nome => $cmd) {
        $out = adb($cmd);
        if (!empty($out)) {
            erro("Root detectado em $nome:");
            detalhe(substr($out, 0, 200) . '...');
            $bypassDetectado = $logDetectado = true;
            $problemasTotal++;
        }
        $totalVerificacoes++;
    }

    if (!$logDetectado) ok("Logs do sistema limpos");

    secao(10, 'DETECÇÃO DE FRAMEWORKS DE HOOK');

    $hookFrameworks = [
        'Xposed'    => [
            ['cmd' =>
                'adb shell "found=; for p in de.robv.android.xposed.installer io.github.xposed.installer; do' .
                ' r=\$(pm path \"\$p\" 2>/dev/null); case \"\$r\" in package:*) found=\"\$found|\$p\";; esac; done; echo \"\$found\""',
             'tipo' => 'output'],
            ['cmd' => 'adb shell "test -f /system/framework/XposedBridge.jar && echo FOUND || echo NOTFOUND"', 'tipo' => 'found'],
        ],
        'LSPosed'   => [
            ['cmd' =>
                'adb shell "found=; for p in io.github.lsposed.manager org.lsposed.manager; do' .
                ' r=\$(pm path \"\$p\" 2>/dev/null); case \"\$r\" in package:*) found=\"\$found|\$p\";; esac; done; echo \"\$found\""',
             'tipo' => 'output'],
            ['cmd' => 'adb shell "test -d /data/adb/lspd && echo FOUND || echo NOTFOUND"', 'tipo' => 'found'],
        ],
        'EdXposed'  => [
            ['cmd' =>
                'adb shell "r=\$(pm path io.github.edxp.lsposed 2>/dev/null); case \"\$r\" in package:*) echo \"\$r\";; esac"',
             'tipo' => 'output'],
        ],
        'Frida'     => [
            
            ['cmd' =>
                'adb shell "found=; for f in /proc/[0-9]*/comm; do' .
                ' [ -r \"\$f\" ] || continue; read -r n < \"\$f\" 2>/dev/null;' .
                ' case \"\$n\" in *frida*) found=\"\$found|\$n\";; esac;' .
                ' done; echo \"\$found\""',
             'tipo' => 'output'],
          
            ['cmd' =>
                'adb shell "found=; for f in /proc/net/tcp /proc/net/tcp6; do' .
                ' [ -r \"\$f\" ] || continue;' .
                ' while IFS= read -r l; do case \"\$l\" in *:699[Aa]*) found=\"\$l\"; break;; esac; done < \"\$f\";' .
                ' done; echo \"\$found\""',
             'tipo' => 'output'],
        ],
        'Substrate' => [
            ['cmd' =>
                'adb shell "r=\$(pm path com.saurik.substrate 2>/dev/null); case \"\$r\" in package:*) echo \"\$r\";; esac"',
             'tipo' => 'output'],
        ],
    ];

    $hookDetectado = false;
    foreach ($hookFrameworks as $framework => $checks) {
        foreach ($checks as ['cmd' => $cmd, 'tipo' => $tipo]) {
            $out = adb($cmd);
            $detectado = match ($tipo) {
                'found'  => $out === 'FOUND',
                'output' => !empty($out),
                default  => false,
            };
            if ($detectado) {
                erro("Framework de hook detectado: $framework");
                detalhe("Detalhes: " . substr($out, 0, 100));
                $bypassDetectado = $hookDetectado = true;
                $problemasTotal++;
                break;
            }
            $totalVerificacoes++;
        }
    }

    if (!$hookDetectado) ok("Nenhum framework de hook detectado");


    secao(11, 'VERIFICANDO FUNÇÕES SHELL SOBRESCRITAS');

    $funcoesTeste = ['pkg', 'git', 'cd', 'stat', 'adb', 'ls', 'cat', 'pm'];
    $funcaoSobrescrita = false;

    foreach ($funcoesTeste as $funcao) {
       
        $r = adb('adb shell "case \"\$(type ' . $funcao . ' 2>/dev/null)\" in *function*) echo FUNCTION_DETECTED;; esac"');
        if (strpos($r, 'FUNCTION_DETECTED') !== false) {
            erro("BYPASS DETECTADO: Função '$funcao' foi sobrescrita!");
            $bypassDetectado = $funcaoSobrescrita = true;
            $problemasTotal++;
        }
        $totalVerificacoes++;
    }

    if (!$funcaoSobrescrita) ok("Todas as funções shell estão normais");


    secao(12, 'TESTANDO ACESSO A DIRETÓRIOS CRÍTICOS');

    $diretorios = [
        '/system/bin'                                    => 'Binários do sistema',
        '/data/data/com.dts.freefireth/files'            => 'Dados Free Fire TH',
        '/data/data/com.dts.freefiremax/files'           => 'Dados Free Fire MAX',
        '/storage/emulated/0/Android/data'               => 'Dados de aplicativos',
        '/data/adb'                                      => 'Diretório ADB',
        '/system/xbin'                                   => 'Binários estendidos',
    ];

    
    $acessoBloqueado = false;
    foreach ($diretorios as $dir => $desc) {
        $r = adb('adb shell "[ -d \"' . $dir . '\" ] && [ -r \"' . $dir . '\" ] && echo ACCESS_OK || echo NOT_OK"');
        if ($r !== 'ACCESS_OK') {
            aviso("Sem acesso ao diretório: $dir ($desc)");
        }
        $totalVerificacoes++;
    }

    if (!$acessoBloqueado) ok("Acesso aos diretórios está normal");


    secao(13, 'VERIFICANDO PROCESSOS SUSPEITOS');

   
    $rawProcs = adb(
        'adb shell "found=; for f in /proc/[0-9]*/comm; do' .
        ' [ -r \"\$f\" ] || continue; read -r n < \"\$f\" 2>/dev/null;' .
        ' case \"\$n\" in *bypass*|*redirect*|*fake_*|*hide_*|*cloak*|*stealth*)' .
        ' case \"\$n\" in *drm_fake*|*mtk_drm_fake*) ;;' .
        ' *) found=\"\$found|\$n\";; esac;; esac;' .
        ' done; echo \"\$found\""'
    );

    $processosSuspeitos = array_values(array_filter(explode('|', $rawProcs)));

    if (!empty($processosSuspeitos)) {
        erro("PROCESSOS SUSPEITOS DETECTADOS:");
        foreach ($processosSuspeitos as $proc) {
            detalhe("• $proc");
        }
        $bypassDetectado = true;
        $problemasTotal++;
    } else {
        ok("Nenhum processo suspeito encontrado");
    }
    $totalVerificacoes++;


    secao(14, 'VERIFICAÇÃO DE REDE E APPS SUSPEITOS');

   
    $interfaces = adb(
        'adb shell "found=; for iface in tun0 ppp0 wg0; do' .
        ' [ -d \"/sys/class/net/\$iface\" ] && found=\"\$found|\$iface\";' .
        ' done; echo \"\$found\""'
    );
    if (!empty(trim($interfaces, "| \n"))) {
        erro("VPN/Tunelamento Detectado (Pode ocultar tráfego):");
        detalhe(trim($interfaces, "| \n"));
        $bypassDetectado = true;
        $problemasTotal++;
    } else {
        ok("Nenhuma interface VPN ativa encontrada");
    }

    $privateDns = adb('adb shell "settings get global private_dns_mode"');
    $dns1       = adb('adb shell "getprop net.dns1"');

    if ($privateDns === 'hostname' || (!in_array($privateDns, ['off', 'null', ''], true) && !empty($privateDns))) {
        aviso("DNS Privado Ativo (Mode: $privateDns) — Verifique se não bloqueia logs");
        $problemasTotal++;
    } elseif (in_array($dns1, ['1.1.1.1', '8.8.8.8', '9.9.9.9'], true)) {
        aviso("DNS Público Detectado ($dns1) — Atenção para redirecionamentos");
    } else {
        ok("Configuração de DNS aparentemente normal");
    }

    $appsSuspeitos = [
        'moe.shizuku.privileged.api'   => 'Shizuku (API)',
        'shizuku.service'              => 'Shizuku (Service)',
        'com.lexa.fakegps'             => 'Fake GPS',
        'com.incorporateapps.fakegps.fre' => 'Fake GPS Free',
        'com.lbe.parallel'             => 'Parallel Space',
        'com.excelliance.multiaccounts'=> 'Multi Accounts',
        'trickystore'                  => 'TrickyStore (Bypass)',
        'shamiko'                      => 'Shamiko (Hide Root)',
    ];

    $pacotesInstalados = adb('adb shell "pm list packages"');
    $appDetectado      = false;

    foreach ($appsSuspeitos as $pkg => $nome) {
        if (strpos($pacotesInstalados, $pkg) !== false) {
            aviso("App Suspeito Instalado: $nome ($pkg)");
            $appDetectado = true;
            $problemasTotal++;
        }
    }

    if (!$appDetectado) ok("Nenhum app de manipulação conhecido encontrado");


    secao(15, 'VERIFICANDO ARQUIVOS EM /DATA/LOCAL/TMP');

  
    $checkPerm = adb('adb shell "[ -r /data/local/tmp ] && echo ACCESS_OK || echo DENIED"');
    if ($checkPerm === 'DENIED') {
        erro("[!] ACESSO NEGADO: Não é possível ler /data/local/tmp!");
        echo c('bold', 'amarelo') . "      O usuário removeu permissões de leitura para ocultar arquivos.\n";
        echo c('bold', 'amarelo') . "      Aplique o W.O imediatamente.\n" . rst();
        $bypassDetectado = true;
        $problemasTotal++;
    } else {
        $statDir    = adb('adb shell "stat /data/local/tmp"');
        $dirTs      = 0;
        if (preg_match('/Modify:\s+(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})/', $statDir, $m)) {
            $dirTs = strtotime($m[1]);
        }

        
        $tmpFiles = adb(
            'adb shell "for f in /data/local/tmp/* /data/local/tmp/.*; do' .
            ' n=\"\${f##*/}\"; case \"\$n\" in \'.\' | \'..\') ;; *)' .
            ' [ -e \"\$f\" ] && echo \"\$n\";; esac; done"'
        );
        $maxFileTs = 0;

        if (!empty($tmpFiles)) {
            aviso("Arquivos encontrados em /data/local/tmp:");

            $assinaturas = [
                'mantis'    => 'Mantis Gamepad (Keymapper - Proibido)',
                'buddy'     => 'Mantis/Panda Activator (Keymapper)',
                'panda'     => 'Panda Mouse Pro (Keymapper - Proibido)',
                'vysor'     => 'Vysor (Espelhamento/Controle - Suspeito)',
                'scrcpy'    => 'Scrcpy (Espelhamento - Suspeito)',
                'frida'     => 'Frida Server (Ferramenta de Hooking)',
                'magisk'    => 'Magisk Root (Arquivo Residual)',
                'busybox'   => 'BusyBox (Ferramenta de Sistema)',
                'su'        => 'Binário SU (Root)',
                'brevent'   => 'Brevent Script (Script de Otimização/Cheat)',
                'termux'    => 'Script Termux (Possível Script)',
                'holograma' => 'Holograma (Visual Skin/Cheat)',
                '.sh'       => 'Script Shell (Possível Brevent/Otimizador)',
                '2'         => 'Script Temporário Genérico (Ativação Keymapper)',
            ];

            $arquivos = array_filter(explode("\n", $tmpFiles));
            $count    = 0;

            foreach ($arquivos as $f) {
                $f = trim($f);
                if (empty($f)) continue;

                $statF = adb('adb shell "stat /data/local/tmp/' . escapeshellarg($f) . '"');
                if (preg_match('/Modify:\s+(\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2})/', $statF, $fm)) {
                    $ft = strtotime($fm[1]);
                    if ($ft > $maxFileTs) $maxFileTs = $ft;
                }

                $identificado = false;
                foreach ($assinaturas as $sig => $desc) {
                    if (stripos($f, $sig) !== false) {
                        erro("DETECTADO: $f → $desc");
                        $identificado    = true;
                        $bypassDetectado = true;
                        break;
                    }
                }
                if (!$identificado && $count < 5) {
                    detalhe("• $f (Arquivo desconhecido)");
                }
                $count++;
            }

            if ($count > 5) detalhe("• ... e mais " . ($count - 5) . " arquivos");
            $problemasTotal++;
        } else {
            ok("Pasta /data/local/tmp limpa");
        }

        if ($dirTs > 0 && $maxFileTs > 0 && ($dirTs > $maxFileTs + 10)) {
            echo "\n";
            erro("[!] ALERTA: Modificação recente em /data/local/tmp sem arquivo correspondente!");
            aviso("     O diretório foi modificado APÓS o último arquivo — possível limpeza de rastros.");
            echo c('bold', 'branco') . "      Modificação do Dir: " . date("H:i:s", $dirTs) . "\n";
            echo c('bold', 'branco') . "      Último Arquivo:     " . date("H:i:s", $maxFileTs) . "\n" . rst();
            $bypassDetectado = true;
            $problemasTotal++;
        }
    }
    $totalVerificacoes++;

    secao(16, 'VERIFICANDO APLICATIVOS DESINSTALADOS SUSPEITOS');


    $logUninstall = adb(
        'adb shell "logcat -d -v time -s ActivityManager:I PackageManager:I 2>/dev/null |' .
        ' { while IFS= read -r l; do case \"\$l\" in' .
        ' *deletePackageX*|*pkg\ removed*) printf \'%s\\n\' \"\$l\";; esac; done; }"'
    );
    $appsRemovidos = [];

    if (!empty($logUninstall)) {
        $now         = new DateTime();
        $umaHoraAtras = (clone $now)->modify('-1 hour');
        $anoAtual    = date('Y');

        foreach (explode("\n", $logUninstall) as $linha) {
            if (!preg_match(
                '/^(\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d{3}).*?Force stopping\s+([^\s]+)\s+appid=\d+\s+user=(\d+):\s*(deletePackageX|pkg removed)/i',
                $linha, $m
            )) continue;

            if (strcasecmp($m[4], 'deletePackageX') !== 0) continue;

            $logDate = DateTime::createFromFormat('Y-m-d H:i:s.u', "$anoAtual-$m[1]");
            if (!$logDate) continue;
            if ($logDate > $now) $logDate->modify('-1 year');
            if ($logDate < $umaHoraAtras || $logDate > $now) continue;

            $pkgName  = $m[2];
            $user     = $m[3];
            $wasManual = false;

            $manualCheck = adb(
                'adb shell "logcat -d -v time 2>/dev/null |' .
                ' { while IFS= read -r l; do case \"\$l\" in' .
                ' *android.intent.action.DELETE*|*UninstallerActivity*)' .
                ' case \"\$l\" in *' . $pkgName . '*) printf \'%s\\n\' \"\$l\"; break;; esac;; esac; done; }"'
            );
            if (!empty($manualCheck) && preg_match('/(\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\.\d{3})/', $manualCheck, $mm)) {
                $manualDate = DateTime::createFromFormat('Y-m-d H:i:s.u', "$anoAtual-$mm[1]");
                if ($manualDate) {
                    if ($manualDate > $now) $manualDate->modify('-1 year');
                    $diff = $logDate->getTimestamp() - $manualDate->getTimestamp();
                    if ($diff >= 0 && $diff <= 20) $wasManual = true;
                }
            }

            if (!$wasManual) {
                $key = $pkgName . '_' . $logDate->format('YmdHis');
                if (!isset($appsRemovidos[$key])) {
                    $appsRemovidos[$key] = [
                        'pkg'    => $pkgName,
                        'time'   => $logDate->format('d/m/Y H:i:s'),
                        'user'   => $user,
                        'method' => 'Comando/Script (SEM interface gráfica)',
                    ];
                }
            }
        }
    }

    if (!empty($appsRemovidos)) {
        foreach ($appsRemovidos as $info) {
            erro("[!] DESINSTALAÇÃO SUSPEITA DETECTADA!");
            echo c('bold', 'amarelo') . "      Pacote:  {$info['pkg']}\n";
            echo c('bold', 'amarelo') . "      Horário: {$info['time']}\n";
            echo c('bold', 'amarelo') . "      Usuário: {$info['user']}\n";
            echo c('bold', 'vermelho') . "      Método:  {$info['method']}\n";
            echo c('bold', 'vermelho') . "      ⚠️  Desinstalação via comando (possível bypass de root)\n" . rst();
        }
        $bypassDetectado = true;
        $problemasTotal++;
    } else {
        ok("Nenhuma desinstalação suspeita detectada (1h)");
        echo c('bold', 'verde') . "      (Desinstalações manuais são ignoradas)\n" . rst();
    }
    $totalVerificacoes++;

    echo "\n" . c('bold', 'ciano') . "  ► RESUMO DA ANÁLISE\n  -------------------\n\n" . rst();
    echo c('bold', 'branco') . "  Total de verificações: $totalVerificacoes\n";
    echo c('bold', 'branco') . "  Problemas encontrados: $problemasTotal\n\n" . rst();

    if ($bypassDetectado) {
        echo "\n" . c('bold', 'vermelho') . "  ⚠️  ATENÇÃO: MODIFICAÇÕES DETECTADAS! ⚠️\n";
        echo c('bold', 'vermelho') . "  ----------------------------------------\n";
        echo c('bold', 'vermelho') . "  Root, bypass ou hooks foram identificados.\n";
        echo c('bold', 'vermelho') . "  Verifique os detalhes acima e tome as medidas necessárias.\n" . rst();
    } else {
        echo "\n" . c('bold', 'verde') . "  ✓ VERIFICAÇÃO CONCLUÍDA ✓\n";
        echo c('bold', 'verde') . "  -------------------------\n";
        echo c('bold', 'verde') . "  Nenhuma modificação de segurança crítica detectada.\n";
        echo c('bold', 'verde') . "  O dispositivo parece estar em condições normais.\n" . rst();
    }

    echo "\n";
    return $bypassDetectado;
}



function verificarJogoInstalado(string $pacote, string $nomeJogo): void
{
    $r = adb("adb shell \"pm path --user 0 " . escapeshellarg($pacote) . " 2>/dev/null\"");

    if (!empty($r) && strpos($r, 'more than one device') !== false) {
        erro("Pareamento incorreto. Digite \"adb disconnect\" e refaça o processo.");
        exit;
    }

    if (empty($r) || !str_contains($r, 'package:')) {
        erro("O $nomeJogo está desinstalado, cancelando a telagem...");
        exit;
    }
}

function verificarRoot(): void
{
    echo "\n" . c('bold', 'azul') . "  → Checando se possui Root...\n" . rst();
    $motivos = [];

    $suTest = adb('adb shell "su -c id 2>&1 | head -1"');
    if (preg_match('/uid=0|(?<!\w)root(?!\w)/', $suTest)) {
        $motivos[] = [true, "Acesso root confirmado no dispositivo"];
    }

    $procComm = adb(
        'adb shell "found=; for f in /proc/[0-9]*/comm; do' .
        ' [ -r \"\$f\" ] && read -r n < \"\$f\" 2>/dev/null &&' .
        ' case \"\$n\" in *zygisk*|*magiskd*|*magisk_d*|*playintegrity*|*zn-zy*|zn-daemon)' .
        ' found=\"\$found|\$n\";; esac; done; echo \"\$found\""'
    );
    if (!empty(trim($procComm, "| \n"))) {
        foreach (array_filter(explode('|', $procComm)) as $nome) {
            $motivos[] = [true, "Processo root detectado: " . trim($nome)];
        }
    }

  
    $procCmd = adb(
        'adb shell "found=; for f in /proc/[0-9]*/cmdline; do' .
        ' [ -r \"\$f\" ] || continue;' .
        ' IFS= read -r n < \"\$f\" 2>/dev/null;' .
        ' case \"\$n\" in *zygisk*|*magisk*|*playintegrity*|*topjohnwu*)' .
        ' found=\"\$found|\$n\";; esac; done; echo \"\$found\""'
    );
    if (!empty(trim($procCmd, "| \n"))) {
        $motivos[] = [true, "Processo root oculto detectado via /proc/cmdline"];
    }

    $bootloader = adb('adb shell getprop ro.bootloader');
    if (strtolower(trim($bootloader)) === 'unknown') {
        $motivos[] = [true, "Firmware do dispositivo modificado (bootloader inválido)"];
    }

    $blState = adb('adb shell getprop ro.boot.bl_state');
    if (trim($blState) !== '' && trim($blState) !== '0' && trim($blState) !== '1') {
        $motivos[] = [false, "Estado do bootloader fora do padrão: " . trim($blState)];
    }

    $writeProtect = adb('adb shell getprop ro.boot.write_protect');
    if (trim($writeProtect) === '0') {
        $motivos[] = [false, "Proteção de escrita desativada no dispositivo"];
    }

    $verifiedBoot = adb('adb shell getprop ro.boot.verifiedbootstate');
    if (strtolower(trim($verifiedBoot)) === 'green' && strtolower(trim($bootloader)) === 'unknown') {
        $motivos[] = [true, "Integridade de boot falsificada detectada"];
    }

    $dataAdb = adb('adb shell "[ -d /data/adb ] && echo yes"');
    if (trim($dataAdb) === 'yes') {
        $motivos[] = [true, "Instalação root encontrada em /data/adb"];
    }

    $suBin = adb('adb shell "for p in /system/xbin/su /sbin/su /system/bin/su /data/adb/su; do [ -f \"\$p\" ] && echo \"\$p\"; done"');
    if (!empty(trim($suBin))) {
        $motivos[] = [true, "Binário su encontrado no sistema"];
    }

    $rootPkg = adb('adb shell "pm list packages 2>/dev/null | grep -E \'topjohnwu\.magisk|io\.github\.magisk\'"');
    if (!empty($rootPkg)) {
        $motivos[] = [true, "Aplicativo de gerenciamento root instalado"];
    }

    if (empty($motivos)) {
        info("Nenhum indicador de root detectado.");
        return;
    }

    $temConfirmado = false;
    foreach ($motivos as [$confirmado, $msg]) {
        if ($confirmado) {
            erro($msg);
            $temConfirmado = true;
        } else {
            aviso($msg);
        }
    }

    if (!$temConfirmado) {
        aviso("Indicadores suspeitos encontrados, mas root não confirmado.");
    }
}

function verificarHackSSH(): void
{
    echo "\n" . c('bold', 'azul') . "  → Verificando hack SSH/remoto...\n" . rst();
    $motivos = [];

    $servicosHack = ['cloudvm_srv', 'cloudAppEngine', 'lgserver', 'cph_logger', 'ecalcMediaCtl'];
    foreach ($servicosHack as $svc) {
        $val = adb("adb shell getprop init.svc.$svc");
        if (!empty(trim($val))) {
            $motivos[] = [true, "Serviço de controle remoto detectado no sistema"];
            break;
        }
        $pid = adb("adb shell getprop init.svc_debug_pid.$svc");
        if (!empty(trim($pid))) {
            $motivos[] = [true, "Serviço de controle remoto detectado no sistema"];
            break;
        }
    }

    $cphSvc = adb('adb shell "service check cph_logger 2>/dev/null"');
    if (!empty(trim($cphSvc)) && str_contains($cphSvc, 'found')) {
        $motivos[] = [true, "Serviço de controle remoto ativo (Binder)"];
    }

    $binUni  = adb('adb shell "[ -f /product/bin/uniview ] && echo yes"');
    $binTool = adb('adb shell "[ -f /product/bin/tool_service ] && echo yes"');
    if (trim($binUni) === 'yes') {
        $motivos[] = [true, "Binário de hack remoto encontrado: uniview"];
    }
    if (trim($binTool) === 'yes') {
        $motivos[] = [false, "Binário suspeito encontrado: tool_service"];
    }


    $procHack = adb(
        'adb shell "found=; susp=; for f in /proc/[0-9]*/comm; do' .
        ' [ -r \"\$f\" ] || continue;' .
        ' read -r n < \"\$f\" 2>/dev/null;' .
        ' case \"\$n\" in uniview|lgserver|cph_logger|cloudvm*)' .
        ' found=\"\$found|\$n\";;' .
        ' tool_service) susp=\"\$susp|\$n\";; esac;' .
        ' done; echo \"ok:\$found::\$susp\""'
    );
    if (preg_match('/^ok:(.*?)::(.*?)$/', trim($procHack), $mProc)) {
        foreach (array_filter(explode('|', $mProc[1])) as $proc) {
            $motivos[] = [true, "Processo de hack remoto ativo: " . trim($proc)];
        }
        foreach (array_filter(explode('|', $mProc[2])) as $proc) {
            $motivos[] = [false, "Processo suspeito em execução: " . trim($proc)];
        }
    }

    $logcatAvc = adb(
        'adb shell "logcat -d 2>/dev/null |' .
        ' grep -E \'Access denied finding property.*(init\.svc_debug_pid\.(cloudvm|cloudApp|lgserver|cph_logger)|ro\.boottime\.(cloudvm|cloudApp|lgserver))\'' .
        ' | head -5"'
    );
    if (!empty(trim($logcatAvc))) {
        $motivos[] = [true, "Infraestrutura de hack detectada via registros do sistema"];
    }


    $avcCph = adb('adb shell "logcat -d 2>/dev/null | grep -E \'avc.*denied.*find.*cph_logger|cph_logger.*service_manager\' | head -3"');
    if (!empty(trim($avcCph))) {
        $motivos[] = [true, "Serviço de controle remoto oculto confirmado via SELinux"];
    }

    $svcUni  = adb('adb shell getprop init.svc.uniview');
    $svcTool = adb('adb shell getprop init.svc.tool_service');
    if (trim($svcUni) === 'running') {
        $motivos[] = [true, "Serviço de acesso remoto ativo desde o boot"];
    }
    if (trim($svcTool) === 'running') {
        $motivos[] = [false, "Serviço suspeito ativo desde o boot: tool_service"];
    }

    $duckPkg = adb('adb shell "pm path com.eltavine.duckdetector 2>/dev/null"');
    if (!empty(trim($duckPkg)) && str_contains($duckPkg, 'package:')) {
        $motivos[] = [true, "Aplicativo de evasão de anti-cheat detectado (DuckDetector)"];
    }

    if (empty($motivos)) {
        info("Nenhum indicador de hack remoto detectado.");
        return;
    }

    $temConfirmado = false;
    foreach ($motivos as [$confirmado, $msg]) {
        if ($confirmado) {
            erro($msg);
            $temConfirmado = true;
        } else {
            aviso($msg);
        }
    }

    if (!$temConfirmado) {
        aviso("Indicadores suspeitos de acesso remoto, mas não confirmados.");
    }
}

function verificarScriptsAtivos(): void
{
    echo "\n" . c('bold', 'azul') . "  → Verificando scripts ativos em segundo plano...\n" . rst();
    $scripts = adb(
        'adb shell "pgrep -a bash | awk \'{\$1=\"\"; sub(/^ /,\"\"); print}\' | grep -vFx \"/data/data/com.termux/files/usr/bin/bash -l\""'
    );

    if (!empty($scripts)) {
        erro("Scripts detectados rodando em segundo plano! Cancelando scanner...");
        echo c('bold', 'amarelo') . "Scripts encontrados:\n$scripts\n\n" . rst();
        exit;
    }

    info("Nenhum script ativo detectado.");
    echo c('bold', 'azul') . "  [+] Finalizando sessões bash desnecessárias...\n" . rst();
    adb('adb shell "current_pid=\$\$; for pid in \$(pgrep bash); do [ \"\$pid\" -ne \"\$current_pid\" ] && kill -9 \$pid; done"');
    info("Sessões desnecessárias finalizadas.");
}

function verificarUptimeEHorario(): void
{
    echo "\n" . c('bold', 'azul') . "  → Checando se o dispositivo foi reiniciado recentemente...\n" . rst();
    $uptime = adb('adb shell uptime');

    if (preg_match('/up (\d+) min/', $uptime, $m)) {
        erro("O dispositivo foi iniciado recentemente (há {$m[1]} minutos).");
    } else {
        info("Dispositivo não reiniciado recentemente.");
    }

    $logcatTime = shell_exec('adb logcat -d -v time | head -n 2') ?? '';
    if (preg_match('/(\d{2}-\d{2} \d{2}:\d{2}:\d{2})/', $logcatTime, $m)) {
        $date = DateTime::createFromFormat('m-d H:i:s', $m[1]);
        if ($date) {
            echo c('bold', 'amarelo') . "  → Primeira log do sistema: " . $date->format('d-m H:i:s') . "\n" . rst();
            echo c('bold', 'branco') . "  → Caso a data da primeira log seja durante/após a partida, aplique o W.O!\n\n" . rst();
        }
    } else {
        erro("Não foi possível capturar a data/hora do sistema.");
    }
}

function verificarMudancasHorario(): void
{
    echo c('bold', 'azul') . "  → Verificando mudanças de data/hora...\n" . rst();

    $fusoHorario = adb('adb shell getprop persist.sys.timezone');
    if ($fusoHorario !== 'America/Sao_Paulo') {
        aviso("Fuso horário do dispositivo é '$fusoHorario', diferente de 'America/Sao_Paulo' — possível bypass.");
    }

    $logcatOutput = adb('adb shell "logcat -d | grep \"UsageStatsService: Time changed\" | grep -v HCALL"');
    $dataAtual    = date('m-d');
    $logsAlterados = [];

    if (!empty($logcatOutput)) {
        foreach (explode("\n", $logcatOutput) as $linha) {
            if (empty($linha)) continue;
            if (!preg_match('/(\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}\.\d{3}).*Time changed in.*by (-?\d+) second/', $linha, $m)) continue;
            if ($m[1] !== $dataAtual) continue;

            [$hora, $min, $secDec] = explode(':', $m[2]);
            $sec       = (int) floor((float) $secDec);
            $tsAntigo  = mktime((int)$hora, (int)$min, $sec, (int)substr($m[1],0,2), (int)substr($m[1],3,2), (int)date('Y'));
            $segsAlter = (int) $m[3];
            $tsNovo    = $segsAlter > 0 ? $tsAntigo - $segsAlter : $tsAntigo + abs($segsAlter);

            $logsAlterados[] = [
                'tsAntigo'  => $tsAntigo,
                'dataAntiga'=> date('d-m H:i', $tsAntigo),
                'dataNova'  => date('d-m', $tsNovo),
                'horaNova'  => date('H:i', $tsNovo),
                'acao'      => $segsAlter > 0 ? 'Atrasou' : 'Adiantou',
            ];
        }
    }

    if (!empty($logsAlterados)) {
        usort($logsAlterados, fn($a, $b) => $b['tsAntigo'] - $a['tsAntigo']);
        foreach ($logsAlterados as $log) {
            aviso("Alterou horário de {$log['dataAntiga']} para {$log['dataNova']} {$log['horaNova']} ({$log['acao']} horário)");
        }
    } else {
        erro("Nenhum log de alteração de horário encontrado.");
    }

    echo "\n" . c('bold', 'azul') . "  [+] Checando configuração automática de data/hora...\n" . rst();
    $autoTime     = adb('adb shell "settings get global auto_time"');
    $autoTimeZone = adb('adb shell "settings get global auto_time_zone"');

    if ($autoTime !== '1' || $autoTimeZone !== '1') {
        erro("Possível bypass: data/hora ou fuso automático desativado.");
    } else {
        info("Data/hora e fuso automáticos estão ativados.");
    }

    echo c('bold', 'branco') . "  → Caso haja mudança de horário durante/após a partida, aplique o W.O!\n\n" . rst();
}

function verificarPlayStore(): void
{
    echo c('bold', 'azul') . "  [+] Obtendo os últimos acessos do Google Play Store...\n" . rst();
    $out = adb("adb shell \"dumpsys usagestats | grep -i 'MOVE_TO_FOREGROUND' | grep 'package=com.android.vending' | awk -F'time=\"' '{print \$2}' | awk '{gsub(/\\\"/, \"\"); print \$1, \$2}' | tail -n 5\"");

    if (!empty($out)) {
        info("Últimos 5 acessos:");
        echo c('amarelo') . $out . "\n" . rst();
    } else {
        echo c('bold') . "\e[31m  [!] Nenhum dado encontrado.\n" . rst();
    }

    echo c('bold', 'branco') . "  → Caso haja acesso durante/após a partida, aplique o W.O!\n\n" . rst();
}

function verificarClipboard(): void
{
    echo c('bold', 'azul') . "  [+] Obtendo os últimos textos copiados...\n" . rst();
    $saida = adb("adb shell \"logcat -d | grep 'hcallSetClipboardTextRpc' | sed -E 's/^([0-9]{2}-[0-9]{2}) ([0-9]{2}:[0-9]{2}:[0-9]{2}).*hcallSetClipboardTextRpc\\(([^)]*)\\).*\$/\\1 \\2 \\3/' | tail -n 10\"");

    if (!empty($saida)) {
        foreach (explode("\n", $saida) as $linha) {
            if (!empty($linha) && preg_match('/^(\d{2}-\d{2}) (\d{2}:\d{2}:\d{2}) (.+)$/', $linha, $m)) {
                aviso("{$m[1]} {$m[2]} " . c('branco') . $m[3]);
            }
        }
    } else {
        echo c('bold') . "\e[31m  [!] Nenhum dado encontrado.\n" . rst();
    }

    echo "\n";
}

function verificarMReplays(string $pacote): void
{
    echo c('bold', 'azul') . "  → Checando se o replay foi passado...\n" . rst();

    $mreplaysDir = "/sdcard/Android/data/$pacote/files/MReplays";

    $permCheck = adb('adb shell "ls ' . escapeshellarg($mreplaysDir) . ' 2>&1 | head -n 1"');
    if (strpos($permCheck, 'Permission denied') !== false) {
        erro("[!] ACESSO NEGADO: $mreplaysDir");
        echo c('bold', 'amarelo') . "      Permissão de leitura removida! Possível ocultação de arquivos.\n";
        echo c('bold', 'amarelo') . "      Aplique o W.O imediatamente.\n" . rst();
    }

    $output   = adb('adb shell "ls -t /sdcard/Android/data/' . $pacote . '/files/MReplays/*.bin"');
    $arquivos = array_filter(explode("\n", $output));
    $motivos  = [];

    $ultimoModifyTime  = null;
    $arquivoMaisRecente = null;

    if (empty($arquivos)) {
        $motivos[] = "Motivo 10 - Nenhum arquivo .bin encontrado na pasta MReplays";
    }

    foreach ($arquivos as $idx => $arquivo) {
        $ts = statTimestamps($arquivo);
        if (!$ts) continue;

        $modifyTime = strtotime($ts['modify']);

        if ($idx === 0) {
            $arquivoMaisRecente = $arquivo;
            $ultimoModifyTime   = $modifyTime;

            if ($ts['access'] === $ts['modify'])
                $motivos[] = "Motivo 1 - Access e Modify iguais no arquivo mais recente: " . basename($arquivo);

            if ($ts['modify'] !== $ts['change'])
                $motivos[] = "Motivo 2 - Modify e Change diferentes no arquivo mais recente: " . basename($arquivo);

            if ($modifyTime > time() + 60)
                $motivos[] = "Motivo 3 - Data futura detectada: " . basename($arquivo);
        }
    }

    $tsPasta = statTimestamps($mreplaysDir);
    if ($tsPasta) {
        if ($tsPasta['access'] === $tsPasta['modify'])
            $motivos[] = "Motivo 4 - Access e Modify iguais na pasta MReplays";

        if ($tsPasta['modify'] !== $tsPasta['change'])
            $motivos[] = "Motivo 5 - Modify e Change diferentes na pasta MReplays";

        if ($ultimoModifyTime && strtotime($tsPasta['modify']) < $ultimoModifyTime - 10)
            $motivos[] = "Motivo 6 - Pasta modificada antes do arquivo mais recente";
    }

    $outputLs = adb('adb shell "ls -l /sdcard/Android/data/' . $pacote . '/files/MReplays/*.bin"');
    foreach (array_filter(explode("\n", $outputLs)) as $linha) {
        if (preg_match('/^-[rwx-]{9}\s+\d+\s+(\S+)\s+(\S+)\s+\d+\s+[\d-]+\s+[\d:]+\s+(.+\.bin)$/', $linha, $m)) {
            if ($m[1] === $m[2])
                $motivos[] = "Motivo 13 - Dono e grupo iguais (suspeito): " . basename($m[3]) . " (dono: {$m[1]})";
        }
    }

    $avcLog = adb('adb shell "logcat -d 2>/dev/null | grep -E \'adbd.*_rep\\.(bin|json)|relabelfrom.*_rep\\.(bin|json)|73796E6320737663.*rep\\.(bin|json)\' | head -20"');
    if (empty(trim($avcLog))) {
        $avcLog = adb('adb shell "dmesg 2>/dev/null | grep -E \'_rep\\.(bin|json)\' | head -20"');
    }
    if (!empty(trim($avcLog))) {
        $contadorAvc = 0;
        foreach (array_filter(explode("\n", $avcLog)) as $linhaAvc) {
            if (preg_match('/"([\d-]+-\d+-\d+-\d+_\d+_\d+_rep\.(bin|json))"/', $linhaAvc, $mAvc)) {
                $contadorAvc++;
                if ($contadorAvc <= 3) {
                    $motivos[] = "Motivo 14 - Replay passado detectado: " . $mAvc[1];
                }
            }
        }
        if ($contadorAvc > 3) {
            $motivos[] = "Motivo 14 - Replays passados adicionais detectados: " . ($contadorAvc - 3) . " arquivo(s)";
        }
    }


    $logcatUsb = adb('adb shell "logcat -d 2>/dev/null | grep -E \'UsbPortManager.*connected=true.*ufp|UsbModeChooserActivity|UsbDetailsActivity\' | tail -5"');
    if (!empty(trim($logcatUsb))) {
        $anoAtual = date('Y');
        foreach (array_filter(explode("\n", $logcatUsb)) as $linhaUsb) {
            if (preg_match('/^(\d{2}-\d{2}) (\d{2}:\d{2}:\d{2})/', $linhaUsb, $mUsb)) {
                $usbTs = strtotime("$anoAtual-{$mUsb[1]} {$mUsb[2]}");
                if ($usbTs !== false && ($ultimoModifyTime === null || abs($usbTs - $ultimoModifyTime) <= 3600)) {
                    if (str_contains($linhaUsb, 'connected=true')) {
                        $motivos[] = "Motivo 15 - Dispositivo externo conectado via USB às {$mUsb[1]} {$mUsb[2]}";
                    } elseif (str_contains($linhaUsb, 'UsbModeChooser') || str_contains($linhaUsb, 'UsbDetails')) {
                        $motivos[] = "Motivo 15 - Configuração de conexão USB alterada às {$mUsb[1]} {$mUsb[2]}";
                    }
                }
            }
        }
    }

    if (!empty($motivos)) {
        erro("Passador de replay detectado, aplique o W.O!");
        foreach (array_unique($motivos) as $motivo) {
            echo "    - $motivo\n";
        }
    } else {
        info("Nenhum replay foi passado e a pasta MReplays está normal.");
    }

    $rawPasta = adb('adb shell "stat ' . escapeshellarg($mreplaysDir) . '"');
    if (!empty($rawPasta) && preg_match('/Access: (\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d+)/', $rawPasta, $mA)) {
        $semMilesimos = preg_replace('/\.\d+.*$/', '', $mA[1]);
        $dtAcesso = DateTime::createFromFormat('Y-m-d H:i:s', $semMilesimos);

        $firstInstall = adb("adb shell dumpsys package " . escapeshellarg($pacote) . " | grep -i firstInstallTime");
        $dataInstalacao = 'Não encontrada';
        if (preg_match('/firstInstallTime=([\d-]+ \d{2}:\d{2}:\d{2})/', $firstInstall, $mi)) {
            $dtInst = DateTime::createFromFormat('Y-m-d H:i:s', trim($mi[1]));
            $dataInstalacao = $dtInst ? $dtInst->format('d-m-Y H:i:s') : 'Formato inválido';
        }

        echo c('bold', 'amarelo') . "  → Data de acesso da pasta MReplays: " . ($dtAcesso ? $dtAcesso->format('d-m-Y H:i:s') : $semMilesimos) . "\n";
        echo c('bold', 'amarelo') . "  • Data de instalação do Free Fire:  $dataInstalacao\n";
        echo c('bold', 'branco') . "  ▸ Compare a data de instalação com a data de acesso da MReplays. Se o jogo foi recém instalado antes da partida e não há histórico, aplique o W.O!\n\n" . rst();
    } else {
        erro("Não foi possível obter a data de acesso da pasta MReplays");
    }
}

function verificarWallhackHolograma(string $pacote): void
{
    echo c('bold', 'azul') . "  → Checando bypass de Wallhack/Holograma...\n" . rst();

    $pastasBase = [
        "/sdcard/Android/data/$pacote/files/contentcache/Optional/android/gameassetbundles",
        "/sdcard/Android/data/$pacote/files/contentcache/Optional/android",
        "/sdcard/Android/data/$pacote/files/contentcache/Optional",
        "/sdcard/Android/data/$pacote/files/contentcache",
        "/sdcard/Android/data/$pacote/files",
        "/sdcard/Android/data/$pacote",
        "/sdcard/Android/data",
        "/sdcard/Android",
    ];

    $modificacaoDetectada = false;

    foreach ($pastasBase as $pasta) {
        $perm = adb('adb shell "ls ' . escapeshellarg($pasta) . ' 2>&1 | head -n 1"');
        if (strpos($perm, 'Permission denied') !== false) {
            erro("[!] ACESSO NEGADO: $pasta");
            echo c('bold', 'amarelo') . "      Permissão de leitura removida! TENTATIVA DE BYPASS!\n" . rst();
            $modificacaoDetectada = true;
        }

        $ts = statTimestamps($pasta);
        if ($ts && $ts['modify'] !== $ts['change']) {
            erro("Modificação detectada na pasta: $pasta! Aplique o W.O!\n");
            $modificacaoDetectada = true;
        }
    }

    if (!$modificacaoDetectada) {
        info("Nenhuma modificação suspeita encontrada nas pastas principais.");
    }

    echo c('bold', 'azul') . "  → Verificando arquivos específicos...\n" . rst();

    $pastasEspecificas = [
        "/sdcard/Android/data/$pacote/files/contentcache/Optional/android/gameassetbundles",
        "/sdcard/Android/data/$pacote/files/contentcache/Optional/android",
    ];

    foreach ($pastasEspecificas as $pasta) {
        $lista = adb('adb shell "ls ' . escapeshellarg($pasta) . '"');
        if (empty($lista)) {
            echo c('vermelho') . "  [*] Sem itens baixados! Verifique se a data é após o fim da partida!\n\n" . rst();
            continue;
        }

        $arquivoSuspeito = false;
        foreach (array_filter(explode("\n", $lista)) as $arquivo) {
            if (empty($arquivo)) continue;
            $caminho = "$pasta/$arquivo";
            if (stripos($arquivo, 'avatar') === false && stripos($arquivo, 'config') === false) continue;

            try {
                $modRaw    = adb('adb shell stat -c "%y" ' . escapeshellarg($caminho));
                $changeRaw = adb('adb shell stat -c "%z" ' . escapeshellarg($caminho));
                if (empty($modRaw) || empty($changeRaw)) continue;

                $dtMod    = new DateTime($modRaw, new DateTimeZone('UTC'));
                $dtChange = new DateTime($changeRaw, new DateTimeZone('UTC'));
                $dtMod->setTimezone(new DateTimeZone('America/Sao_Paulo'));
                $dtChange->setTimezone(new DateTimeZone('America/Sao_Paulo'));

                if ($dtMod != $dtChange) {
                    erro("Modificação detectada no arquivo: $arquivo! Aplique o W.O!");
                    $arquivoSuspeito = $modificacaoDetectada = true;
                }
            } catch (Exception $e) {
                echo c('vermelho') . "  [!] Erro ao verificar $arquivo: " . $e->getMessage() . "\n" . rst();
            }
        }

        if (!$arquivoSuspeito) {
            info("Nenhuma alteração suspeita encontrada nos arquivos.");
        }
    }
}

function verificarOBB(string $pacote): void
{
    echo c('bold', 'azul') . "  → Checando OBB...\n" . rst();

    $dirObb = "/sdcard/Android/obb/$pacote";
    $perm   = adb('adb shell "ls ' . escapeshellarg($dirObb) . ' 2>&1 | head -n 1"');
    if (strpos($perm, 'Permission denied') !== false) {
        erro("[!] ACESSO NEGADO: $dirObb");
        echo c('bold', 'amarelo') . "      Permissão removida! TENTATIVA DE BYPASS! Aplique o W.O.\n" . rst();
    }

    $resultObb  = adb('adb shell "ls ' . escapeshellarg($dirObb) . '/*obb*"');
    if (empty($resultObb)) {
        echo c('vermelho') . "[*] OBB deletada e/ou inexistente!\n" . rst();
        return;
    }

    foreach (array_filter(explode("\n", $resultObb)) as $arquivo) {
        $changeRaw = adb('adb shell stat -c "%z" ' . escapeshellarg($arquivo));
        if (!empty($changeRaw)) {
            $dt = new DateTime(trim($changeRaw), new DateTimeZone('UTC'));
            $dt->setTimezone(new DateTimeZone('America/Sao_Paulo'));
            echo c('amarelo') . "[*] Data de modificação do OBB: " . $dt->format('d-m-Y H:i:s') . "\n" . rst();
        } else {
            echo c('vermelho') . "[!] Não foi possível obter a data de modificação do OBB.\n" . rst();
        }
    }
}

function verificarShaders(string $pacote): void
{
    $dirShaders = "/sdcard/Android/data/$pacote/files/contentcache/Optional/android/gameassetbundles";
    $resultShaders = adb('adb shell "if [ -d ' . escapeshellarg($dirShaders) . ' ]; then find ' . escapeshellarg($dirShaders) . ' -type f; fi"');

    if (empty($resultShaders)) {
        info("Nenhuma alteração suspeita encontrada.");
        return;
    }

    $firstInstall = adb("adb shell dumpsys package " . escapeshellarg($pacote) . " | grep -i firstInstallTime");
    $dataInstalacao = 'Data de instalação não encontrada';
    $dtInstalacao   = null;
    if (preg_match('/firstInstallTime=([\d-]+ \d{2}:\d{2}:\d{2})/', $firstInstall, $mi)) {
        $dtInstalacao = DateTime::createFromFormat('Y-m-d H:i:s', trim($mi[1]));
        $dataInstalacao = $dtInstalacao ? $dtInstalacao->format('d-m-Y H:i:s') : 'Formato inválido';
    }

    foreach (array_filter(explode("\n", $resultShaders)) as $arquivo) {
        if (empty($arquivo)) continue;
        if (empty(adb('adb shell "if [ -f ' . escapeshellarg($arquivo) . ' ]; then echo 1; fi"'))) continue;

        $nomeArquivo = basename($arquivo);


        $header = adb('adb shell "head -c 20 ' . escapeshellarg($arquivo) . '"');
        if (strpos($header, 'UnityFS') === false) continue;


        if (stripos($nomeArquivo, 'shader') !== false) {
            $nanoOut = adb('adb shell "stat -c \"%y\" ' . escapeshellarg($arquivo) . '"');
            if (!empty($nanoOut) && preg_match('/\.(\d+)\s/', $nanoOut, $nm)) {
                $ns = $nm[1];
                if (preg_match('/(9999+|0000+)/', $ns)) {
                    erro("Bypass de Wall detectado (padrão em nanosegundos) — aplique o W.O!");
                    aviso("Arquivo: $nomeArquivo  •  Nanosegundos: $ns  •  Timestamp: $nanoOut");
                    return;
                }
                if (preg_match('/(999(?:[0-8]|$)|000(?:[1-9]|$))/', $ns)) {
                    aviso("Possível WallHack detectado (padrão em nanosegundos).");
                    aviso("Arquivo: $nomeArquivo  •  Nanosegundos: $ns  •  Timestamp: $nanoOut");
                    return;
                }
            }
        }

        $ts = statTimestamps($arquivo);
        if (!$ts) continue;

        $dtMod = DateTime::createFromFormat('Y-m-d H:i:s', $ts['modify']);
        if (!$dtMod) continue;

        $agora     = new DateTime();
        $diffSecs  = abs($agora->getTimestamp() - $dtMod->getTimestamp());

        if ($diffSecs <= 3600) {
            aviso("Possível bypass: arquivo shader alterado recentemente.");
            aviso("Arquivo: $nomeArquivo  •  Modificado: " . $dtMod->format('d-m-Y H:i:s') . "  •  Agora: " . $agora->format('d-m-Y H:i:s'));
            return;
        }

        if ($ts['modify'] === $ts['change'] && $ts['modify'] === $ts['access']) {
            if (stripos($nomeArquivo, 'shader') !== false && $ts['modify'] !== ($dtInstalacao ? $dtInstalacao->format('Y-m-d H:i:s') : '')) {
                aviso("Arquivo shader modificado: $nomeArquivo");
                aviso("Horário da modificação: " . $dtMod->format('d-m-Y H:i:s'));
                echo c('bold', 'amarelo') . "  • Data de instalação do Free Fire: $dataInstalacao\n";
                echo c('bold', 'branco') . "  ▸ Verifique no App Usage se a data de instalação bate com o horário da modificação. Se diferente, aplique o W.O!\n\n" . rst();
                return;
            }
        }
    }

    info("Nenhuma alteração suspeita encontrada.");
}

function verificarOptionalAvatarRes(string $pacote): void
{
    $dirGameAsset  = "/sdcard/Android/data/$pacote/files/contentcache/Optional/android/optionalavatarres/gameassetbundles";
    $dirOptional   = "/sdcard/Android/data/$pacote/files/contentcache/Optional/android/optionalavatarres";

    $existe = adb('adb shell "test -d ' . escapeshellarg($dirGameAsset) . ' && echo existe || echo naoexiste"');
    $dirAlvo  = $existe === 'existe' ? $dirGameAsset  : $dirOptional;
    $nomePasta = $existe === 'existe' ? 'gameassetbundles' : 'optionalavatarres';

    $modRaw = adb('adb shell stat -c "%y" ' . escapeshellarg($dirAlvo));
    if (empty($modRaw)) return;

    try {
        $dtMod = new DateTime($modRaw);
        $agora = new DateTime();
        echo c('bold', 'amarelo') . "  • Modificação na pasta '$nomePasta' (Optional): " . $dtMod->format('d-m-Y H:i:s') . "\n" . rst();

        if ($agora->getTimestamp() - $dtMod->getTimestamp() <= 3600) {
            erro("Possível Bypass em Optional! Modificada há menos de 1 hora.");
            echo c('vermelho') . "    Hora da modificação: " . $dtMod->format('H:i:s') . "\n";
            echo c('vermelho') . "    Hora atual:          " . $agora->format('H:i:s') . "\n" . rst();
        }
    } catch (Exception $e) {
        echo c('vermelho') . "[!] Erro ao ler data da pasta '$nomePasta': " . $e->getMessage() . "\n" . rst();
    }

    $listaArquivos = adb('adb shell "find ' . escapeshellarg($dirAlvo) . ' -type f"');
    if (empty($listaArquivos)) return;

    foreach (array_filter(explode("\n", $listaArquivos)) as $arquivo) {
        $arquivo = trim($arquivo);
        if (empty($arquivo)) continue;

        $header = adb('adb shell "head -c 20 ' . escapeshellarg($arquivo) . '"');
        if (strpos($header, 'UnityFS') === false) continue;

        $modRawArq    = adb('adb shell stat -c "%y" ' . escapeshellarg($arquivo));
        $changeRawArq = adb('adb shell stat -c "%z" ' . escapeshellarg($arquivo));

        if (empty($modRawArq) || empty($changeRawArq)) continue;

        try {
            $dtM = new DateTime($modRawArq,    new DateTimeZone('UTC'));
            $dtC = new DateTime($changeRawArq, new DateTimeZone('UTC'));
            $dtM->setTimezone(new DateTimeZone('America/Sao_Paulo'));
            $dtC->setTimezone(new DateTimeZone('America/Sao_Paulo'));

            if ($dtM != $dtC) {
                erro("Modificação detectada no arquivo Optional: " . basename($arquivo) . "! Aplique o W.O!");
            }
        } catch (Exception $e) {}
    }
}


function escanearFreeFire(string $pacote, string $nomeJogo): void
{
    garantirPermissoesBinarios();
    system('clear');
    kellerBanner();
    verificarDispositivoADB();

    if (empty(adb('adb version'))) {
        system('pkg install -y android-tools > /dev/null 2>&1');
    }

    date_default_timezone_set('America/Sao_Paulo');
    shell_exec('adb start-server > /dev/null 2>&1');

    $devices = adb('adb devices');
    if (empty($devices) || strpos($devices, 'device') === false || strpos($devices, 'no devices') !== false) {
        erro("Nenhum dispositivo encontrado. Faça o pareamento de IP ou conecte via USB.");
        exit;
    }

    verificarJogoInstalado($pacote, $nomeJogo);

    $androidVer = adb('adb shell getprop ro.build.version.release');
    if (!empty($androidVer)) {
        echo c('bold', 'azul') . "  [+] Versão do Android: $androidVer\n" . rst();
    }

    verificarRoot();
    verificarScriptsAtivos();

    echo c('bold', 'azul') . "  → Verificando bypasses de funções shell...\n" . rst();
    detectarBypassShell();

    verificarUptimeEHorario();
    verificarMudancasHorario();
    verificarPlayStore();
    verificarClipboard();
    verificarMReplays($pacote);
    verificarWallhackHolograma($pacote);
    verificarOBB($pacote);
    verificarShaders($pacote);
    verificarOptionalAvatarRes($pacote);

    echo c('bold', 'branco') . "\n\n\t Obrigado por compactuar por um cenário limpo de cheats.\n";
    echo c('bold', 'branco') . "\t                 Com carinho, Keller...\n\n" . rst();
}


function conectarADB(): void
{
    system('clear');
    kellerBanner();

    echo c('bold', 'azul') . "  → Verificando se o ADB está instalado...\n" . rst();
    if (empty(adb('adb version'))) {
        aviso("ADB não encontrado. Instalando android-tools...");
        system('pkg install android-tools -y');
        info("Android-tools instalado com sucesso!");
    } else {
        info("ADB já está instalado.");
    }

    echo "\n";
    inputUsuario("Qual a sua porta para o pareamento (ex: 45678)?");
    $pairPort = trim(fgets(STDIN, 1024));

    if (!is_numeric($pairPort) || empty($pairPort)) {
        erro("Porta inválida! Retornando ao menu.");
        sleep(2);
        return;
    }

    echo c('bold', 'amarelo') . "\n  [!] Agora, digite o código de pareamento que aparece no celular e pressione Enter.\n" . rst();
    system('adb pair localhost:' . intval($pairPort));

    echo "\n";
    inputUsuario("Qual a sua porta para a conexão (ex: 12345)?");
    $connectPort = trim(fgets(STDIN, 1024));

    if (!is_numeric($connectPort) || empty($connectPort)) {
        erro("Porta inválida! Retornando ao menu.");
        sleep(2);
        return;
    }

    echo c('bold', 'amarelo') . "\n  [!] Conectando ao dispositivo...\n" . rst();
    system('adb connect localhost:' . intval($connectPort));
    info("Processo de conexão finalizado. Verifique a saída acima.");

    echo c('bold', 'branco') . "\n  [+] Pressione Enter para voltar ao menu...\n" . rst();
    fgets(STDIN, 1024);
}


function exibirMenu(): void
{
    echo c('bold', 'azul') . "  ╔══════════════════════════╗\n";
    echo c('bold', 'azul') . "  ║      MENU PRINCIPAL      ║\n";
    echo c('bold', 'azul') . "  ╚══════════════════════════╝\n\n" . rst();
    echo c('amarelo') . "  [0] " . c('branco') . "Conectar ADB " . c('cinza') . "(Pareamento e conexão via ADB)\n" . rst();
    echo c('verde')   . "  [1] " . c('branco') . "Escanear FreeFire Normal\n" . rst();
    echo c('verde')   . "  [2] " . c('branco') . "Escanear FreeFire Max\n" . rst();
    echo c('vermelho'). "  [S] " . c('branco') . "Sair\n\n" . rst();
}

function lerOpcao(): string
{
    $validas = ['0', '1', '2', 'S', 's'];
    do {
        inputUsuario("Escolha uma das opções acima");
        $opcao = trim(fgets(STDIN, 1024));
        if (!in_array($opcao, $validas, true)) {
            erro("Opção inválida! Tente novamente.");
            echo "\n";
        }
    } while (!in_array($opcao, $validas, true));

    return strtoupper($opcao);
}


garantirPermissoesBinarios();
system('clear');
kellerBanner();
sleep(1);
echo "\n";

while (true) {
    exibirMenu();
    $opcao = lerOpcao();

    switch ($opcao) {
        case '0':
            conectarADB();
            system('clear');
            kellerBanner();
            break;

        case '1':
            escanearFreeFire('com.dts.freefireth', 'FreeFire Normal');
            break;

        case '2':
            escanearFreeFire('com.dts.freefiremax', 'FreeFire MAX');
            break;

        case 'S':
            echo "\n\n\t Obrigado por compactuar por um cenário limpo de cheats.\n\n";
            exit(0);
    }
}
