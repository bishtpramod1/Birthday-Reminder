# ==========================================
# Birthday Reminder - Telegram
# ==========================================

$CsvPath = Join-Path $PSScriptRoot "birthday.csv"

$TelegramBotToken = $env:TELEGRAM_BOT_TOKEN
$TelegramChatId   = $env:TELEGRAM_CHAT_ID

$Today = Get-Date

Write-Host "Checking birthdays for $($Today.ToString('dd/MM/yyyy'))..."

if ([string]::IsNullOrWhiteSpacemBotToken)) {
    throw "TELEGRAM_BOT_TOKEN is not configured."
}

if (:IsNullOrWhiteSpace($TelegramChatId)) {
    throw "TELEGRAM_CHAT_ID is not configured."
}

$Birthdays = Import-Csv $CsvPath

$TodaysBirthdays = foreach ($Person in $Birthdays) {

    try {

        $DobValue = $null

        if ($Person.PSObject.Properties["Date of Birth"]) {
            $DobValue = $Person.'Date of Birth'
        }
        elseif ($Person.PSObject.Properties["DOB"]) {
            $DobValue = $Person.DOB
        }
        elseif ($Person.PSObject.Properties["DateOfBirth"]) {
            $DobValue = $Person.DateOfBirth
        }

        if (:IsNullOrWhiteSpace($DobValue)) {
            Write-Warning "DOB missing for $($Person.Name)"
            continue
        }

        $DOB = :Parse($DobValue)

        if ($DOB.Day -eq $Today.Day -and $DOB.Month -eq $Today.Month) {
            $Person
        }
    }
    catch {
        Write-Warning "Invalid DOB: $DobValue for $($Person.Name)"
    }
}

if ($TodaysBirthdays) {

    $BirthdayLines = $TodaysBirthdays | ForEach-Object {
        "🎂 $($_.Name)"
    }

    $Message = @"
🎉 Birthday Reminder 🎉

Aaj birthday hai:

$($BirthdayLines -join "`n")

🥳 Please wish them a Happy Birthday!
"@

    $TelegramUrl = "https://api.telegram.org/bot$TelegramBotToken/sendMessage"

    $Body = @{
        chat_id = $TelegramChatId
        text    = $Message
    }

    Invoke-RestMethod `
        -Uri $TelegramUrl `
        -Method Post `
        -Body $Body

    Write-Host "Telegram birthday message sent successfully."
}
else {
    Write-Host "Aaj kisi ka birthday nahi hai."
}