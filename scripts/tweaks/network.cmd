:: Find the LAN/Ethernet device guid with key
for /f "delims=" %%a in ('powershell -noprofile -c "Get-CimInstance -ClassName Win32_PnPEntity | where-object {($_.PNPClass -match 'Net') -and ($_.Status -match 'OK') -and ($_.Name -like '*Connection*')} | ForEach-Object { ($_ | Invoke-CimMethod -MethodName GetDeviceProperties).deviceProperties.where({$_.KeyName -EQ 'DEVPKEY_Device_Driver'}).data }"') do set "ETHERNET_DEVICE_CLASS_GUID_WITH_KEY=%%a"

:: Get cores and threads quantity
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfCores /value') do set /a CoresQty=%%a
for /f "tokens=2 delims==" %%a in ('wmic cpu get NumberOfLogicalProcessors /value') do set /a LogicalProcessorsQty=%%a

:: Set MTU value
set /a MTU=1400

:: Set to a core value, non-zero
set /a RSSBaseNumber=2

:: =============================================================================================================================================================================================

:: Optmize network card settings
powershell Set-NetOffloadGlobalSetting -ReceiveSegmentCoalescing Disabled -ErrorAction SilentlyContinue
powershell Set-NetOffloadGlobalSetting -PacketCoalescingFilter Disabled -ErrorAction SilentlyContinue
powershell Set-NetOffloadGlobalSetting -Chimney Disabled -ErrorAction SilentlyContinue
powershell Set-NetOffloadGlobalSetting -ReceiveSideScaling Enabled -ErrorAction SilentlyContinue
powershell Set-NetOffloadGlobalSetting -TaskOffload Enabled -ErrorAction SilentlyContinue
powershell Set-NetOffloadGlobalSetting -ScalingHeuristics Disabled -ErrorAction SilentlyContinue
powershell Set-NetTCPSetting -SettingName "*" -InitialCongestionWindow 10 -MinRto 300 -ErrorAction SilentlyContinue
powershell Set-NetIPv4Protocol -MulticastForwarding Disabled -MediaSenseEventLog Disabled -ErrorAction SilentlyContinue
powershell Disable-NetAdapterLso -Name "*" -ErrorAction SilentlyContinue
powershell Disable-NetAdapterRsc -Name "*" -ErrorAction SilentlyContinue
powershell Disable-NetAdapterIPsecOffload -Name "*" -ErrorAction SilentlyContinue
powershell Disable-NetAdapterPowerManagement -Name "*" -ErrorAction SilentlyContinue
powershell Disable-NetAdapterQos -Name "*" -ErrorAction SilentlyContinue
powershell Disable-NetAdapterUso -Name "*" -ErrorAction SilentlyContinue
powershell Enable-NetAdapterEncapsulatedPacketTaskOffload -Name "*" -ErrorAction SilentlyContinue

powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_lldp -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_lltdio -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_msclient -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_rspndr -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_server -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_implat -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_pacer -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_pppoe -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_rdma_ndk -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_ndisuio -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_wfplwf_upper -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_wfplwf_lower -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_netbt -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_netbios -ErrorAction SilentlyContinue
powershell Disable-NetAdapterBinding -Name "*" -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue

:: ===================================================================================================================================================================================

:: Optimize OS network settings
netsh winsock reset
netsh winsock set autotuning on
netsh interface teredo set state disabled
netsh interface 6to4 set state disabled
netsh interface isatap set state disable
netsh int tcp set heuristics wsh=disabled forcews=enabled
netsh int ip set global neighborcachelimit=4096
netsh int tcp set heuristics disabled

:: Disabled: Greatly reduce / complete remove bufferbloat in exchange of reducing bandwidth throughput slightly, depending on your connection. If not worth enough, I suggest the "normal" value instead.
:: It will resolve the bufferbloat only in your machine, if you are making downloads/uploads while playing. It will NOT resolve the issue in your whole network, for that to happen it needs to be in the router, and your router and routerOS must support and enable it.
:: Why router and routerOS, because router must have good enough hardware to be able to handle if you have a internet connection with a lot of bandwidth and routerOS as software functionality so you can enable it.
:: Even though it's a tcp setting, and many games use UDP, you are more likely to exaust your network bandwidth with TCP than with UDP.
:: https://www.waveform.com/tools/bufferbloat
netsh int tcp set global autotuninglevel=disabled

:: CongestionProvider bbr2 recently added into Win11, should bring better performance over all others, it will be set if available.
netsh int tcp set supplemental Internet congestionprovider=newreno
netsh int tcp set supplemental Internet congestionprovider=bbr2
netsh int tcp set supplemental InternetCustom congestionprovider=newreno
netsh int tcp set supplemental InternetCustom congestionprovider=bbr2
netsh int tcp set global chimney=disabled
netsh int tcp set global ecncapability=disabled
netsh int tcp set global rss=enabled
netsh int tcp set global rsc=disabled
netsh int tcp set global dca=enabled
netsh int tcp set global netdma=enabled
netsh int tcp set global nonsackrttresiliency=disabled
netsh int tcp set global timestamps=disabled
netsh int tcp set global fastopen=enabled
netsh int tcp set global fastopenfallback=disabled
netsh int tcp set global initialRto=2000
netsh int tcp set global maxsynretransmissions=2
netsh int tcp set global pacingprofile=off
netsh int tcp set global hystart=disabled
netsh int tcp set security profiles=disabled
netsh int tcp set security mpp=disable
netsh int udp set global uro=enabled
netsh interface ip set interface ethernet currenthoplimit=64
netsh interface ip set interface ethernet weakhostsend=enabled
netsh interface ip set interface ethernet weakhostreceive=enabled

:: Find your optimal MTU that is not fragmented, use the command below. Start from 1500 and dont go below 1400.
:: ping 1.1.1.1 -f -l 1500
:: Only problem here, is that this is based on a value already preset on windows, usually 1500. To be fragmented or not, it is not considering what comes before your PC.
:: Why? Because it matters the MTU value from your ISP, Modem / Router and whatever else you might have in between, only then you would know the best value to not be fragmented, therefore have no packet loss (because the remaining bytes are dropped), most noticed in games.
:: If I am not mistaken (I could be), you should use the lowest value from what comes from before your PC, set that on windows and then do the ping / packet fragmentation test from that value till not fragmented, then you set that value as the MTU, and it should be the optimal. I suppose 1400 could be a fragmentation safety value.
:: https://www.cloudflare.com/learning/network-layer/what-is-mtu/ - Dont mind about MSS, that is based on the MTU value.
:: In the internet, you will find many repetitions of the same thing and that is not complete, probably one copied from the other without fully understanding. Not that I do.
:: To see the current MTU value set in Windows, use: netsh interface ipv4 show subinterface
powershell "$AdapterName = $(Get-NetAdapter | Where { $_.InterfaceDescription -Match 'Connection' }).Name; netsh interface ipv4 set subinterface "$AdapterName" mtu=%MTU% store=persistent"

ipconfig /flushdns
ipconfig /release
ipconfig /renew
arp -d *
netsh interface ip delete arpcache
netsh branchcache reset

:: =============================================================================================================================================================================================

:: Disable QoS and NdisCap
FOR /F "tokens=3*" %%I IN ('REG QUERY "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\NetworkCards" /F "ServiceName" /S^| FINDSTR /I /L "ServiceName"') DO (
	FOR /F %%a IN ('REG QUERY "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Class\{4D36E972-E325-11CE-BFC1-08002BE10318}" /F "%%I" /D /E /S^| FINDSTR /I /L "\\Class\\"') DO SET "REGPATH=%%a"
	FOR /F "tokens=3*" %%n in ('REG QUERY "!REGPATH!" /V "FilterList"') DO SET newFilterList=%%n
	SET newFilterList=!newFilterList:-{B5F4D659-7DAA-4565-8E41-BE220ED60542}=!
	SET newFilterList=!newFilterList:-{430BDADD-BAB0-41AB-A369-94B67FA5BE0A}=!
	REG QUERY !REGPATH! /V "FilterList" | FINDSTR /I "{B5F4D659-7DAA-4565-8E41-BE220ED60542} {430BDADD-BAB0-41AB-A369-94B67FA5BE0A}" >NUL 2>&1
	IF NOT ERRORLEVEL 1 (
		REG ADD !REGPATH! /F /V "FilterList" /T REG_MULTI_SZ /d "!newFilterList!" >NUL 2>&1
	)
)

:: Remove adapters off QoS Service
FOR /F %%a in ('REG QUERY "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Psched\Parameters\Adapters"') DO (
	REG DELETE %%a /F >NUL 2>&1
	FOR /F "tokens=*" %%z IN ("%%a") DO (
		SET STR=%%z
		SET STR=!STR:HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Psched\Parameters\Adapters\=!
	)
)

:: Disable TCP delay
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSMQ\Parameters" /v TCPNoDelay /t REG_DWORD /d 1 /f

:: Tweak Tcpip interfaces
for /f %%r in ('REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" /f 1 /d /s^|Findstr HKEY_') do (
	REG ADD %%r /v NonBestEffortLimit /t REG_DWORD /d 0 /f
	REG ADD %%r /v DeadGWDetectDefault /t REG_DWORD /d 1 /f
	REG ADD %%r /v PerformRouterDiscovery /t REG_DWORD /d 1 /f
	REG ADD %%r /v TCPNoDelay /t REG_DWORD /d 1 /f
	REG ADD %%r /v TcpAckFrequency /t REG_DWORD /d 1 /f
	REG ADD %%r /v TcpInitialRTT /t REG_DWORD /d 2 /f
	REG ADD %%r /v TcpDelAckTicks /t REG_DWORD /d 0 /f
	REG ADD %%r /v UseZeroBroadcast /t REG_DWORD /d 0 /f
	REG ADD %%r /v InterfaceMetric /t REG_DWORD /d 55 /f
)

:: Disable IPV6
REG ADD "HKEY_LOCAL_MACHINE\System\CurrentControlSet\services\Tcpip6\Parameters" /v EnableICSIPv6 /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\Tcpip6\Parameters" /v DisabledComponents /t REG_DWORD /d 255 /f

:: Disable 20% bandwidth reservation
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Psched" /v NonBestEffortLimit /t REG_DWORD /d 0 /f

:: Set most frequent packaet transmission
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\Psched" /v TimerResolution /t REG_DWORD /d 1 /f

:: Remove network throttling
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" /v NetworkThrottlingIndex /t REG_DWORD /d 0xffffffff /f

:: TCPIP and NetBT Optimizations
:: REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /t REG_DWORD /d 64 /f :: Removed in favor of MultihopsSets
REG DELETE "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DefaultTTL /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MultihopSets /t REG_DWORD /d 0x0000000f /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpTimedWaitDelay /t REG_DWORD /d 30 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnablePMTUBHDetect /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v KeepAliveTime /t REG_DWORD /d 0x006ddd00 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v QualifyingDestinationThreshold /t REG_DWORD /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpCreateAndConnectTcbRateLimitDepth /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DelayedAckFrequency /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DelayedAckTicks /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v CongestionAlgorithm /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableDCA /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableWsd /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableTCPA /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableConnectionRateLimiting /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DeadGWDetectDefault /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v GlobalMaxTcpWindowSize /t REG_DWORD /d 65535 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v TcpWindowSize /t REG_DWORD /d 65535 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxUserPort /t REG_DWORD /d 65534 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxFreeTcbs /t REG_DWORD /d 65536 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v Tcp1323Opts /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v DisableTaskOffload /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaximumReassemblyHeaders /t REG_DWORD /d 0xffff /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableTCPChimney /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v EnableRSS /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxNumRssCpus /t REG_DWORD /d %CoresQty% /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" /v MaxNumRssThreads /t REG_DWORD /d %LogicalProcessorsQty% /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NetBT\Parameters" /v NameSrvQueryTimeout /t REG_DWORD /d 3000 /f
REG ADD "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NetBT\Parameters" /v EnableLMHOSTS /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NetBT\Parameters" /v NodeType /t REG_DWORD /d 2 /f
REG ADD "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NetBT\Parameters" /v EnablePMTUDiscovery /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NetBT\Parameters" /v SackOpts /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\System\CurrentControlSet\Services\NetBT\Parameters" /v TCPCongestionControl /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Winsock" /v UseDelayedAcceptance /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Winsock" /v MaxSockAddrLength /t REG_DWORD /d 16 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Winsock" /v MinSockAddrLength /t REG_DWORD /d 16 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v "Do not use NLA" /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v EnableRSVP /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\QoS" /v EnablePriorityBoost /t REG_DWORD /d 0 /f

:: TCPIP priorities
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v LocalPriority /t REG_DWORD /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v HostsPriority /t REG_DWORD /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v DnsPriority /t REG_DWORD /d 6 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Tcpip\ServiceProvider" /v NetbtPriority /t REG_DWORD /d 7 /f

:: DNS cache optimizations
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v ServiceDllUnloadOnStop /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheTtl /t REG_DWORD /d 13824 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxNegativeCacheTtl /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NetFailureCacheTime /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NegativeSOACacheTime /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v NegativeCacheTime /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableBucketSize /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxCacheEntryTtlLimit /t REG_DWORD /d 86400 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaxSOACacheEntryTtlLimit /t REG_DWORD /d 300 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v CacheHashTableSize /t REG_DWORD /d 384 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v MaximumUdpPacketSize /t REG_DWORD /d 1300 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v RegistrationRefreshInterval /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v EnableAutoDoh /t REG_DWORD /d 2 /f

:: Disable multicast
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\DnsClient" /v EnableMulticast /t REG_DWORD /d 0 /f

:: Ethernet settings optimizations
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*JumboPacket" /t REG_SZ /d 1514 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*FlowControl" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*TransmitBuffers" /t REG_SZ /d 2048 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*ReceiveBuffers" /t REG_SZ /d 2048 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*TCPChecksumOffloadIPv4" /t REG_SZ /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*TCPChecksumOffloadIPv6" /t REG_SZ /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*UDPChecksumOffloadIPv4" /t REG_SZ /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*UDPChecksumOffloadIPv6" /t REG_SZ /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*IPChecksumOffloadIPv4" /t REG_SZ /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*TCPUDPChecksumOffloadIPv4" /t REG_SZ /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*TCPUDPChecksumOffloadIPv6" /t REG_SZ /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v ITR /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*InterruptModeration" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*PriorityVLANTag" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*LsoV1IPv4" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*LsoV2IPv4" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*LsoV2IPv6" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v AdaptiveIFS /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*PMARPOffload" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*PMNSOffload" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v EnableTss /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v AllowAllSpeedsLPLU /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v WakeOnFastStartup /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v RxIntModerationProfile /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v TxIntModerationProfile /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v RxIntModeration /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v TxIntModeration /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v TxIntDelay /t REG_SZ /d 5 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v PacketDirect /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v DisableDelayedPowerUp /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v EnableCoalesce /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v EnableUdpTxScaling /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v AlternateSemaphoreDelay /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v BlueFlame /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v RssV2 /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v ValidateRssV2 /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v ThreadedDpcEnable /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v TxThreadedDpcEnable /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v CheckForHangTOInSeconds /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v RecvCompletionMethod /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v SendCompletionMethod /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v AsyncReceiveIndicate /t REG_SZ /d 2 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*RscIPv4" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*RscIPv6" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*PtpHardwareTimestamp" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*SoftwareTimestamp" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v StridingRqEnabled /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v EnableZtt /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v RxSmallPacketBypass /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v TCStallEnable /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*IPsecOffloadV1IPv4" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*IPsecOffloadV2" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*IPsecOffloadV2IPv4" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v RelaxedOrderingWrite /t REG_SZ /d 1 /f

:: If Auto Negotiation are causing disconnect issues, try set 1GBps full duplex
:: REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*SpeedDuplex" /t REG_SZ /d 6 /f

:: Lower might process packets faster but could increase CPU usage
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v ThreadPoll /t REG_SZ /d 2000 /f

:: Higher value might process packets faster.
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v MaxCallsToNdisIndicate /t REG_SZ /d 32 /f

:: https://learn.microsoft.com/en-us/windows-hardware/drivers/network/setting-the-number-of-rss-processors
:: https://learn.microsoft.com/en-us/windows-hardware/drivers/network/introduction-to-receive-side-scaling
:: Run this powershell command Get-NetAdapterRss, if you want to know whether RSS are working in your machine, if the indirection table are filled, it is, if not, then it's not.
:: Beware that, to have RSS working, you must have Task Offload enabled, along some other ones related to Offload and Checksum.
:: If you have an Intel and indirection table are still coming out empty even after all these changes, be sure to remove the intel driver and let it default to microsoft ethernet driver or try an older version of intel.
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*NumRSSQueues" /t REG_SZ /d %CoresQty% /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*RSS" /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*RssBaseProcNumber" /t REG_SZ /d %RSSBaseNumber% /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*MaxRssProcessors" /t REG_SZ /d %CoresQty% /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*RssMaxProcNumber" /t REG_SZ /d %LogicalProcessorsQty% /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*NumaNodeId" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*RssBaseProcGroup" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*RssMaxProcGroup" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*RSSProfile" /t REG_SZ /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*RssOrVmqPreference" /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "*RssOnHostVPorts" /t REG_SZ /d 0 /f

:: For whatever reason, this reg was causing RSS Indirection table to not output anything.
:: Only information I could find is that 0 is Static Mode and 1 is Dynamic Mode for RSS. I suppose it prefers Static Mode, and it's more performant too.
:: Static Mode, the CPU core assignments for processing network traffic remain fixed and do not change dynamically. This means that each network queue is associated with a specific CPU core, and this assignment doesn't fluctuate based on system load or network conditions.
:: REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v ReceiveScalingMode /t REG_SZ /d 1 /f

:: NDI Tweaks
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumRSSQueues" /v ParamDesc /t REG_SZ /d "Maximum Number of RSS Queues" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumRSSQueues" /v default /t REG_SZ /d 4 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumRSSQueues" /v type /t REG_SZ /d enum /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumRSSQueues\Enum" /v 1 /t REG_SZ /d "1 Queue" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumRSSQueues\Enum" /v 2 /t REG_SZ /d "2 Queues" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumRSSQueues\Enum" /v 4 /t REG_SZ /d "4 Queues" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumRSSQueues\Enum" /v 8 /t REG_SZ /d "8 Queues" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumRSSQueues\Enum" /v 16 /t REG_SZ /d "16 Queues" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RSSProfile" /v ParamDesc /t REG_SZ /d "RSS load balancing profile" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RSSProfile" /v default /t REG_SZ /d 3 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RSSProfile" /v type /t REG_SZ /d enum /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RSSProfile\Enum" /v 1 /t REG_SZ /d ClosestProcessor /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RSSProfile\Enum" /v 2 /t REG_SZ /d ClosestProcessorStatic /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RSSProfile\Enum" /v 3 /t REG_SZ /d NUMAScaling /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RSSProfile\Enum" /v 4 /t REG_SZ /d NUMAScalingStatic /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RSSProfile\Enum" /v 5 /t REG_SZ /d ConservativeScaling /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumaNodeId" /v ParamDesc /t REG_SZ /d "Preferred NUMA node" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumaNodeId" /v default /t REG_SZ /d 65535 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumaNodeId" /v type /t REG_SZ /d dword /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumaNodeId" /v min /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumaNodeId" /v max /t REG_SZ /d 65535 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*NumaNodeId" /v step /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*MaxRssProcessors" /v ParamDesc /t REG_SZ /d "Maximum number of RSS Processors" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*MaxRssProcessors" /v default /t REG_SZ /d 8 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*MaxRssProcessors" /v type /t REG_SZ /d enum /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*MaxRssProcessors\Enum" /v 1 /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*MaxRssProcessors\Enum" /v 2 /t REG_SZ /d 2 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*MaxRssProcessors\Enum" /v 4 /t REG_SZ /d 4 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*MaxRssProcessors\Enum" /v 8 /t REG_SZ /d 8 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*MaxRssProcessors\Enum" /v 16 /t REG_SZ /d 16 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RssBaseProcNumber" /v ParamDesc /t REG_SZ /d "RSS Base Processor Number" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RssBaseProcNumber" /v default /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RssBaseProcNumber" /v type /t REG_SZ /d int /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RssBaseProcNumber" /v min /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RssBaseProcNumber" /v max /t REG_SZ /d 63 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RssBaseProcNumber" /v step /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*RssBaseProcNumber" /v Optional /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*ReceiveBuffers" /v ParamDesc /t REG_SZ /d "Receive Buffers" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*ReceiveBuffers" /v default /t REG_SZ /d 512 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*ReceiveBuffers" /v min /t REG_SZ /d 32 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*ReceiveBuffers" /v max /t REG_SZ /d 2048 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*ReceiveBuffers" /v step /t REG_SZ /d 8 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*ReceiveBuffers" /v Base /t REG_SZ /d 10 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*ReceiveBuffers" /v type /t REG_SZ /d int /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*TransmitBuffers" /v ParamDesc /t REG_SZ /d "Transmit Buffers" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*TransmitBuffers" /v default /t REG_SZ /d 512 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*TransmitBuffers" /v min /t REG_SZ /d 32 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*TransmitBuffers" /v max /t REG_SZ /d 2048 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*TransmitBuffers" /v step /t REG_SZ /d 8 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*TransmitBuffers" /v Base /t REG_SZ /d 10 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\Ndi\Params\*TransmitBuffers" /v type /t REG_SZ /d int /f

:: PROSetNdi tweaks
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\PROSetNdi" /v EnableLLI /t REG_SZ /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\PROSetNdi\Params\EnableLLI" /v ParamDesc /t REG_SZ /d "Low Latency Interrupts" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\PROSetNdi\Params\EnableLLI" /v default /t REG_SZ /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\PROSetNdi\Params\EnableLLI" /v type /t REG_SZ /d enum /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\PROSetNdi\Params\EnableLLI\Enum" /v 0 /t REG_SZ /d "Disabled" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\PROSetNdi\Params\EnableLLI\Enum" /v 1 /t REG_SZ /d "Port Based" /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%\PROSetNdi\Params\EnableLLI\Enum" /v 2 /t REG_SZ /d "PSH Based" /f

:: NDIS tweaks
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v MaxNumRssCpus /t REG_DWORD /d %CoresQty% /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v MaxNumRssThreads /t REG_DWORD /d %LogicalProcessorsQty% /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v ProcessorAffinityMask /t REG_DWORD /d 55 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v RssBaseCpu /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v smpAffinitized /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v smpProcessorAffinityMask /t REG_DWORD /d 55 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v smpProcessorAffinityMask2 /t REG_DWORD /d 55 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\NDIS\Parameters" /v ThreadPoolUseIdealCpu /t REG_DWORD /d 0 /f

:: Disable windows network crawling
REG ADD "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v NoNetCrawling /t REG_DWORD /d 1 /f

:: AFD optimizations
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DynamicSendBufferDisable /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v IgnorePushBitOnReceives /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v NonBlockingSendSpecialBuffering /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DisableRawSecurity /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DefaultReceiveWindow /t REG_DWORD /d 0x10000 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DefaultSendWindow /t REG_DWORD /d 0x10000 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v EnableDynamicBacklog /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v MinimumDynamicBacklog /t REG_DWORD /d 20 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v MaximumDynamicBacklog /t REG_DWORD /d 20000 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DynamicBacklogGrowthDelta /t REG_DWORD /d 10 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v PriorityBoost /t REG_DWORD /d 8 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v IRPStackSize /t REG_DWORD /d 50 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v LargeBufferSize /t REG_DWORD /d 32768 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v MediumBufferSize /t REG_DWORD /d 12032 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v SmallBufferSize /t REG_DWORD /d 1024 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v TransmitWorker /t REG_DWORD /d 32 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v MaxFastTransmit /t REG_DWORD /d 64 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v MaxFastCopyTransmit /t REG_DWORD /d 128 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DisableAddressSharing /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v StandardAddressLength /t REG_DWORD /d 1024 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v transmitIoLength /t REG_DWORD /d 4294967295 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v DoNotHoldNicBuffers /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v FastSendDatagramThreshold /t REG_DWORD /d %MTU% /f
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\AFD\Parameters" /v FastCopyReceiveThreshold /t REG_DWORD /d %MTU% /f

:: Disable NetBIOS (partial with services)
for /f %%i in ('REG QUERY "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\NetBT\Parameters\Interfaces" /s /f "NetbiosOptions"^| findstr "HKEY"') do REG ADD "%%i" /v NetbiosOptions /t REG_DWORD /d 2 /f >nul 2>&1

:: Disable WPAD
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Wpad" /v WpadOverride /t REG_DWORD /d 1 /f

:: Disable smart multi-homed name resolution
REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" /v DisableParallelAandAAAA /t REG_DWORD /d 1 /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient" /v DisableSmartNameResolution /t REG_DWORD /d 1 /f

:: Disable wi-fi sense
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\wcmsvc\wifinetworkmanager\config" /v AutoConnectAllowedOEM /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\wcmsvc\wifinetworkmanager" /v WifiSenseCredShared /t REG_DWORD /d 0 /f
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\wcmsvc\wifinetworkmanager" /v WifiSenseOpen /t REG_DWORD /d 0 /f

:: Disable hotspot 2.0 networks
REG ADD "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\WlanSvc\AnqpCache" /v OsuRegistrationStatus /t REG_DWORD /d 0 /f

:: Disable more power saving features
for %%i in (
	"EEE"
	"*EEE"
	"*SelectiveSuspend"
	"*WakeOnMagicPacket"
	"*WakeOnPattern"
	"AdvancedEEE"
	"AutoDisableGigabit"
	"AutoPowerSaveModeEnabled"
	"EnableConnectedPowerGating"
	"EnableDynamicPowerGating"
	"EnableGreenEthernet"
	"EnableModernStandby"
	"EnablePME"
	"EnablePowerManagement"
	"EnableSavePowerNow"
	"GigaLite"
	"PowerSavingMode"
	"ReduceSpeedOnPowerDown"
	"ULPMode"
	"WakeOnLink"
	"WakeOnSlot"
	"WakeUpModeCap"
	"PowerDownPll"
	"*NicAutoPowerSaver"
	"EeePhyEnable"
	"MasterSlave"
	"SavePowerNowEnabled"
	"SipsEnabled"
	"MPC"
	"PowerSaveMode"
	"ApCompatMode"
	"bLeisurePs"
	"bLowPowerEnable"
	"bAdvancedLPs"
	"InactivePs"
	"Enable9KJFTpt"
	"DMACoalescing"
	"PMWiFiRekeyOffload"
	"uAPSDSupport"
	"*PacketCoalescing"
	"NSOffloadEnable"
	"ARPOffloadEnable"
	"GTKOffloadEnable"
	"WoWLANLPSLevel"
	"*ModernStandbyWoLMagicPacket"
	"S5WakeOnLan"
	"WakeOnDisconnect"
	"WoWLANS5Support"
	"EnableWakeOnLan"
	"EEELinkAdvertisement"
	"EnableWakeOnManagmentOnTCO"
	"LogLinkStateEvent"
	"*DeviceSleepOnDisconnect"
) do (
    REG ADD "HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\Class\%ETHERNET_DEVICE_CLASS_GUID_WITH_KEY%" /v "%%i" /t REG_SZ /d 0 /f
)

:: It seems that deep packet inspection can introduce some latency to even UDP packets, a way would be to disable the Windows Filtering Platform (WFP), but not really recommended.
:: netsh advfirewall set allprofiles state off

:: Restart ethernet adapter at the end
powershell "Restart-NetAdapter -Name '*'"
