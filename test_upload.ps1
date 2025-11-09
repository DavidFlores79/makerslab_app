# Test upload endpoint
$imagePath = "C:\Windows\System32\@WLOGO_48x48.png"

# Read file as bytes
$fileBytes = [System.IO.File]::ReadAllBytes($imagePath)
Write-Host "File size: $($fileBytes.Length) bytes"

# Create proper multipart form data
$boundary = [System.Guid]::NewGuid().ToString()
$LF = "`r`n"

$bodyLines = ( 
    "--$boundary",
    "Content-Disposition: form-data; name=`"file0`"; filename=`"test.png`"",
    "Content-Type: image/png$LF",
    $LF
)

$bodyString = $bodyLines -join $LF
$bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyString)

# Combine: header + file bytes + footer
$footerBytes = [System.Text.Encoding]::UTF8.GetBytes("$LF--$boundary--$LF")
$requestBytes = $bodyBytes + $fileBytes + $footerBytes

Write-Host "Total request size: $($requestBytes.Length) bytes"

# Send request
try {
    $response = Invoke-WebRequest `
        -Uri "http://192.168.100.45:3001/api/upload/cloud/chat" `
        -Method POST `
        -ContentType "multipart/form-data; boundary=$boundary" `
        -Body $requestBytes `
        -Verbose

    Write-Host "Success!"
    Write-Host "Status: $($response.StatusCode)"
    Write-Host "Response: $($response.Content)"
}
catch {
    Write-Host "Error: $_"
    Write-Host "Response: $($_.Exception.Response)"
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $responseBody = $reader.ReadToEnd()
        Write-Host "Response body: $responseBody"
    }
}
