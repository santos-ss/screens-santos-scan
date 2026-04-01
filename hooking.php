#!/usr/bin/env php
<?php

declare(strict_types=1);

const C = [
    'rst'      => "\e[0m",
    'bold'     => "\e[1m",
    'branco'   => "\e[97m",
    'cinza'    => "\e[37m",
    'vermelho' => "\e[91m",
    'verde'    => "\e[92m",
    'fverde'   => "\e[32m",
    'amarelo'  => "\e[93m",
    'azul'     => "\e[34m",
    'ciano'    => "\e[36m",
];

function c(string ...$nomes): string
{
    return implode('', array_map(fn($n) => C[$n] ?? '', $nomes));
}

function rst(): string { return C['rst']; }

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
  🔍 H O O K I N G   S C A N N E R
  " . c('ciano') . "Fucking Cheaters Detector" . c('branco') . "
  " . c('cinza') . "Baseado em KellerSS | Mod by Grok\n\n" . rst();
}

function garantirPermissoesBinarios(): void
{
    @chmod('/data/data/com.termux/files/usr/bin/adb', 0755);
}

function adb(string $cmd): string
{
    $cmd = trim($cmd);
    if (str_starts_with($cmd, 'adb ')) $cmd = substr($cmd, 4);
    return trim((string) shell_exec("adb $cmd 2>/dev/null"));
}

// ====================== DETECÇÃO COMPLETA - 16 SEÇÕES ======================
function detectarBypassShell(): bool
{
    $bypassDetectado   = false;
    $totalVerificacoes = 0;
    $problemasTotal    = 0;

    cabecalho('ANÁLISE COMPLETA DE SEGURANÇA DO DISPOSITIVO (HOOKING)');

    secao(1, 'VERIFICANDO DISPOSITIVO CONECTADO');
    if (strpos(adb('devices'), 'device') === false) {
        erro("Nenhum dispositivo ADB conectado ou autorizado!");
        return false;
    }
    ok("Dispositivo conectado com sucesso");

    secao(2, 'ESTADO DE BOOT');
    $boot = adb('shell getprop ro.boot.verifiedbootstate');
    if ($boot === 'orange') { erro("Bootloader desbloqueado (ORANGE)"); $bypassDetectado = true; }
    elseif ($boot === 'yellow') { aviso("Boot modificado (YELLOW)"); $bypassDetectado = true; }
    else ok("Boot State: $boot");

    secao(3, 'SELinux');
    $sel = adb('shell getenforce');
    if ($sel === 'Permissive') { erro("SELinux PERMISSIVE - Dispositivo provavelmente rooteado"); $bypassDetectado = true; }
    else ok("SELinux: $sel");

    secao(4, 'PROPRIEDADES SUSPEITAS');
    $props = ['ro.debuggable' => '1', 'ro.secure' => '0', 'ro.boot.veritymode' => 'disabled', 'ro.kernel.qemu' => '1'];
    foreach ($props as $p => $v) {
        if (adb("shell getprop $p") === $v) {
            erro("Propriedade suspeita: $p = $v");
            $bypassDetectado = true;
        }
    }

    secao(5, 'BINÁRIOS ROOT');
    $suspeitos = ['/system/bin/su', '/sbin/su', '/data/adb/magisk', '/data/adb/ksu'];
    $rootEncontrado = false;
    foreach ($suspeitos as $bin) {
        if (adb("shell test -f $bin && echo FOUND") === 'FOUND') {
            erro("Root encontrado: $bin");
            $rootEncontrado = $bypassDetectado = true;
        }
    }
    if (!$rootEncontrado) ok("Nenhum binário root clássico encontrado");

    secao(6, 'MAGISK');
    if (str_contains(adb('shell pm list packages'), 'magisk')) {
        erro("Magisk instalado");
        $bypassDetectado = true;
    } else ok("Magisk não detectado");

    secao(7, 'KERNELSU / APATCH');
    if (str_contains(adb('shell cat /proc/version 2>/dev/null'), 'ksu')) {
        erro("KernelSU detectado");
        $bypassDetectado = true;
    }
    if (adb('shell test -d /data/adb/ap && echo FOUND') === 'FOUND') {
        erro("APatch detectado");
        $bypassDetectado = true;
    }

    secao(8, 'FRAMEWORKS DE HOOK');
    $hook = adb('shell ps -ef 2>/dev/null');
    if (str_contains($hook, 'frida') || str_contains($hook, 'xposed') || str_contains($hook, 'lsposed')) {
        erro("Framework de Hook detectado (Frida/Xposed/LSPosed)");
        $bypassDetectado = true;
    } else ok("Nenhum hook framework ativo");

    secao(9, 'PROCESSOS SUSPEITOS');
    if (str_contains($hook, 'magiskd') || str_contains($hook, 'ksu')) {
        erro("Processos root/hook em execução");
        $bypassDetectado = true;
    }

    secao(10, 'VPN / TUNNEL');
    if (str_contains(adb('shell ip link show'), 'tun0') || str_contains(adb('shell ip link show'), 'wg0')) {
        erro("Interface VPN/Tunnel detectada");
        $bypassDetectado = true;
    }

    secao(11, '/data/local/tmp');
    $tmp = adb('shell ls /data/local/tmp 2>/dev/null');
    if (!empty($tmp)) {
        aviso("Arquivos encontrados em /data/local/tmp");
        detalhe(trim($tmp));
        $bypassDetectado = true;
    } else ok("/data/local/tmp limpa");

    secao(12, 'FUNÇÕES SHELL SOBRESCRITAS');
    if (str_contains(adb('shell type ls 2>/dev/null'), 'function')) {
        erro("Funções shell foram sobrescritas (possível bypass)");
        $bypassDetectado = true;
    }

    secao(13, 'APPS SUSPEITOS');
    $apps = ['shizuku', 'fakegps', 'shamiko', 'trickystore'];
    $pkgs = adb('shell pm list packages');
    foreach ($apps as $app) {
        if (str_contains($pkgs, $app)) {
            aviso("App suspeito instalado: $app");
            $bypassDetectado = true;
        }
    }

    secao(14, 'LOGS DE DESINSTALAÇÃO');
    $uninstall = adb('shell "logcat -d 2>/dev/null | grep -E \'deletePackageX|pkg removed\' | tail -3"');
    if (!empty($uninstall)) {
        erro("Desinstalações suspeitas via comando detectadas");
        detalhe(substr($uninstall, 0, 200));
        $bypassDetectado = true;
    }

    secao(15, 'ACESSO A DIRETÓRIOS CRÍTICOS');
    $dirs = ['/data/adb', '/system/bin'];
    foreach ($dirs as $d) {
        if (adb("shell '[ -r $d ] && echo OK || echo DENIED'") === 'DENIED') {
            aviso("Acesso negado a $d - possível ocultação");
        }
    }

    secao(16, 'RESUMO GERAL');
    echo c('bold', 'branco') . "  Total de verificações: $totalVerificacoes\n";
    echo c('bold', 'branco') . "  Problemas detectados   : $problemasTotal\n\n" . rst();

    if ($bypassDetectado) {
        echo c('bold', 'vermelho') . "  💀 HOOKING / ROOT / BYPASS DETECTADO 💀\n";
        echo c('bold', 'vermelho') . "  Recomendado aplicar W.O. imediatamente!\n" . rst();
    } else {
        echo c('bold', 'verde') . "  ✅ NENHUM HOOKING DETECTADO - Dispositivo parece LIMPO ✅\n" . rst();
    }

    return $bypassDetectado;
}

// ====================== FUNÇÕES DO SCAN ======================
function verificarDispositivoADB(): void
{
    garantirPermissoesBinarios();
    if (empty(adb('devices'))) {
        erro("ADB não encontrado. Instale com: pkg install android-tools");
        exit(1);
    }
}

function verificarJogoInstalado(string $pacote, string $nome): void
{
    $r = adb("shell pm path $pacote");
    if (!str_contains($r, 'package:')) {
        erro("$nome não está instalado!");
        exit(1);
    }
    ok("$nome detectado");
}

// ====================== MENU ======================
function exibirMenu(): void
{
    echo c('bold', 'azul') . "\n  ╔════════════════════════════════════╗\n";
    echo "  ║         🔍 H O O K I N G   S C A N         ║\n";
    echo "  ╚════════════════════════════════════╝\n\n" . rst();

    echo c('amarelo') . "  [0] Conectar via ADB (Pair + Connect)\n";
    echo c('verde')   . "  [1] Escanear Free Fire Normal\n";
    echo c('verde')   . "  [2] Escanear Free Fire MAX\n";
    echo c('vermelho'). "  [S] Sair\n\n" . rst();
}

function conectarADB(): void
{
    system('clear');
    kellerBanner();

    inputUsuario("Porta de pareamento (ex: 45678)");
    $pair = (int)trim(fgets(STDIN));
    system("adb pair localhost:$pair");

    inputUsuario("Porta de conexão (ex: 12345)");
    $conn = (int)trim(fgets(STDIN));
    system("adb connect localhost:$conn");

    info("Conexão ADB concluída.");
    echo "\nPressione ENTER...";
    fgets(STDIN);
}

// ====================== MAIN ======================
system('clear');
kellerBanner();

while (true) {
    exibirMenu();
    inputUsuario("Escolha uma opção");
    $op = strtoupper(trim(fgets(STDIN) ?? ''));

    match ($op) {
        '0' => conectarADB(),
        '1' => {
            system('clear');
            kellerBanner();
            verificarDispositivoADB();
            verificarJogoInstalado('com.dts.freefireth', 'Free Fire');
            detectarBypassShell();
        },
        '2' => {
            system('clear');
            kellerBanner();
            verificarDispositivoADB();
            verificarJogoInstalado('com.dts.freefiremax', 'Free Fire MAX');
            detectarBypassShell();
        },
        'S' => {
            echo "\n" . c('bold', 'verde') . "HOOKING DOMINA - Até a próxima!\n" . rst();
            exit(0);
        },
        default => aviso("Opção inválida!")
    };

    echo "\nPressione ENTER para voltar ao menu...";
    fgets(STDIN);
    system('clear');
}
