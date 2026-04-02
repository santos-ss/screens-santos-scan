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

function c(string ...$nomes): string {
    return implode('', array_map(fn($n) => C[$n] ?? '', $nomes));
}

function rst(): string { return C['rst']; }

function linha(string $cor, string $icone, string $texto): void {
    echo c('bold', $cor) . "  $icone $texto\n" . rst();
}

function ok(string $texto): void     { linha('verde',    '✓', $texto); }
function erro(string $texto): void   { linha('vermelho', '✗', $texto); }
function aviso(string $texto): void  { linha('amarelo',  '⚠', $texto); }
function info(string $texto): void   { linha('fverde',   'ℹ', $texto); }
function detalhe(string $texto): void {
    echo c('bold', 'amarelo') . "    $texto\n" . rst();
}

function secao(int $num, string $titulo): void {
    $sep = str_repeat('─', mb_strlen($titulo) + 4);
    echo "\n" . c('bold', 'azul') . "  ► [$num] $titulo\n  $sep\n" . rst();
}

function cabecalho(string $titulo): void {
    echo "\n" . c('bold', 'ciano') . "  $titulo\n  " . str_repeat('=', mb_strlen($titulo)) . "\n\n" . rst();
}

function kellerBanner(): void {
    echo c('branco') . "
  KellerSS Android " . c('ciano') . "Fucking Cheaters" . c('branco') . "
  " . c('cinza') . "discord.gg/allianceoficial" . c('branco') . "

  )       (     (          (
  ( /(       )\ )  )\ )       )\ )
  )\()) (   (()/( (()/(  (   (()/(
  |((_)\  )\   /(_)) /(_)) )\   /(_))
  |_ ((_)((_) (_))  (_))  ((_) (_))
  | |/ / | __|| |   | |   | __|| _ \\
  ' <  | _| | |__ | |__ | _| |   /
  _|\_\\ |___||____||____||___||_|_\\

  " . c('ciano') . "Coded By: KellerSS | Otimizado com Wallhack + MReplays" . rst() . "\n\n";
}

function adb(string $cmd): string {
    return trim((string) shell_exec('adb ' . $cmd . ' 2>/dev/null'));
}

function criarArquivoDetecao(string $nome, string $conteudo = ""): void {
    $arquivo = "/sdcard/" . $nome . "_Detectado.txt";
    $data = date('Y-m-d H:i:s');
    $conteudo = "=== $nome DETECTADO ===\nData: $data\n\n" . $conteudo;
    file_put_contents($arquivo, $conteudo);
    echo c('bold', 'amarelo') . "  📄 Arquivo criado: $arquivo\n" . rst();
}

function scanCompleto(string $pacote = 'com.dts.freefireth', string $nomeJogo = 'Free Fire'): void {
    system('clear');
    kellerBanner();

    $RESULT_FILE = "/sdcard/resultSCAN.txt";
    $DATE = date('Y-m-d H:i:s');
    $score = 0;

    file_put_contents($RESULT_FILE, "=== RESULT SCAN - ANTI CHEAT FREE FIRE ===\n");
    file_put_contents($RESULT_FILE, "Data/Hora: $DATE\nJogo: $nomeJogo\nDispositivo: " . adb('shell getprop ro.product.model') . "\n\n", FILE_APPEND);

    cabecalho("INICIANDO SCAN COMPLETO - $nomeJogo");

    // 1. ROOT
    secao(1, "VERIFICANDO ROOT");
    if (adb('shell "su -c id 2>&1"') || adb('shell "test -f /data/adb/magisk && echo found"') === 'found') {
        erro("ROOT DETECTADO ATIVO");
        file_put_contents($RESULT_FILE, "[ROOT] ROOT DETECTADO ATIVO\n", FILE_APPEND);
        $score += 15;
    } else {
        ok("Sem root ativo detectado");
    }

    // 2. XPOSED / LSPOSED
    secao(2, "VERIFICANDO XPOSED / LSPOSED");
    $xposed = false;
    $paths = ['/data/adb/lsposed', '/data/adb/xposed', '/data/system/xposed.prop', '/data/system/lsposed.prop'];
    foreach ($paths as $p) {
        if (adb("shell \"test -e $p && echo found\"") === 'found') {
            erro("XPOSED/LSPOSED DETECTADO → $p");
            file_put_contents($RESULT_FILE, "[XPOSED] $p\n", FILE_APPEND);
            $xposed = true;
            $score += 12;
        }
    }
    if ($xposed) criarArquivoDetecao("Xposed");

    // 3. VIRTUAL APPS
    secao(3, "VERIFICANDO VIRTUAL APPS");
    $virtual = false;
    $vpaths = ['/sdcard/Android/data/io.virtualapp', '/sdcard/Android/data/com.vmos', '/sdcard/Android/data/com.f1vm', '/sdcard/Android/data/com.parallel'];
    foreach ($vpaths as $p) {
        if (adb("shell \"test -d $p && echo found\"") === 'found') {
            erro("VIRTUAL APP DETECTADO → $p");
            file_put_contents($RESULT_FILE, "[VIRTUAL APP] $p\n", FILE_APPEND);
            $virtual = true;
            $score += 15;
        }
    }
    if ($virtual) criarArquivoDetecao("VirtualApp");

    // 4. GAME GUARDIAN
    secao(4, "VERIFICANDO GAME GUARDIAN");
    $gg = false;
    $ggfiles = adb('shell "find /sdcard -name \"*gg*\" -o -name \"*gameguardian*\" -o -name \"*.lua\" 2>/dev/null | head -15"');
    if (!empty(trim($ggfiles))) {
        erro("GAME GUARDIAN DETECTADO (arquivos .lua ou pastas GG)");
        file_put_contents($RESULT_FILE, "[GAME GUARDIAN]\n$ggfiles\n", FILE_APPEND);
        $gg = true;
        $score += 18;
    }
    if (adb('shell "ps -ef | grep -E \"gameguardian|ggapp\" | grep -v grep"')) {
        erro("PROCESSO GAME GUARDIAN EM EXECUÇÃO");
        $gg = true;
        $score += 16;
    }
    if ($gg) criarArquivoDetecao("GameGuardian");

    // 5. LUCKY PATCHER
    secao(5, "VERIFICANDO LUCKY PATCHER");
    $lp = false;
    $lppaths = ['/sdcard/LuckyPatcher', '/sdcard/Android/data/ru.yandex.lucky.patcher'];
    foreach ($lppaths as $p) {
        if (adb("shell \"test -d $p && echo found\"") === 'found') {
            erro("LUCKY PATCHER DETECTADO → $p");
            file_put_contents($RESULT_FILE, "[LUCKY PATCHER] $p\n", FILE_APPEND);
            $lp = true;
            $score += 17;
        }
    }
    if ($lp) criarArquivoDetecao("LuckyPatcher");

    // 6. WALLHACK / HOLOGRAMA (OTIMIZADO)
    secao(6, "VERIFICANDO WALLHACK / HOLOGRAMA");
    $wallhackDetectado = false;
    $pacoteDir = "/sdcard/Android/data/$pacote/files/contentcache/Optional/android";
    $pastasCriticas = ["$pacoteDir/gameassetbundles", "$pacoteDir/optionalavatarres", "$pacoteDir/optionalavatarres/gameassetbundles"];

    foreach ($pastasCriticas as $pasta) {
        if (adb("shell \"test -d '$pasta' && echo found\"") !== 'found') continue;

        $ts = adb("shell \"stat -c '%y %z' '$pasta' 2>/dev/null\"");
        if (empty($ts)) continue;

        [$modify, $change] = array_pad(explode(' ', trim($ts)), 2, '');
        if ($modify !== $change) {
            erro("WALLHACK / HOLOGRAMA DETECTADO → Modificação suspeita:");
            detalhe("Pasta: $pasta");
            detalhe("Modify: $modify | Change: $change");
            file_put_contents($RESULT_FILE, "[WALLHACK] Modificação em: $pasta\n", FILE_APPEND);
            $wallhackDetectado = true;
            $score += 22;
        }
    }
    if ($wallhackDetectado) criarArquivoDetecao("Wallhack");

    // 7. MREPLAYS (OTIMIZADO)
    secao(7, "VERIFICANDO MREPLAYS (REPLAY PASSADO)");
    $mreplaysDir = "/sdcard/Android/data/$pacote/files/MReplays";
    $mreplaysDetectado = false;

    if (adb("shell \"test -d '$mreplaysDir' && echo found\"") === 'found') {
        $permCheck = adb("shell \"ls '$mreplaysDir' 2>&1 | head -n 1\"");
        if (strpos($permCheck, 'Permission denied') !== false) {
            erro("MREPLAYS → Permissão de leitura removida (técnica de bypass)");
            file_put_contents($RESULT_FILE, "[MREPLAYS] Permissão removida intencionalmente\n", FILE_APPEND);
            $mreplaysDetectado = true;
            $score += 25;
        }

        $binFiles = adb("shell \"ls -lt '$mreplaysDir'/*.bin 2>/dev/null | head -8\"");
        if (!empty(trim($binFiles))) {
            erro("ARQUIVOS .bin ENCONTRADOS EM MREPLAYS (possível replay passado)");
            detalhe("Arquivos mais recentes:");
            echo c('bold', 'vermelho') . substr($binFiles, 0, 400) . "\n" . rst();
            file_put_contents($RESULT_FILE, "[MREPLAYS] Arquivos .bin:\n$binFiles\n", FILE_APPEND);
            $mreplaysDetectado = true;
            $score += 20;
        }
    }
    if ($mreplaysDetectado) criarArquivoDetecao("MReplays");

    // RESUMO FINAL
    secao(99, "RESUMO FINAL DO SCAN");

    if ($score >= 60) {
        erro("💀 CRÍTICO - ALTO RISCO DE CHEAT / BYPASS");
    } elseif ($score >= 40) {
        aviso("🚨 SUSPEITO FORTE");
    } elseif ($score >= 25) {
        aviso("⚠️ ATENÇÃO");
    } else {
        ok("✅ DISPOSITIVO PARECE LIMPO");
    }

    echo "\n" . c('bold', 'branco') . "  Score de risco: $score\n";
    echo "  Relatório completo: /sdcard/resultSCAN.txt\n" . rst();
    echo "  Arquivos de detecção criados na pasta 0.\n";

    file_put_contents($RESULT_FILE, "\nScore final: $score\nStatus: " . ($score >= 60 ? "CRITICO" : ($score >= 40 ? "SUSPEITO" : "ATENCAO")) . "\n=== FIM DO SCAN ===\n", FILE_APPEND);

    echo "\nPressione ENTER para voltar ao menu...";
    fgets(STDIN);
}

function exibirMenu(): void {
    system('clear');
    kellerBanner();
    echo c('bold', 'azul') . "  [1] Escanear Free Fire Normal\n";
    echo c('bold', 'azul') . "  [2] Escanear Free Fire MAX\n";
    echo c('bold', 'vermelho') . "  [0] Sair\n\n" . rst();
}

while (true) {
    exibirMenu();
    $op = trim(fgets(STDIN));

    if ($op === '1') {
        scanCompleto('com.dts.freefireth', 'Free Fire Normal');
    } elseif ($op === '2') {
        scanCompleto('com.dts.freefiremax', 'Free Fire MAX');
    } elseif ($op === '0') {
        echo "\nObrigado por usar o scanner!\n";
        exit(0);
    } else {
        aviso("Opção inválida! Tente novamente.");
        sleep(1);
    }
}
