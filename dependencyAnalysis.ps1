Write-Output 'Starting analysis'

$time = Get-Date -format "yyyy-MM-dd_HH-mm-ss"
$out = $time + '_dependency-list.txt'

# delete old analysis file if exists
if (Test-Path $out) {
  Remove-Item $out
  Write-Output 'Removed old file'
}

$dependencies = "`"References`": ["
$namespaces_hashset = New-Object System.Collections.Generic.HashSet[string]

# go through all scripts and analyse namespace dependencies
Get-ChildItem ..\..\Assets -Recurse -Filter *.cs | where{$_.PSParentPath -like '*Script*'} |
  Foreach-Object {
    $content = Get-Content $_.FullName

    # (?-i)^ to make it case sensitive
    $namespace = $content | Where-Object {$_ -match '(?-i)^namespace *'}

    # if the string is empty, use global
    if (-Not $namespace) { $namespace = "Global" }

    $content | Where-Object {$_ -match '(?-i)^using *(?<!;\s*)'} |
    Foreach-Object {
        # TODO make excluded namespaces into an argument list
        #if (-Not $_.Contains("Unity") -and -Not $_.Contains("System")) {
            # curly braces have to be doubled
            $a = $namespace.replace("namespace ", '').replace(' {', '').Trim()
            $b = $_.replace("using ", '').replace(";", '').Trim()
            $dependencies += ("{`"From`": `"$($a)`", `"To`": `"$($b)`"},")
            # add both to existing namespaces. Using "| Out-Null" to not print the output to std
            $namespaces_hashset.Add($a) | Out-Null
            $namespaces_hashset.Add($b) | Out-Null
    }
  }

$dependencies += "]"


# write to json

Add-Content $out "{"

Add-Content $out "`"Projects`": ["

$namespaces_hashset | Foreach-Object {
    "{`"ID`":`"$($_)`", `"Name`":`"$($_)`"}, " | Add-Content $out
}
Add-Content $out "], "

Add-Content $out "`"Packages`": [],"

Add-Content $out $dependencies

Add-Content $out "}"


Write-Output "Saved to: $out"