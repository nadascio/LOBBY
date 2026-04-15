@echo off
set PORT=8889
:: IR A LA CARPETA RAIZ (El BAT esta en /data)
cd /d "%~dp0.."
title LOBBY_HOST_LAUNCHER

:: [LIMPIEZA]
echo [0/3] Limpiando sesiones previas en puerto %PORT%...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :%PORT% ^| findstr LISTENING') do (
    taskkill /f /pid %%a >nul 2>&1
)

:: Pequeña pausa para que Windows procese el cierre de sockets
timeout /t 1 /nobreak >nul

cls
echo ==========================================================
echo          LANZADOR DE LOBBY INTERACTIVO
echo ==========================================================
echo.
echo  [1/2] Iniciando servidor local en puerto %PORT%...
echo  [2/2] Abriendo LOBBY en el navegador...
echo.
echo  IMPORTANTE: NO CIERRES ESTA VENTANA mientras uses
echo              el Lobby.
echo.
echo ==========================================================

:: Servidor Micro-HTTP en PowerShell (Versión Anti-Cache)
powershell -ExecutionPolicy Bypass -Command "$p=%PORT%;$l=[System.Net.HttpListener]::new();$l.Prefixes.Add('http://localhost:'+$p+'/');try{$l.Start();Write-Host ('Servidor Activo en http://localhost:'+$p)}catch{Write-Host 'Error: Puerto '+$p+' ocupado o acceso denegado.';pause;exit}; $nc=[guid]::NewGuid().ToString().Substring(0,8); Start-Process ('http://localhost:'+$p+'/data/LOBBY.html?v='+$nc); while($l.IsListening){try{$c=$l.GetContext();$req=$c.Request;$res=$c.Response;$res.Headers.Add('Cache-Control','no-store, no-cache, must-revalidate, max-age=0');$res.Headers.Add('Pragma','no-cache');$res.Headers.Add('Access-Control-Allow-Origin','*'); $lp=$req.Url.LocalPath; Write-Host ('['+(Get-Date -Format 'HH:mm:ss')+'] '+$req.HttpMethod+' '+$lp); if($lp -eq '/assets'){ $cvs=Get-ChildItem -Path data/covers -Filter portada*|Select-Object -ExpandProperty Name; $lgs=Get-ChildItem -Path data/logos -Filter logo*|Select-Object -ExpandProperty Name; $json='{\"covers\":[\"'+($cvs -join '\",\"')+'\"],\"logos\":[\"'+($lgs -join '\",\"')+'\"]}'; $res.ContentType='application/json'; $b=[System.Text.Encoding]::UTF8.GetBytes($json); $res.OutputStream.Write($b,0,$b.Length); $res.Close(); continue }; if($req.HttpMethod -eq 'POST' -and $lp -eq '/upload'){ $fn=$req.QueryString['f']; $out=Join-Path (Get-Location) $fn; $in=$req.InputStream; $fs=[System.IO.File]::Create($out); $in.CopyTo($fs); $fs.Close(); $res.StatusCode = 200; $res.Close(); continue }; $path=$lp.TrimStart('/');if(!$path){$path='data/LOBBY.html'};$f=Join-Path (Get-Location) $path;if(Test-Path $f -PathType Leaf){$ext=[System.IO.Path]::GetExtension($f).ToLower();$mime='text/plain';if($ext -eq '.html'){$mime='text/html'}elseif($ext -eq '.png'){$mime='image/png'}elseif($ext -eq '.jpg'){$mime='image/jpeg'}elseif($ext -eq '.css'){$mime='text/css'}elseif($ext -eq '.js'){$mime='application/javascript'};$res.ContentType=$mime;$b=[System.IO.File]::ReadAllBytes($f);$res.OutputStream.Write($b,0,$b.Length)}else{$res.StatusCode=404};$res.Close()}catch{Write-Host ('!! Error detectado: '+$_.Exception.Message); if($res){$res.Close()}}}"
