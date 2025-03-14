@echo off
setlocal enabledelayedexpansion

REM 设置DNS地址
set "dns1=192.168.13.186"
set "dns2=192.168.13.251"
set "dns3=192.168.10.110"

REM 遍历所有网络适配器，找到以“以太网”开头且处于“已连接”状态的适配器
for /f "tokens=1,2,3,* delims= " %%a in ('netsh interface show interface ^| findstr /R /C:"已连接"') do (
    echo %%d | findstr /R "^以太网.*$" >nul
    if not errorlevel 1 (
        set "adapter=%%d"
        echo Configuring DNS settings for adapter: !adapter!

        REM 设置第一个DNS为主DNS
        netsh interface ipv4 set dns name="!adapter!" static %dns1% primary
        if errorlevel 1 (
            echo Failed to set primary DNS to %dns1% for adapter !adapter!.
        ) else (
            echo Primary DNS set to %dns1% for adapter !adapter!.
        )

        REM 添加第二个DNS
        netsh interface ipv4 add dns name="!adapter!" addr=%dns2% index=2
        if errorlevel 1 (
            echo Failed to add DNS %dns2% as secondary for adapter !adapter!.
        ) else (
            echo Secondary DNS added: %dns2% for adapter !adapter!.
        )

        REM 添加第三个DNS
        netsh interface ipv4 add dns name="!adapter!" addr=%dns3% index=3
        if errorlevel 1 (
            echo Failed to add DNS %dns3% as tertiary for adapter !adapter!.
        ) else (
            echo Tertiary DNS added: %dns3% for adapter !adapter!.
        )
    )
)

echo DNS configuration completed for all matched and enabled adapters.