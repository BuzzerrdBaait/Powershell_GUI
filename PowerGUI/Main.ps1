ADD-TYPE -AssemblyName System.Windows.Forms
# Function to parse color setting
function GetColorFromSetting($colorSetting) {
    try {
        return [System.Drawing.Color]::FromArgb([System.Convert]::ToInt32($colorSetting, 16))
    }
    catch {
        $namedColor = [System.Drawing.Color]::FromName($colorSetting)
        if ($namedColor.Name -ne '0') {
            return $namedColor
        }
        else {
            return [System.Drawing.Color]::Gray
        }
    }
}

# Function to reload the JSON settings from the file
function ReloadSettings() {
    $Settings = Get-Content -Path "$PSScriptRoot\settings.json" | ConvertFrom-Json
    $BackgroundColor = GetColorFromSetting $Settings.backgroundColor
    $ButtonColor = GetColorFromSetting $Settings.buttonColor
    $FontSize = [float]::Parse($Settings.fontSize)
    $FontName = $Settings.font
    $TextColor = GetColorFromSetting $Settings.textColor

    # Update the form and buttons with the new settings
    $Form.Text = $Settings.title
    $Form.BackColor = $BackgroundColor
    $jsonEditorButton.BackColor = $ButtonColor
    $jsonEditorButton.ForeColor = $TextColor
    $jsonEditorButton.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    foreach ($Button in $Panel.Controls) {
        $Button.BackColor = $ButtonColor
        $Button.ForeColor = $TextColor
        $Button.Font = New-Object System.Drawing.Font($FontName, $FontSize)
    }
}

# Read the JSON settings from a file
$Settings = Get-Content -Path "$PSScriptRoot\settings.json" | ConvertFrom-Json
$Title = $Settings.title
$BackgroundColor = GetColorFromSetting $Settings.backgroundColor
$ButtonColor = GetColorFromSetting $Settings.buttonColor
$FontSize = [float]::Parse($Settings.fontSize)
$FontName = $Settings.font
$TextColor = GetColorFromSetting $Settings.textColor

# Create the main form
$Form = New-Object System.Windows.Forms.Form
$Form.Text = $Title
$Form.BackColor = $BackgroundColor

# Create a panel to hold the buttons
$Panel = New-Object System.Windows.Forms.FlowLayoutPanel
$Panel.Dock = 'Fill'

# Get the list of files in the specified folder
$FolderPath = $PSScriptRoot

# Check if the folder exists
if (Test-Path -Path $FolderPath) {
    # Get the files with the specified extensions
    $Files = Get-ChildItem -Path $FolderPath | Where-Object { $_.Extension -in ".ps1", ".bat", ".exe", ".ps2" }
}

# Define the desired number of columns and rows
$ButtonCount = $Files.Count
$DesiredColumns = $ButtonCount
$DesiredRows = [math]::Ceiling($ButtonCount / $DesiredColumns)

# Calculate the button width and height
$ButtonWidth = $FontSize * 15
$ButtonHeight = $FontSize * 3

# Calculate the new form width and height based on the buttons
$NewFormWidth = ($ButtonWidth + 5) * $DesiredColumns
$NewFormHeight = $ButtonHeight * $DesiredRows

# Adjust the form's size
$Form.ClientSize = New-Object System.Drawing.Size($NewFormWidth, $NewFormHeight)

# Function to create/update the button grid
function UpdateButtonGrid() {


    #A little bit redundant here but I have to load the json everytime to fix the bug of colors changing back to original settings after changing

    #our settings.

    $Settings = Get-Content -Path "$PSScriptRoot\settings.json" | ConvertFrom-Json
    $BackgroundColor = GetColorFromSetting $Settings.backgroundColor
    $ButtonColor = GetColorFromSetting $Settings.buttonColor
    $FontSize = [float]::Parse($Settings.fontSize)
    $FontName = $Settings.font
    $TextColor = GetColorFromSetting $Settings.textColor

    # - - - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - -  - - - - - - - - - - - - - - - - - - -  - - - - - - - - - - -

    # Calculate the new form width and height based on the buttons
    $NewFormWidth = ($ButtonWidth + 5) * $DesiredColumns
    $NewFormHeight = ($ButtonHeight + 5) * $DesiredRows + $OptionsButton.Height

    # Adjust the form's size
    $Form.ClientSize = New-Object System.Drawing.Size($NewFormWidth, $NewFormHeight)
    
    

    $CurrentProgram = $MyInvocation.ScriptName
    
    # Split the program's name off of the end of the path after the backslash
    $ProgramName = $CurrentProgram.Split("\\")[-1]
    
    # Print the program's name
    Write-Host "The program's name is $ProgramName"
    
    
    foreach ($File in $Files) {
        if ($File.Name -eq $ProgramName) {
            continue  # Skip loading the file
        }      
        $Button = New-Object System.Windows.Forms.Button
        $Button.Text = $File.Name
        $Button.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
        $Button.BackColor = GetColorFromSetting $Settings.buttonColor
        $Button.ForeColor = $TextColor
        $Button.Font = New-Object System.Drawing.Font($FontName, $FontSize)

        $Button.Add_Click({
            $command = Join-Path $FolderPath $args[0].Text
            & $command
        })
        $Button.Margin = New-Object System.Windows.Forms.Padding(2)      
        $Panel.Controls.Add($Button)
        Write-Host "Button added: $($Button.Text)"
    }

    # Add the options button as the last button
    $Panel.Controls.Add($OptionsButton)
    $Panel.Controls.Add($jsonEditorButton)
    Write-Host "Button added: $($OptionsButton.Text)"
}

# Function to save the changes to the JSON file
function SaveChanges() {
    foreach ($variable in $variables) {
        if ($variable.Name -eq "Font") {
            $fontTextBox = $jsonEditorForm.Controls["$($variable.Variable)TextBox"]
            $selectedFont = $fontTextBox.Text.Split(',')[0].Trim()
            $selectedFontSize = $fontTextBox.Text.Split(',')[1].Trim()
            $jsonContent.$($variable.Variable) = $selectedFont
            $jsonContent.fontSize = $selectedFontSize
        } else {
            $textBox = $jsonEditorForm.Controls[$variable.Variable]
            $jsonContent.$($variable.Variable) = $textBox.Text
        }
    }

    # Convert the updated JSON content back to string
    $updatedJson = $jsonContent | ConvertTo-Json -Depth 4

    # Save the updated JSON content to the file
    $updatedJson | Set-Content -Path $filePath -Force

    # Display a message box indicating successful save
    [System.Windows.Forms.MessageBox]::Show("Changes saved successfully.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)

    # Reload the settings to reflect the changes
    ReloadSettings
}

# Create a button to open the JSON editor
$jsonEditorButton = New-Object System.Windows.Forms.Button
$jsonEditorButton.Text = "Settings"
$jsonEditorButton.Size = New-Object System.Drawing.Size($ButtonWidth, $ButtonHeight)
$jsonEditorButton.BackColor = $ButtonColor
$jsonEditorButton.ForeColor = $TextColor
$jsonEditorButton.Font = New-Object System.Drawing.Font($FontName, $FontSize)


$jsonEditorButton.Add_Click({
    Add-Type -AssemblyName System.Windows.Forms

    # Define the path to the JSON file
    $filePath = "$PSScriptRoot\settings.json"

    # Load the JSON content
    $jsonContent = Get-Content -Path $filePath | ConvertFrom-Json

    # Create a form
    $jsonEditorForm = New-Object System.Windows.Forms.Form
    $jsonEditorForm.Text = "JSON Editor"

    #----------------------
    
    #BACK COLOR GOES HERE FOR FUTURE REFERENCE

    #----------------------
    $jsonEditorForm.Width = 425

    $jsonEditorForm.Height = 255

    # Set the form's startup position to be fixed
    $jsonEditorForm.StartPosition = "Manual"
    $jsonEditorForm.Location = New-Object System.Drawing.Point(200, 200)

    # Create labels, option selectors, and color pickers for each variable
    $variables = @(
        @{Name = "Title"; Variable = "title"},
        @{Name = "BG Color"; Variable = "backgroundColor"},
        @{Name = "Button Color"; Variable = "buttonColor"},
        @{Name = "Font"; Variable = "font"},
        @{Name = "Text Color"; Variable = "textColor"}
    )
    $top = 20

    foreach ($variable in $variables) {
        $label = New-Object System.Windows.Forms.Label
        $label.Font = New-Object System.Drawing.Font("Arial", 12)
        $label.Text = $variable.Name
        $label.Top = $top
        $label.Left = 10
        $jsonEditorForm.Controls.Add($label)

        if ($variable.Name -eq "BG Color") {
            # Color picker for background color
            $colorButton = New-Object System.Windows.Forms.Button
            $colorButton.Text = "Select BG Color"
            $colorButton.Top = $top
            $colorButton.Left = 280
            $colorButton.Width = 120

            $colorButton.Add_Click({
                $colorDialog = New-Object System.Windows.Forms.ColorDialog
                $result = $colorDialog.ShowDialog()

                if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                    $selectedColor = $colorDialog.Color
                    $jsonContent.$($variable.Variable) = $selectedColor.Name
                    $bgColorTextBox.Text = $selectedColor.Name
                }
            })

            $jsonEditorForm.Controls.Add($colorButton)

            $bgColorTextBox = New-Object System.Windows.Forms.TextBox
            $bgColorTextBox.Name = $variable.Variable
            $bgColorTextBox.Text = $jsonContent.$($variable.Variable)
            $bgColorTextBox.Top = $top
            $bgColorTextBox.Left = 120
            $bgColorTextBox.Width = 150
            $jsonEditorForm.Controls.Add($bgColorTextBox)
        }
        elseif ($variable.Name -eq "Button Color") {
            # Color picker for button color
            $colorButton = New-Object System.Windows.Forms.Button
            $colorButton.Text = "Select Button Color"
            $colorButton.Top = $top
            $colorButton.Left = 280
            $colorButton.Width = 120

            $colorButton.Add_Click({
                $colorDialog = New-Object System.Windows.Forms.ColorDialog
                $result = $colorDialog.ShowDialog()

                if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                    $selectedColor = $colorDialog.Color
                    $jsonContent.$($variable.Variable) = $selectedColor.Name
                    $buttonColorTextBox.Text = $selectedColor.Name
                }
            })

            $jsonEditorForm.Controls.Add($colorButton)

            $buttonColorTextBox = New-Object System.Windows.Forms.TextBox
            $buttonColorTextBox.Name = $variable.Variable
            $buttonColorTextBox.Text = $jsonContent.$($variable.Variable)
            $buttonColorTextBox.Top = $top
            $buttonColorTextBox.Left = 120
            $buttonColorTextBox.Width = 150
            $jsonEditorForm.Controls.Add($buttonColorTextBox)
        }
        elseif ($variable.Name -eq "Text Color") {
            # Color picker for text color
            $colorButton = New-Object System.Windows.Forms.Button
            $colorButton.Text = "Select Text Color"
            $colorButton.Top = $top
            $colorButton.Left = 280
            $colorButton.Width = 120

            $colorButton.Add_Click({
                $colorDialog = New-Object System.Windows.Forms.ColorDialog
                $result = $colorDialog.ShowDialog()

                if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                    $selectedColor = $colorDialog.Color
                    $jsonContent.$($variable.Variable) = $selectedColor.Name
                    $textColorTextBox.Text = $selectedColor.Name
                }
            })

            $jsonEditorForm.Controls.Add($colorButton)

            $textColorTextBox = New-Object System.Windows.Forms.TextBox
            $textColorTextBox.Name = $variable.Variable
            $textColorTextBox.Text = $jsonContent.$($variable.Variable)
            $textColorTextBox.Top = $top
            $textColorTextBox.Left = 120
            $textColorTextBox.Width = 150
            $jsonEditorForm.Controls.Add($textColorTextBox)
        }
        elseif ($variable.Name -eq "Font") {
            # Font selector
            $fontButton = New-Object System.Windows.Forms.Button
            $fontButton.Name = $variable.Variable
            $fontButton.Text = "Select Font"
            $fontButton.Top = $top
            $fontButton.Left = 280
            $fontButton.Width = 120

            $fontButton.Add_Click({
                $fontDialog = New-Object System.Windows.Forms.FontDialog
                $result = $fontDialog.ShowDialog()

                if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
                    $selectedFont = $fontDialog.Font.Name
                    $selectedFontSize = $fontDialog.Font.Size
                    $selectedFontString = "$selectedFont, $selectedFontSize"
                    $fontTextBox.Text = $selectedFontString
                }
            })

            $jsonEditorForm.Controls.Add($fontButton)

            $fontTextBox = New-Object System.Windows.Forms.TextBox
            $fontTextBox.Name = "$($variable.Variable)TextBox"
            $fontTextBox.Top = $top
            $fontTextBox.Left = 120
            $fontTextBox.Width = 150
            $fontTextBox.Text = "$($jsonContent.$($variable.Variable)), $($jsonContent.fontSize)"
            $jsonEditorForm.Controls.Add($fontTextBox)
        }
        else {
            $textBox = New-Object System.Windows.Forms.TextBox
            $textBox.Name = $variable.Variable
            $textBox.Text = $jsonContent.$($variable.Variable)
            $textBox.Top = $top
            $textBox.Left = 120
            $textBox.Width = 200
            $jsonEditorForm.Controls.Add($textBox)
        }

        $top += 30
    }

        #create a slider label
    $slabel = New-Object System.Windows.Forms.Label
    $slabel.Width = 100
    $slabel.Height=45
    $slabel.Font = New-Object System.Drawing.Font("Arial", 12)
    $slabel.Text = "Width x Height"
    $slabel.Top = $top
    $slabel.Left = 10


        #Create a slider
    $Slider = New-Object System.Windows.Forms.TrackBar

    $Slider.Minimum = 1
    $Slider.Maximum = $ButtonCount
    $Slider.SmallChange = 1
    $Slider.LargeChange = 2
    $Slider.Value = $DesiredColumns
    $Slider.AutoSize = $true
    $slider.top = $top
    $slider.left =120

    # Add a value changed event handler for the slider
    $Slider.Add_ValueChanged({
    $DesiredColumns = $Slider.Value
    $DesiredRows = [math]::Ceiling($ButtonCount / $DesiredColumns)
    #ReloadSettings
    $panel.Controls.Clear()
    UpdateButtonGrid
    })


    # Create a button to save changes
    $saveButton = New-Object System.Windows.Forms.Button
    $saveButton.Text = "Save Changes"
    $saveButton.Width = 100
    $saveButton.Top = $top
    $saveButton.Left = 280
    $saveButton.Add_Click({
        SaveChanges
    })

    $jsonEditorForm.Controls.add($slabel)

    $jsonEditorForm.Controls.add($slider)

    $jsonEditorForm.Controls.Add($saveButton)

    # Show the form
    [void]$jsonEditorForm.ShowDialog()
})

# Call the UpdateButtonGrid function initially to populate the buttons
UpdateButtonGrid

$Form.Controls.Add($Panel)
$Panel.Controls.Add($jsonEditorButton)
$Form.ShowDialog()


#whever we use the slider wheel, our buttons change back to our original color. The variable must not have changed or something.