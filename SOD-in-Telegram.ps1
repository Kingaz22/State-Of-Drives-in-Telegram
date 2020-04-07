#специальный токен, присваиваемый боту при создании
$token = ""
#айдишник контакта, канала или группы 
$chat_id = ""
#Значение состояния накопителя ниже которого отправлять сообщение
$HL = 90

Try 
{
    $HdInfo = Get-WmiObject -Query "select * from hdsentinel" -Namespace "root\wmi" -ErrorAction Stop
    $Output = @()
    foreach($Hd in $HdInfo)
    {
        $SmartPsObject = @()
        foreach($Attribute in ($Hd.SMART -split ([char]13)))
        {
            if($Attribute -ne '')
            {
                $AttArr = $Attribute -split ','
                $SmartPsObject += (New-Object PSObject -Property @{ Number = $AttArr[0]
                                                                    Attribute = $AttArr[1]
                                                                    Threshold = $AttArr[2]
                                                                    Value = $AttArr[3]
                                                                    Worst = $AttArr[4]
                                                                    Data = $AttArr[5]})
            }
        }
        $Properties = Get-Member -InputObject $Hd -Name "__*" | Select -ExpandProperty Name
        $Hd | Add-Member -MemberType NoteProperty -Name 'SMARTObject' -Value $SmartPsObject
        $Output += $Hd | Select * -ExcludeProperty $Properties
    }
    $Output = $Output | Select PSComputerName, Interface, ModelID, Health, Report | Where Health -le $HL
} 
Catch
{
    Write-Host "Ошибка получения данных hdsentinel"
    Write-Host $error[0].Exception
} 


if($Output)
{
    Try 
    {
            foreach($va in $Output)
            {
                $PSComputerName = $va.PSComputerName
                $Interface = $va.Interface
                $Health = $va.Health
                $ModelID = $va.ModelID
                $Report = $va.Report
                $text = "<b>Имя компьютера:</b> $PSComputerName
<b>Интерфейс:</b> $Interface
<b>Здоровье накопителя:</b> $Health
<b>Модель/ID:</b> $ModelID
<b>Отчёт о состоянии накопителя:</b> <i>$Report</i>"
        
                $payload = @{
                    "chat_id" = $chat_id;
                    "text" = $text;
                    "parse_mode" = 'html';
                    }
                Invoke-WebRequest `
                    -Uri ("https://api.telegram.org/bot{0}/sendMessage" -f $token) `
                    -Method Post `
                    -ContentType "application/json;charset=utf-8" `
                    -Body (ConvertTo-Json -Compress -InputObject $payload)
            }
    } 
    Catch
    {
        Write-Host "Ошибка отправки сообщения в Telegram"
        Write-Host $error[0].Exception
    }
    
}

