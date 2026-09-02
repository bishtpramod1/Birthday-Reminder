# ==========================================
# Birthday Reminder - Telegram
# ==========================================

$CsvPath = Join-Path $PSScriptRoot "birthday.csv"

# Telegram configuration
$TelegramBotToken = $env:TELEGRAM_BOT_TOKEN
$TelegramChatId   = $env:TELEGRAM_CHAT_ID

# Today's date
$Today = Get-Date

Write-Host "Checking birthdays for $($Today.ToString('dd/MM/yyyy'))..."

# Validate secrets
if ([string]::IsNullOrWhiteSpace($TelegramBotToken)) {
    throw "TELEGRAM_BOT_TOKEN is not configured."
}

if ([string]::IsNullOrWhiteSpace($TelegramChatId)) {
    throw "TELEGRAM_CHAT_ID is not configured."
}

# Read CSV
$Birthdays = Import-Csv $CsvPath

# Find today's birthdays
$TodaysBirthdays = foreach ($Person in $Birthdays) {

    try {
        $DOB = [datetime]::ParseExact(
            $Person.'Date of Birth',
            @("d/M/yyyy", "dd/MM/yyyy"),
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::None
        )

        if ($DOB.Day -eq $Today.Day -and $DOB.Month -eq $Today.Month) {
            $Person
        }
    }
    catch {
        Write-Warning "Invalid DOB: $($Person.'Date of Birth') for $($Person.Name)"
    }
}

# ==========================================
# Send Telegram message
# ==========================================

if ($TodaysBirthdays) {

    $BirthdayLines = $TodaysBirthdays | ForEach-Object {
        "🎂 $($_.Name) - $($_.'Date of Birth')"
    }

    $Message = @"
🎉🎂 Birthday Reminder 🎂🎉

Aaj birthday hai:

$($BirthdayLines -join "`n")

🥳 Please wish them a Happy Birthday!

🤖 Birthday Reminder System
"@

    $TelegramUrl = "https://api.telegram.org/bot$TelegramBotToken/sendMessage"

    $Body = @{
        chat_id    = $TelegramChatId
        text       = $Message
    }

    try {
        Invoke-RestMethod `
            -Uri $TelegramUrl `
            -Method Post `
            -Body $Body

        Write-Host "Telegram birthday message sent successfully."
    }
    catch {
        Write-Error "Failed to send Telegram message."
        Write-Error $_
        exit 1
    }
}
else {
    Write-Host "Aaj kisi ka birthday nahi hai."
}