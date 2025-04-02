@echo off
setlocal enabledelayedexpansion

REM ����DNS��ַ
set "dns1=10.10.13.186"
set "dns2=10.10.13.251"
set "dns3=192.168.10.110"

REM ���������������������ҵ��ԡ���̫������ͷ�Ҵ��ڡ������ӡ�״̬��������
for /f "tokens=1,2,3,* delims= " %%a in ('netsh interface show interface ^| findstr /R /C:"������"') do (
    echo %%d | findstr /R "^��̫��.*$" >nul
    if not errorlevel 1 (
        set "adapter=%%d"
        echo Configuring DNS settings for adapter: !adapter!

        REM ���õ�һ��DNSΪ��DNS
        netsh interface ipv4 set dns name="!adapter!" static %dns1% primary
        if errorlevel 1 (
            echo Failed to set primary DNS to %dns1% for adapter !adapter!.
        ) else (
            echo Primary DNS set to %dns1% for adapter !adapter!.
        )

        REM ���ӵڶ���DNS
        netsh interface ipv4 add dns name="!adapter!" addr=%dns2% index=2
        if errorlevel 1 (
            echo Failed to add DNS %dns2% as secondary for adapter !adapter!.
        ) else (
            echo Secondary DNS added: %dns2% for adapter !adapter!.
        )

        REM ���ӵ�����DNS
        netsh interface ipv4 add dns name="!adapter!" addr=%dns3% index=3
        if errorlevel 1 (
            echo Failed to add DNS %dns3% as tertiary for adapter !adapter!.
        ) else (
            echo Tertiary DNS added: %dns3% for adapter !adapter!.
        )
    )
)

echo DNS configuration completed for all matched and enabled adapters.