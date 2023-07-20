#_______________________________________________________________________________________________________________________
#____________________________ R E T R I E V E   -|-   D A T A _________ A N D   -|-   C L E A N ________________________
#_______________________________________________________________________________________________________________________

  $getcsv = Get-ChildItem -Path $PSScriptRoot | Where-Object {$_.Extension -eq '.csv'}


    #----------------------------------------------------------------------------------------------------------------------------


# Update the GetVariablePath function to return an array of paths
function Get-VariablePath {
    param (
        $new,
        [string]$Path
    )

    $Path += "\$new"

    $object = [PSCustomObject]@{
        Path = $Path 
    }
    return $object
}



function Process-CSVData {
    param (
        [Parameter(Mandatory = $true)]
        [System.Object[]]$CSVData
    )

    $output = @()

    foreach ($row in $CSVData) {
        $combinedValue = ($row.Column1 -replace '^.*=') + '~' + ($row.Column2 -replace '^.*=')
        $output += $combinedValue
    }

    return $output

    }



function Calculate-RecursiveSum {
    param (
        [Parameter(Mandatory = $true)]
        [System.Collections.ArrayList]$List,

        [Parameter(Mandatory = $true)]
        [int]$Index = 0,

        [Parameter(Mandatory = $true)]
        [int]$PreviousSum = 0
    )

    $results = @()
    $appended= @()

    if ($Index -ge $List.Count) {
        write-host "index > list count"
        #write-host $results
        return $results
    }

    $currentValue = [int]$List[$Index]
    $currentSum = $currentValue + $PreviousSum

    $results += $currentSum

    $results += Calculate-RecursiveSum -List $List -Index ($Index + 1) -PreviousSum $currentSum

    return $results
}


function get-data {
    param($path_list)

    $QandAsFinal = @()
    $QandAs = @()
    $SplitIndexFinal = @()
    $SplitIndex = @()
    $count = 0

    for ($i = 0; $i -lt $path_list.Count; $i++){
        $csvdata = Import-Csv -Path $path_list[$i]
        foreach ($row in $csvdata){
            $QandAs += $row.Questions
            $QandAs += $row.Answers
        }
        $count = $QandAs.Count
        $QandAsFinal += $QandAs
        $SplitIndex += $count
        $count = 0
        $QandAs = @()
    }
    return $QandAsFinal, $SplitIndex
}

$file_list = Get-ChildItem -Path $PSScriptRoot | Where-Object { $_.Extension -eq '.csv' }
$path_list = @()

foreach ($file in $file_list){
    try{
        $getvariable = Get-VariablePath -new $file -Path $PSScriptRoot
        $path_list += $getvariable.Path
    }
    catch{
        write-host "end of list or no files found"
    }
}


$book = get-data -path_list $path_list
$splits = $book[1]
$QA = $book[0]
$bookmarks = Calculate-RecursiveSum -List $splits -Index 0 -PreviousSum 0


function GetIndexRange {
    $getcsv = Get-ChildItem -Path $PSScriptRoot | Where-Object {$_.Extension -eq '.csv'}
    
    $currentIndex = 0
    $minIndex = [int]::MaxValue
    $maxIndex = [int]::MinValue
    
    foreach ($file in $getcsv) {
        $filename = $file.Name.Replace('.csv', '')
    
        if ($currentIndex -lt $minIndex) {
            $minIndex = $currentIndex
        }
        
        if ($currentIndex -gt $maxIndex) {
            $maxIndex = $currentIndex
        }
        
        $currentIndex++
    }
    
    return @($minIndex, $maxIndex)
}




function Get-Names {
    param($path_list)
    $names = @()
    foreach ($path in $path_list) {
        $fileName = Split-Path -Leaf $path
        $readable_name = $fileName.Replace(".csv","")
        Write-Host "ATTACHING READABLE NAME ", $readable_name
        $names += $readable_name
    }
    return $names
}

$names=Get-Names $path_list



function FindCurrentAndNextPage {
    param(
        [int]$current,
        [int[]]$list,
        [int]$index = 0
    )

    if ($index -ge $list.Count) {
        # Base case: If we reach the end of the list, return the last chapter
        return $list[-1], $null
    }

    $chapterNumber = $list[$index]

    if ($current -lt $chapterNumber) {
        # We found the current chapter and the next chapter
        return $list[$index - 1], $chapterNumber
    }

    # Recursive call with the next index in the list
    return FindCurrentAndNextPage -current $current -list $list -index ($index + 1)
}

function Get-EvenAndOddIndexes {
    param (
        [object[]]$inputArray
    )


    $odds = @()

    foreach ($index in 0..($inputArray.Count - 1)) {

        if ($index % 2 -eq 1) {
            try {

                $odds += [int]$inputArray[$index]
            }
            catch {

                $odds += $inputArray[$index]
            }
        }
    }

 
    $even = @()
    for ($i = 0; $i -lt $inputArray.Count; $i += 2) {
        try {

            $even += [int]$inputArray[$i]
        }
        catch {
            $even += $inputArray[$i]
        }
    }

    return @{
        "Evens" = $even
        "Odds" = $odds
    }
}


function Get-ZippedTuple {
    param(
        [Parameter(Mandatory = $true)]
        [array]$list1,

        [Parameter(Mandatory = $true)]
        [array]$list2
    )

    # Ensure both lists have the same number of elements
    if ($list1.Count -ne $list2.Count) {
        Write-Error "Both lists must have the same number of elements."
        return
    }

    # Initialize an empty array to store the tuples (lists with two items)
    $zippedTuple = @()

    # Calculate the number of elements in the lists
    $count = $list1.Count

    # Zip the two lists together with the second list shifted back one position
    for ($i = 0; $i -lt $count; $i++) {
        $tuple = @($list1[$i], $list2[($i + $count - 1) % $count])
        $zippedTuple += $tuple
    }

    return $zippedTuple
}


function Get-PageName {
    param (
        [int]$current,
        [int[]]$page_indexes,
        [string[]]$page_names
    )

    $currentIndex = 0
    $nextIndex = 0

    for ($i = 0; $i -lt $page_indexes.Count; $i++) {
        $currentIndex = $page_indexes[$i]

        if ($i -eq $page_indexes.Count - 1) {
            $nextIndex = $page_indexes[0]
        } else {
            $nextIndex = $page_indexes[$i + 1]
        }

        if ($current -ge $currentIndex -and $current -lt $nextIndex) {
            Write-Host $page_names[$i]
            return $page_names[$i]
        }
    }

    # If the current index is greater than the last index, return the first page name
    Write-Host $page_names[0]
    return $page_names[0]
}
#_____________________________________________________________________________________________________________________________________________

#------------------------------------D A T A  ------------L O G I C------------------ D A T A------------------- L O G I C-------------------

#____________________________________________________________________________________________________________________________________________


$i=1

$indexRange = GetIndexRange
$minIndex = $indexRange[0]
$numFiles = $indexRange[1]

$index = 2  

$filePath = $path_list[0]

$csvData = Import-Csv -Path $filePath

#strings
$fileName        = Split-Path -Leaf $filePath
$variable_string = $QA[$current]

#Integers
$total           = $QA.count-1
$global:current  = 0

$global:x = -1

write-host $fileName,"<~~~file name"

$readable_name=$fileName.Replace(".csv","")
write-host $readable_name,"<-----readable name?"
write-host $QA
write-host $book[0]
# Create a list
$list = @()


write-host $path_list,"path list"


$zippedResult = Get-ZippedTuple -list1 $names -list2 $bookmarks

$splitzipped= Get-EvenAndOddIndexes $zippedResult

$page_indexes= $splitzipped.odds
$page_names= $splitzipped.Evens



$current_deck_name= Get-PageName $current $page_indexes $page_names


#_____________________________________________________________________________________________________________________________________________

#------------------------------------G U I ------------G U I------------------ G U I------------------- G U I--------------------- G U I -----#

#_____________________________________________________________________________________________________________________________________________

Add-Type -AssemblyName System.Windows.Forms

#--------------------L O A D  -|-  CSV------------------------------------------------------------------------------------------------------#

$getcsv=Get-ChildItem -Path $PSScriptRoot

#write-host $getcsv

#-------------------------------------------------------------------------------------------------------------------------------------------#
#------------------------M A I N  -|-  F O R M----------------------------------------------------------------------------------------------#
# Create the main form
$form = New-Object System.Windows.Forms.Form                              
$form.Text = "Note Cards"
$form.Width = 650
$form.Height = 500

#--------------------------------------------------------------------------------------------------------------------------------------------#
#--------------------------------------------------------------------------------------------------------------------------------------------#
# Create the title label
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = $readable_name
$titleLabel.Font = New-Object System.Drawing.Font("Arial", 20, [System.Drawing.FontStyle]::Bold)
$titleLabel.AutoSize = $true
$titleLabel.Dock = [System.Windows.Forms.DockStyle]::Top

# Entry label
$entryLabel = New-Object System.Windows.Forms.Label
$entryLabel.AutoSize = $true
$entryLabel.Text=$QA[$current]                    # E N T R Y    L A B E L 
$entryLabel.Font="Ariel,25"
$entryLabel.ForeColor="white"

$entryLabel.BackColor="pink"
$entryLabel.Dock = [System.Windows.Forms.DockStyle]::Fill
$entryLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter

# left arrow 
$leftArrow = New-Object System.Windows.Forms.Button
$leftArrow.Text = "<"
$leftArrow.Width = 50

$leftArrow.add_click({                                       # L E F T    A R R O W
    $global:current -= 1
    if ($current -lt $minIndex) {
        $global:current = $total
    }
    $positionLabel.Text = "$current / $total"
    $entryLabel.Text=$QA[$current]
    $pages_name= Get-PageName $current $page_indexes $page_names
    $titleLabel.text= $pages_name
    write-host $current
})
$leftArrow.Dock = [System.Windows.Forms.DockStyle]::Left
                                                              
# right arrow
$rightArrow = New-Object System.Windows.Forms.Button
$rightArrow.Text = ">"
$rightArrow.Width = 50

$rightArrow.add_click({
    $global:current += 1
    if ($current -gt $total) {
        $global:current = $minIndex                      # R I G H T    A R R O W
    }
    $positionLabel.Text = "$current / $total"
    $entryLabel.Text=$QA[$current]
    $pages_name= Get-PageName $current $page_indexes $page_names
    $titleLabel.text= $pages_name
    write-host $current
})

$rightArrow.Dock = [System.Windows.Forms.DockStyle]::Right

# Entry Panel
$EntryPanel = New-Object System.Windows.Forms.TableLayoutPanel
$EntryPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$EntryPanel.Height = 400
$EntryPanel.RowCount = 1                                   # E N T R Y    P A N E L    -|-  (entry & left & right arrows)
$EntryPanel.ColumnCount = 3                                 
$EntryPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 10)))
$EntryPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 80)))
$EntryPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 10)))
$EntryPanel.Controls.Add($leftArrow, 0, 0)
$EntryPanel.Controls.Add($entryLabel, 1, 0)
$EntryPanel.Controls.Add($rightArrow, 2, 0)

# Position label
$positionLabel = New-Object System.Windows.Forms.Label      # P O S I T I O N    L A B E L
$positionLabel.Text = "$current / $total"
$positionLabel.AutoSize = $true

# Open creator button
$EditorButton = New-Object System.Windows.Forms.Button       # E D I T O R     B U T T O N
$EditorButton.Text = "Edit Notes"
$EditorButton.Width = 100

# Previous deck button
$previousDeckButton = New-Object System.Windows.Forms.Button
$previousDeckButton.Text = "Previous Deck"
$previousDeckButton.Width = 100                             # P R E V I O U S    D E C K #__
$previousDeckButton.add_click({

    $currentpage, $nextPage = FindCurrentAndNextPage -current $current -list $bookmarks
    Write-host "Start of page: $currentpage, Next Page: $nextPage"

    $index = $bookmarks.IndexOf($currentpage)
    write-host $index, "<______________________________I N D E X"

    # Decrement the index
    $global:x = $index - 1

    # If the index is less than 0, set it to the last item's value in the list
    if ($global:x -lt 0) {
        $global:x = $bookmarks.Count - 1
        write-host "x set to $global:x"
    }
    

    $global:current = $bookmarks[$global:x]

    if ($global:current -lt 0) {
        $global:current = ($total - ($total - $bookmarks[$global:x]))
    }

    $pages_name= Get-PageName $current $page_indexes $page_names
    $titleLabel.text= $pages_name

    $positionLabel.Text = "$global:current / $total"
    $entryLabel.Text = $QA[$global:current]


    

    write-host $global:current
})

# Previous card button
$previousCardButton = New-Object System.Windows.Forms.Button
$previousCardButton.Text = "Previous Card"
$previousCardButton.Width = 100
$previousCardButton.add_click({
    
    $global:current -= 2
    $remainder=($global:current)%2
    #write-host $remainder,"<--------remaineder"            # P R E V I O U S    C A R D 
    if ($remainder -eq 1){
    $global:current += 1
    }
    if ($current -lt 0) {
        $global:current = $total-1
    }

    $positionLabel.Text = "$global:current / $total"
    $entryLabel.Text=$qa[$global:current]

    $pages_name= Get-PageName $current $page_indexes $page_names
    $titleLabel.text= $pages_name

    write-host $global:current
})

# Next card button
$nextCardButton = New-Object System.Windows.Forms.Button
$nextCardButton.Text = "Next Card"
$nextCardButton.Width = 100
$nextCardButton.add_click({
    
    $global:current += 2
    $remainder=($global:current)%2
    #write-host $remainder,"<--------remaineder"             # N E X T   C A R D
    if ($remainder -eq 1){
    $global:current -= 1
    }
    write-host $global:current,"<---------curren"
    write-host $total,"<-------total"
    if ($global:current -gt $total-1) {
        $global:current = 0
    }

    $positionLabel.Text = "$global:current / $total"
    $entryLabel.Text=$qa[$global:current]

    $pages_name= Get-PageName $current $page_indexes $page_names
    $titleLabel.text= $pages_name


    #write-host $global:current
})

# Next deck button
$nextDeckButton = New-Object System.Windows.Forms.Button
$nextDeckButton.Text = "Next Deck"
$nextDeckButton.Width = 100                                   # N E X T    D E C K

$nextDeckButton.add_click({

    $currentpage, $nextPage = FindCurrentAndNextPage -current $current -list $bookmarks
    Write-host "Current Page: $currentpage, Next Page: $nextPage"

    $index = $bookmarks.IndexOf($currentpage)
    write-host $index,"<______________________________________I N D E X"
    $global:x = $index
    $global:x += 1

    write-host "next deck button pressed,--> glo "
    if ($global:x -ge $bookmarks.Count) {
        $global:x = 0

        write-host "x set to $global:x"
    }

    $global:current = $bookmarks[$global:x]

    if ($global:current -gt $total){
        write-host "current > total"

        $global:current=0
    }


    $positionLabel.Text = "$global:current / $total"
    $entryLabel.Text = $QA[$global:current]

    $pages_name= Get-PageName $current $page_indexes $page_names
    $titleLabel.text= $pages_name

    write-host $global:current
})

write-host $current_deck_name,"current deck name"

write-host $page_names
write-host $page_indexes

# Button Panel
$buttonPanel = New-Object System.Windows.Forms.TableLayoutPanel
$buttonPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$buttonPanel.Height = 25                                             # B O T T O M     P A N E L
$buttonPanel.RowCount = 1                                              
$buttonPanel.ColumnCount = 6
$buttonPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 10)))
$buttonPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$buttonPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$buttonPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$buttonPanel.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 20)))
$buttonPanel.Controls.Add($positionLabel, 0, 0)
$buttonPanel.Controls.Add($EditorButton, 1, 0)
$buttonPanel.Controls.Add($previousDeckButton, 2, 0)
$buttonPanel.Controls.Add($previousCardButton, 3, 0)
$buttonPanel.Controls.Add($nextCardButton, 4, 0)
$buttonPanel.Controls.Add($nextDeckButton, 5, 0)

# Add the controls to the form

$form.Controls.Add($EntryPanel)
$form.Controls.Add($titleLabel)
$form.Controls.Add($buttonPanel)

# Show the form
[void]$form.ShowDialog()
# SIG # Begin signature block
# MIIFmQYJKoZIhvcNAQcCoIIFijCCBYYCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUyCXhHcAsXnpAUz6OJm9YNqCV
# +IigggMwMIIDLDCCAhSgAwIBAgIQPcdV79wbGbxFBz444Y/QCTANBgkqhkiG9w0B
# AQsFADAeMRwwGgYDVQQDDBNNeVNjcmlwdFNpZ25pbmdDZXJ0MB4XDTIzMDcyMDIz
# MjkyOVoXDTI0MDcyMDIzNDkyOVowHjEcMBoGA1UEAwwTTXlTY3JpcHRTaWduaW5n
# Q2VydDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAOBy0UmCvvMCNzBH
# OXpNIn9jVLlK9jc9ITB8EWPA34PdbCW9y3Kq/XcFnnsvTzz0eZPouyQZGh+Y9t7C
# HzTbz3XLEZTDThJECzxg/k+svBYeZjvEbsgxEa3/n7r3h+6oLTsdoEzXMdyi11/m
# UzcqZhJ241G/nBQwXpyo/P3KatjgFHGXjDHBk5e7duChAW9S2uNtl0PPgQ4evrbh
# te9vG3Uq+Xnts+r9u3CtRpiSHf7rjw2G/dYXZL/AKr+MdkJQtYVjInZT+kYjV2fr
# dGlUEykRoZ9qGZMnacAU72UqhLFdKPnsuvPbMuJrUN13dcSSJTvlgCfFppw+Odts
# gtgw9nUCAwEAAaNmMGQwDgYDVR0PAQH/BAQDAgeAMBMGA1UdJQQMMAoGCCsGAQUF
# BwMDMB4GA1UdEQQXMBWCE015U2NyaXB0U2lnbmluZ0NlcnQwHQYDVR0OBBYEFNtl
# Zydoe4nj3CeCbYmfeMuGbaNQMA0GCSqGSIb3DQEBCwUAA4IBAQCDs1dkodnpHW5F
# /ccA8NcyOJ0xAxt5iR+PEQaGYGfxka5op7AtfM2EbkNefDijnDpzAP6IDNq7itcY
# MEKLpFpjG4dm3kziplcv+Q9+aVcmaqBX+TC37O47oaSBBafV8DDOkRtYCufOfnBz
# Gk7M++PblOwgfIL5iDyjoIj8Nl3gQHvHOj+052JVEyZgbZRLIy1gMo4lm9VJMlAb
# 0c9HfUOZ2ecD4nb7bg0KuebG6wfsqa30lYn9kBQ+4hD9ajpVDNBD2TcpL1kztPqf
# Vs2ggPPNbyeQrPpmkZdMWwU6+H4hqp0qwozWfbqMAGNyos9ItozHsWBTGpdvfmbK
# 7vxQIDDFMYIB0zCCAc8CAQEwMjAeMRwwGgYDVQQDDBNNeVNjcmlwdFNpZ25pbmdD
# ZXJ0AhA9x1Xv3BsZvEUHPjjhj9AJMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEM
# MQowCKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQB
# gjcCAQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBStsj97BVaVMdnm
# He+cfo6QlNihnDANBgkqhkiG9w0BAQEFAASCAQCCluEU2Igjt19PYZptqCCyc016
# u8HKEEtfYC5LYni7apGAwFVvswhJc0q4ofF19bTbY36rPBfi+3Nh0S0F5J9QncIu
# Hl0VoAmWgLvjQXZDeXKt/J+lFn77RaCzIkYb77MnIJLveHkF/sdDOP+OmmwpKYEw
# EarVldgpGrZf4pIEWDb/2QA3GtCqVPAFknROtBVqwpec2KVPC5H2aD0PihnK/WIa
# 1TLo8YwQz1Tx4MG3z0KcmmsNiBvqVT+v5KWWhMmE64yMJDSnlhrg3wPnG2RMkEW7
# 2yx/I9dGYxwOC9ZgaeDG9nMmtafVB4fMSzFx7dUU0epNM4axVSyNehmTOMn9
# SIG # End signature block
