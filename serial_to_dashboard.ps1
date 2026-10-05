$BaudRate = 115200
$ApiUrl = 'http://localhost:4000/api/v1/sensors/ingest'
$HardwareUrl = 'http://localhost:4000/api/v1/hardware/latest'
$DeviceId = 'esp32-bluetooth-bridge'
$DefaultPressureHpa = 1013.25

function Get-AvailablePorts {
    $ports = [System.IO.Ports.SerialPort]::GetPortNames() | Sort-Object
    if (-not $ports) {
        Write-Host 'No COM ports found. Connect the ESP32 first.' -ForegroundColor Yellow
        return @()
    }

    Write-Host 'Available COM ports:' -ForegroundColor Cyan
    foreach ($port in $ports) {
        Write-Host "  - $port"
    }

    return $ports
}

function Get-NormalizedPayload {
    param(
        [pscustomobject]$JsonData,
        [double]$FallbackPressure
    )

    $pressure = $JsonData.pressure
    if ($null -eq $pressure -or $pressure -eq '') {
        $pressure = $FallbackPressure
        Write-Host ("[WARN] Pressure missing in current ESP32 reading, using {0:N2} hPa" -f $pressure) -ForegroundColor Yellow
    }

    return @{
        deviceId = $DeviceId
        temperatureC = [double]$JsonData.temp
        humidityPct = [double]$JsonData.humidity
        pressureHpa = [double]$pressure
        rainAnalog = [Math]::Max(0, [Math]::Min(100, [int]$JsonData.rain_level))
        capturedAt = [DateTime]::UtcNow.ToString('o')
    }
}

function Send-Payload {
    param([hashtable]$Payload)

    try {
        $json = $Payload | ConvertTo-Json -Depth 4
        $null = Invoke-RestMethod -Uri $ApiUrl -Method Post -ContentType 'application/json' -Body $json
        Write-Host ("[API] Sent {0:N2} C, {1:N2} %, rain {2}%" -f $Payload.temperatureC, $Payload.humidityPct, $Payload.rainAnalog) -ForegroundColor Green
    } catch {
        Write-Host ("[API] Failed: {0}" -f $_.Exception.Message) -ForegroundColor Red
    }
}

function Send-HardwareReading {
    param([pscustomobject]$JsonData)

    try {
        $body = @{
            deviceId = $DeviceId
            source = 'serial-bridge'
            time = [int64]$JsonData.time
            temp = [double]$JsonData.temp
            humidity = [double]$JsonData.humidity
            pressure = if ($null -eq $JsonData.pressure -or $JsonData.pressure -eq '') { $null } else { [double]$JsonData.pressure }
            rain_level = [Math]::Max(0, [Math]::Min(100, [int]$JsonData.rain_level))
            rain_detected = [bool]$JsonData.rain_detected
            capturedAt = [DateTime]::UtcNow.ToString('o')
        }

        $json = $body | ConvertTo-Json -Depth 4
        $null = Invoke-RestMethod -Uri $HardwareUrl -Method Post -ContentType 'application/json' -Body $json
        Write-Host '[HW] Latest raw hardware reading updated.' -ForegroundColor DarkCyan
    } catch {
        Write-Host ("[HW] Failed: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
    }
}

$ports = Get-AvailablePorts
if (-not $ports.Count) {
    exit 1
}

$selectedPort = Read-Host 'Enter the COM port to bridge (example: COM10)'
if ([string]::IsNullOrWhiteSpace($selectedPort)) {
    Write-Host 'No COM port selected.' -ForegroundColor Yellow
    exit 1
}

$serialPort = New-Object System.IO.Ports.SerialPort $selectedPort.ToUpper(), $BaudRate, ([System.IO.Ports.Parity]::None), 8, ([System.IO.Ports.StopBits]::One)
$serialPort.ReadTimeout = 1000
$serialPort.NewLine = "`n"

$lastValidPressure = $DefaultPressureHpa

try {
    $serialPort.Open()
    Write-Host ("Connected to {0} at {1} baud." -f $serialPort.PortName, $BaudRate) -ForegroundColor Cyan
    Write-Host 'Reading ESP32 JSON and forwarding it to the dashboard API...' -ForegroundColor Cyan

    while ($true) {
        try {
            $line = $serialPort.ReadLine().Trim()
            if ([string]::IsNullOrWhiteSpace($line)) {
                continue
            }

            Write-Host "[Serial] $line"

            if (-not $line.StartsWith('{')) {
                continue
            }

            $jsonData = $line | ConvertFrom-Json
            Send-HardwareReading -JsonData $jsonData
            if ($null -ne $jsonData.pressure -and $jsonData.pressure -ne '') {
                $lastValidPressure = [double]$jsonData.pressure
            }

            $payload = Get-NormalizedPayload -JsonData $jsonData -FallbackPressure $lastValidPressure
            Send-Payload -Payload $payload
        } catch [System.TimeoutException] {
            continue
        } catch {
            Write-Host ("[Bridge] Error: {0}" -f $_.Exception.Message) -ForegroundColor Yellow
        }
    }
} finally {
    if ($serialPort.IsOpen) {
        $serialPort.Close()
    }
}
