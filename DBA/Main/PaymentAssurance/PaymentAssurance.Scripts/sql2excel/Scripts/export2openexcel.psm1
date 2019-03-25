function init-excel($processfolder)
{
    $ToolDirectory=Get-Location -PSProvider FileSystem
    $epplusdll = Join-Path -path $ToolDirectory -childPath "\inputs\lib\EPPlus\EPPlus.dll"
    [Reflection.Assembly]::LoadFile($epplusdll) | Out-Null

    $xlsFile = "$processfolder\QueryResults_$((Get-Date).ToString("yyyyMMddhhmmss")).xlsx";
    if (Test-Path $xlsFile)
    {
        Remove-Item $xlsFile
    }

    return $xlsFile
}


Function Export-XLSX {
    <#
    .SYNOPSIS
        Export data to an XLSX file

    .DESCRIPTION
        Export data to an XLSX file

    .PARAMETER InputObject
        Data to export

    .PARAMETER Path
        Path to the file to export

    .PARAMETER WorksheetName
        Name the worksheet you are importing to

    .PARAMETER Header
        Header to use. Must match order and count of your data's properties

    .PARAMETER AutoFit
        If specified, autofit everything

    .PARAMETER PivotRows
        If specified, add pivot table pivoting on these rows

    .PARAMETER PivotColumns
        If specified, add pivot table pivoting on these columns

    .PARAMETER PivotValues
        If specified, add pivot table pivoting on these values

    .PARAMETER PivotFunction
        If specified, use this summary mode for pivot values (defaults to Count mode)
	
    .PARAMETER DateTimeFormat
    	Specifies the format for dates.

    .PARAMETER ChartType
        If specified, add pivot chart of this type

    .PARAMETER Table
        If specified, add table to all cells

    .PARAMETER TableStyle
        If specified, add table style

    .PARAMETER Append
        If specified, append to existing worksheet.

        We don't check header names, but header count must match.

    .PARAMETER Force
        If file exists, overwrite it.

    .PARAMETER ClearSheet
        If worksheet with the same name exists, clear it before filling it in

    .PARAMETER RemoveSheet
        If worksheet with the same name exists, remove it and re-add it
    
    .PARAMETER RemoveDebugColumns
        it will remove the extra columns of debugging

    .PARAMETER Passthru
        If specified, we re-open the ExcelPackage and return it

    .EXAMPLE
        $Files = Get-ChildItem C:\ -File

        Export-XLSX -Path C:\Files.xlsx -InputObject $Files

        Export file listing to C:\Files.xlsx

    .EXAMPLE
        $Files = Get-ChildItem C:\ -File

		$Worksheet = 'Files'

        Export-XLSX -Path C:\temp\Files.xlsx -InputObject $Files -WorksheetName $Worksheet -ClearSheet

        Export file listing to C:\temp\Files.xlsx to the worksheet named "Files".  If it exists already, clear the sheet then import the data.

    .EXAMPLE

        1..10 | Foreach-Object {
            New-Object -typename PSObject -Property @{
                Something = "Prop$_"
                Value = Get-Random
            }
        } |
            Select-Object Something, Value |
            Export-XLSX -Path C:\Random.xlsx -Force -Header Name, Val

        # Generate data
        # Send it to Export-XLSX
        # Give it new headers
        # Overwrite C:\random.xlsx if it exists

    .EXAMPLE

        # Create XLSX
        Get-ChildItem -file | Export-XLSX -Path C:\temp\multi.xlsx

        # Add a second worksheet to the xlsx
        Get-ChildItem -file | Export-XLSX -Path C:\temp\multi.xlsx -WorksheetName "Two"

    .EXAMPLE

        # Create XLSX
        Get-ChildItem -file | Export-XLSX -Path C:\temp\multi.xlsx

        # Add a second worksheet to the xlsx
        Get-ChildItem -file | Export-XLSX -Path C:\temp\multi.xlsx -WorksheetName "Two"

        # I don't like that second worksheet. Recreate it, deleting the existing worksheet if it exists.
        Get-ChildItem -file | Select -first 1 | Export-XLSX -Path C:\temp\multi.xlsx -WorksheetName "Two" -ReplaceSheet

    .EXAMPLE

        Get-ChildItem C:\ -file |
            Export-XLSX -Path C:\temp\files.xlsx -PivotRows Extension -PivotValues Length -ChartType Pie

        # Get files
        # Create an xlsx in C:\temp\files.xlsx
        # Pivot rows on 'Extension'
        # Pivot values on 'Length
        # Add a pie chart

        # This example gives you a pie chart breaking down storage by file extension

    .EXAMPLE

	    Get-Process | Export-XLSX -Path C:\temp\process.xlsx -Worksheet process -Table -TableStyle Medium1 -AutoFit

	    # Get all processes
	    # Create an xlsx
	    # Create a table with the Medium1 style and all cells autofit on the 'process' worksheet

    .EXAMPLE

    #
    # This example illustrates appending data

        1..10 | Foreach-Object {
            New-Object -typename PSObject -Property @{
                Something = "Prop$_"
                Value = Get-Random
            }
        } |
            Select-Object Something, Value |
            Export-XLSX -Path C:\Random.xlsx -Force

        # Generate data
        # Send it to Export-XLSX
        # Overwrite C:\random.xlsx if it exists

        1..5 | Foreach-Object {
            New-Object -typename PSObject -Property @{
                Something = "Prop$_"
                Value = Get-Random
            }
        } |
            Select-Object Something, Value |
            Export-XLSX -Path C:\Random.xlsx -Append

        # Generate data
        # Send it to Export-XLSX
        # Append to C:\random.xlsx

    .NOTES
        Thanks to Doug Finke for his example
        The pivot stuff is straight from Doug:
            https://github.com/dfinke/ImportExcel

        Thanks to Philip Thompson for an expansive set of examples on working with EPPlus in PowerShell:
            https://excelpslib.codeplex.com/

    .LINK
        https://github.com/RamblingCookieMonster/PSExcel

    .FUNCTIONALITY
        Excel
    #>
    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
        [parameter( ParameterSetName='Path',
                    Position = 0,
                    Mandatory=$true )]
        [ValidateScript({
            $Parent = Split-Path $_ -Parent
            if( -not (Test-Path -Path $Parent -PathType Container) )
            {
                Throw "Specify a valid path.  Parent '$Parent' does not exist: $_"
            }
            $True
        })]
        [string]$Path,

        [parameter( ParameterSetName='Excel',
                    Position = 0,
                    Mandatory=$true )]
        [OfficeOpenXml.ExcelPackage]$Excel,

        $InputObject,

        [string[]]$Header,

	[ValidateLength(1,31)]
        [string]$WorksheetName = "Worksheet1",

        [string[]]$PivotRows,

        [string[]]$PivotColumns,

        [string[]]$PivotValues,
	
	[string]$DateTimeFormat = "d/M/yyy h:mm",
        
        [OfficeOpenXml.Table.PivotTable.DataFieldFunctions]$PivotFunction = [OfficeOpenXml.Table.PivotTable.DataFieldFunctions]::Count,

        [OfficeOpenXml.Drawing.Chart.eChartType]$ChartType,

        [switch]$Table,

        [OfficeOpenXml.Table.TableStyles]$TableStyle = [OfficeOpenXml.Table.TableStyles]"Medium2",

        [bool]$AutoFit,
        [double]$AutofitMaxWidth,
        [switch]$Append,

        [switch]$Force,

		[switch]$ClearSheet,

        [switch]$ReplaceSheet,
        [bool]$RemoveDebugColumns=$true,
        [bool]$setborder=$true,
        [switch]$Passthru,
        [string]$password=$null
    )
    begin
    {
        if ( $PSBoundParameters.ContainsKey('Path'))
        {
            if ( Test-Path $Path ) 
            {
                if($Append)
                {
                    Write-Verbose "'$Path' exists. Appending data"
                }
                elseif($Force)
                {
                    Try
                    {
                        Remove-Item -Path $Path -Force -Confirm:$False
                    }
                    Catch
                    {
                        Throw "'$Path' exists and could not be removed: $_"
                    }
                }
                else
                {
                    Write-Verbose "'$Path' exists. Use -Force to overwrite. Attempting to add sheet to existing workbook"
                }
            }

            $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
        }

        Write-Verbose "Export-XLSX '$($PSCmdlet.ParameterSetName)' PSBoundParameters = $($PSBoundParameters | Out-String)"

        $bound = $PSBoundParameters.keys -contains "InputObject"
        if((-not $bound) -or ($InputObject -eq $null))
        {
            [System.Collections.ArrayList]$AllData = @()
        }
    }
    process
    {
        #We write data by row, so need everything countable, not going to stream...
        if($bound)
        {
            $AllData = $InputObject
        }
        Else
        {
            foreach($Object in $InputObject)
            {
                [void]$AllData.add($Object)
            }
        }
    }
    end
    {
        #Deal with headers
            $ExistingHeader = @(

                # indexes might be an issue if we get array of strings, so select first
                ($AllData | Select -first 1).PSObject.Properties | Select -ExpandProperty Name
            )

            $Columns = $ExistingHeader.count

            if($Header)
            {
                if($Header.count -ne $ExistingHeader.count)
                {
                    Throw "Found '$columns' columns, provided $($header.count) headers.  You must provide a header for every column."
                }
            }
            else
            {
                $Header = $ExistingHeader
            }

            if($RemoveDebugColumns -eq $true)
            {
                $excluded="RowError","RowState","Table","ItemArray","HasErrors"
                $Header=$Header | Where-Object{$_ -notin $excluded}
            }

        #initialize stuff
            $RowIndex = 2
            Try
            {
                if( $PSBoundParameters.ContainsKey('Path'))
                {
                    if((test-path $Path) -and $password -ne $null -and $password -ne "")
                    {
                        $Excel = New-Object OfficeOpenXml.ExcelPackage($Path,$password) -ErrorAction Stop
                    }
                    else
                    {
                        $Excel = New-Object OfficeOpenXml.ExcelPackage($Path) -ErrorAction Stop
                    }
                }
                else
                {
                    $Path = $Excel.File.FullName
                }

                $Workbook = $Excel.Workbook
                if($ReplaceSheet)
                {
                    Try
                    {
                        Write-Verbose "Attempting to delete worksheet $WorksheetName"
                        $Workbook.Worksheets.Delete($WorksheetName)
                    }
                    Catch
                    {
                        if($_.Exception -notmatch 'Could not find worksheet to delete')
                        {
                            Write-Error "Error removing worksheet $WorksheetName"
                            Throw $_
                        }
                    }
                }

                # They asked for append but we don't have a worksheet.  Drop the append switch.
                if($Excel.Workbook.WorkSheets.count -eq 0 )
                {
                    $Append = $False
                }

                #If we have an excel or valid path, try to append or clearsheet as needed
                if (($Append -or $ClearSheet) -and ($PSBoundParameters.ContainsKey('Excel') -or (Test-Path $Path)) )
                {
                    $WorkSheet=$Excel.Workbook.Worksheets | Where-Object {$_.Name -like $WorkSheetName}
                    if($ClearSheet)
                    {
                        $WorkSheet.Cells[$WorkSheet.Dimension.Start.Row, $WorkSheet.Dimension.Start.Column, $WorkSheet.Dimension.End.Row, $WorkSheet.Dimension.End.Column].Clear()
                    }
                    if($Append)
                    {
                        $RealHeaderCount = $WorkSheet.Dimension.Columns
                        if($Header.count -ne $RealHeaderCount)
                        {
                            $Excel.Dispose()
                            Throw "Found $RealHeaderCount existing headers, provided data has $($Header.count)."
                        }
                        $RowIndex = 1 + $Worksheet.Dimension.Rows
                    }
                }
                else
                {
                    $WorkSheet = $Workbook.Worksheets.Add($WorkSheetName)
                }
            }
            Catch
            {
                Throw "Failed to initialize Excel, Workbook, or Worksheet. Try -ClearSheet switch if worksheet already exists:`n`n_"
            }

        #Set those headers if we aren't appending
            if(-not $Append)
            {
                for ($ColumnIndex = 1; $ColumnIndex -le $Header.count; $ColumnIndex++)
                {
                    $WorkSheet.SetValue(1, $ColumnIndex, $Header[$ColumnIndex - 1])
                }
            }

        #Write the data...
            foreach($RowData in $AllData)
            {
                Write-Verbose "Working on object:`n$($RowData | Out-String)"
                for ($ColumnIndex = 1; $ColumnIndex -le $Header.count; $ColumnIndex++)
                {
                    $Object = @($RowData.PSObject.Properties)[$ColumnIndex - 1]
                    $Value = $Object.Value
                    $WorkSheet.SetValue($RowIndex, $ColumnIndex, $Value)

                    Try
                    {
                        #Nulls will error, catch them
                        $ThisType = $Null
                        $ThisType = $Value.GetType().FullName
                    }
                    Catch
                    {
                        Write-Verbose "Applying no style to null in row $RowIndex, column $ColumnIndex"
                    }

                    #Idea from Philip Thompson, thank you Philip!
                    $StyleName = $Null
                    $ExistingStyles = @($WorkBook.Styles.NamedStyles | Select -ExpandProperty Name)
                    Switch -regex ($ThisType)
                    {
                        "double|decimal|single"
                        {
                            $StyleName = 'decimals'
                            $StyleFormat = "0.00"
                        }
                        "int\d\d$"
                        {
                            $StyleName = 'ints'
                            $StyleFormat = "0"
                        }
                        "datetime"
                        {
                            $StyleName = "dates"
                            $StyleFormat = $DateTimeFormat
                        }
                        "TimeSpan"
                        {
                            #Open to other ways to handle this
                            $WorkSheet.SetValue($RowIndex, $ColumnIndex, "$Value")
                        }
                        default
                        {
                            #No default yet...
                        }
                    }

                    if($StyleName)
                    {
                        if($ExistingStyles -notcontains $StyleName)
                        {
                            $StyleSheet = $WorkBook.Styles.CreateNamedStyle($StyleName)
                            $StyleSheet.Style.Numberformat.Format = $StyleFormat
                        }

                        $WorkSheet.Cells.Item($RowIndex, $ColumnIndex).Stylename = $StyleName
                    }

                }
                Write-Verbose "Wrote row $RowIndex"
                $RowIndex++
            }

            # Any pivot params specified?  add a pivot!
            if($PSBoundParameters.Keys -match 'Pivot')
            {
                $Params = @{}
                if($PivotRows)     {$Params.Add('PivotRows',$PivotRows)}
                if($PivotColumns)  {$Params.Add('PivotColumns',$PivotColumns)}
                if($PivotValues)   {$Params.Add('PivotValues',$PivotValues)}
                if($PivotFunction) {$Params.Add('PivotFunction',$PivotFunction)}
                if($ChartType)     {$Params.Add('ChartType',$ChartType)}
                $Excel = Add-PivotTable @Params -Excel $Excel -WorkSheetName $WorksheetName -Passthru -ErrorAction stop

            }

            # Create table
            elseif($Table)
            {
                $Excel = Add-Table -Excel $Excel -WorkSheetName $WorksheetName -TableStyle $TableStyle -Passthru
            }

           
           if($AllData -ne $null)
           {
               Format-Cell -WorkSheet $WorkSheet -Bold $true -Size 12 -Font 'Calibri' -BackgroundColor MediumAquamarine -Border "*" -BorderStyle Thin -Header
               Format-Cell -WorkSheet $WorkSheet -Font 'Calibri' -Border "*" -BorderStyle Thin -BorderColor DarkCyan

                if($AutoFit)
                {
                   if($AutoFitMaxWidth -gt 0)
                   {
                        Format-Cell -WorkSheet $WorkSheet -AutoFitMaxWidth $AutoFitMaxWidth -Autofit
                   }
                   else
                   {
                        Format-Cell -WorkSheet $WorkSheet -Autofit
                   } 
                }
           }

            # This is an export command. Save whether we have a path or ExcelPackage input...
            if($password -ne $null -and $password -ne "")
            {
                $Excel.SaveAs($Path,$password)
            }
            else
            {
                $Excel.SaveAs($Path)
            }

            if($Passthru)
            {
                New-Excel -Path $Path
            }
    }
}



function Format-Cell 
{
    <#
    .SYNOPSIS
        Format cells in an Excel worksheet

    .DESCRIPTION
        Format cells in an Excel worksheet

        Note:
            Each time you call this function, you need to save and re-create your Excel Object.
            If you attempt to modify the Excel object, save, modify, and save a second time, it will fail.
            See Save-Excel Passthru parameter for a workaround
        
    .PARAMETER Worksheet
        Worksheet to format cells on
    
    .PARAMETER StartRow
        The top row to format.  If not specified, we use the dimensions start row

    .PARAMETER StartColumn
        The leftmost column to format.  If not specified, we use the dimensions start column

    .PARAMETER EndRow
        The bottom row to format.  If not specified, we use the dimensions' end row

    .PARAMETER EndColumn
        The rightmost column to format.  If not specified, we use the dimensions' end column

    .PARAMETER Header
        If specified, identify and apply formatting to the header row only.

    .PARAMETER Bold
        Add or remove bold font (boolean)

    .PARAMETER Italic
        Add or remove Italic font (boolean)

    .PARAMETER Underline
        Add or remove Underline font (boolean)

    .PARAMETER Size
        Set font size

    .PARAMETER Font
        Set font name
        
    .PARAMETER Color
        Set font color

    .PARAMETER BackgroundColor
        Set background fill color

    .PARAMETER FillStyle
        Set the FillStyle, if BackgroundColor is specified.  Default is Solid

    .PARAMETER WrapText
        Add or remove WrapText property (boolean)

    .PARAMETER AutoFilter
        Set autofilter for the cells

        This currently only works for $True. It won't turn off Autofilter with $False.

    .PARAMETER AutoFit
        Apply auto fit to cells

    .PARAMETER AutoFitMinWidth
        Minimum width to set autofit with
    
    .PARAMETER AutoFitMaxWidth
        Maximum width to set autofit with

    .PARAMETER VerticalAlignment
        Set the vertical alignment

    .PARAMETER HorizontalAlignment
        Set the horizontal alignment

    .PARAMETER Border
        Set a border to the left, right, top, bottom, or all (*).

    .PARAMETER BorderStyle
        Style for the border. Defaults to Thin

    .PARAMETER BorderColor
        Color for the border. Defaults to Black

    .PARAMETER Passthru
        If specified, pass the Worksheet back

    .EXAMPLE
        #
        # Create an Excel object to work with
            $Excel = New-Excel -Path C:\Temp\Demo.xlsx
        
        #Get the worksheet, format the header as bold, size 14
            $Excel |
                Get-WorkSheet |
                Format-Cell -Header -Bold $True -Size 14
        
        #Save your changes, re-open the excel file
            $Excel = $Excel | Save-Excel -Passthru

        #Oops, too big!  Get the worksheet, format the header as size 11
            $Excel |
                Get-WorkSheet |
                Format-Cell -Header -Size 11

            $Excel | Save-Excel -Close

    .EXAMPLE
        $WorkSheet | Format-Cell -StartRow 2 -StartColumn 1 -EndColumn 1 -Italic $True -Size 10

        # Set the first column, rows 2 through the end to size 10, italic

    .EXAMPLE
          
        # Get the worksheet
        # format all the cells (default if nothing specified)
        # Set autofit between minumum of 5 and maximum of 20
        $Excel |
            Get-WorkSheet |
            Format-Cell -Autofit -AutofitMinWidth 5 -AutofitMaxWidth 20

    .NOTES
        Thanks to Doug Finke for his example:
            https://github.com/dfinke/ImportExcel/blob/master/ImportExcel.psm1

        Thanks to Philip Thompson for an expansive set of examples on working with EPPlus in PowerShell:
            https://excelpslib.codeplex.com/

    .LINK
        https://github.com/RamblingCookieMonster/PSExcel

    .FUNCTIONALITY
        Excel
    #>

    #[OutputType([OfficeOpenXml.ExcelWorksheet])]
    [cmdletbinding(DefaultParameterSetname = 'Range')]
    param(
        [parameter( Mandatory=$true,
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [OfficeOpenXml.ExcelWorksheet]$WorkSheet,

        [parameter( ParameterSetName = 'Range',
                    Mandatory=$false,
                    ValueFromPipeline=$false,
                    ValueFromPipelineByPropertyName=$false)]
        [int]$StartRow,
        
        [parameter( ParameterSetName = 'Range',
                    Mandatory=$false,
                    ValueFromPipeline=$false,
                    ValueFromPipelineByPropertyName=$false)]
        [int]$StartColumn,
        
        [parameter( ParameterSetName = 'Range',
                    Mandatory=$false,
                    ValueFromPipeline=$false,
                    ValueFromPipelineByPropertyName=$false)]
        [int]$EndRow,

        [parameter( ParameterSetName = 'Range',
                    Mandatory=$false,
                    ValueFromPipeline=$false,
                    ValueFromPipelineByPropertyName=$false)]
        [int]$EndColumn,

        [parameter( ParameterSetName = 'Header',
                    Mandatory=$true,
                    ValueFromPipeline=$false,
                    ValueFromPipelineByPropertyName=$false)]
        [Switch]$Header,

        [boolean]$Bold,
        [boolean]$Italic,
        [boolean]$Underline,
        [int]$Size,
        [string]$Font,
        
        [System.Drawing.KnownColor]$Color,
        [System.Drawing.KnownColor]$BackgroundColor,
        [OfficeOpenXml.Style.ExcelFillStyle]$FillStyle,
        [boolean]$WrapText,
        [String]$NumberFormat,

        [boolean]$AutoFilter,
        [switch]$Autofit,
        [double]$AutofitMinWidth,
        [double]$AutofitMaxWidth,

        [OfficeOpenXml.Style.ExcelVerticalAlignment]$VerticalAlignment,
        [OfficeOpenXml.Style.ExcelHorizontalAlignment]$HorizontalAlignment,

        [validateset('Left','Right','Top','Bottom','*')]
        [string[]]$Border,
        [OfficeOpenXml.Style.ExcelBorderStyle]$BorderStyle,
        [System.Drawing.KnownColor]$BorderColor,

        [switch]$Passthru
    )
    Begin
    {

        if($PSBoundParameters.ContainsKey('BorderColor'))
        {
            Try
            {
                $BorderColorConverted = [System.Drawing.Color]::FromKnownColor($BorderColor)
            }
            Catch
            {
                Throw "Failed to convert $($BorderColor) to a valid System.Drawing.Color: $_"
            }
        }

        if($PSBoundParameters.ContainsKey('Color'))
        {
            Try
            {
                $ColorConverted = [System.Drawing.Color]::FromKnownColor($Color)
            }
            Catch
            {
                Throw "Failed to convert $($Color) to a valid System.Drawing.Color: $_"
            }
        }

        if($PSBoundParameters.ContainsKey('BackgroundColor'))
        {
            Try
            {
                $BackgroundColorConverted = [System.Drawing.Color]::FromKnownColor($BackgroundColor)
                if(-not $PSBoundParameters.ContainsKey('FillStyle'))
                {
                    $FillStyle = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
                }
            }
            Catch
            {
                Throw "Failed to convert $($BackgroundColor) to a valid System.Drawing.Color: $_"
            }
        }
    }
    Process
    {
        #Get the coordinates
            $dimension = $WorkSheet.Dimension
        
            if($PSCmdlet.ParameterSetName -like 'Range')
            {
                If(-not $StartRow)
                {
                    $StartRow = $dimension.Start.Row
                }
                If(-not $StartColumn)
                {
                    $StartColumn = $dimension.Start.Column
                }
                If(-not $EndRow)
                {
                    $EndRow = $dimension.End.Row
                }
                If(-not $EndColumn)
                {
                    $EndColumn = $dimension.End.Column
                }
            }
            Elseif($PSCmdlet.ParameterSetName -like 'Header')
            {
                $StartRow = $dimension.Start.Row
                $StartColumn = $dimension.Start.Column
                $EndRow = $dimension.Start.Row
                $EndColumn = $dimension.End.Column
            }

            $Start = ConvertTo-ExcelCoordinate -Row $StartRow -Column $StartColumn
            $End = ConvertTo-ExcelCoordinate -Row $EndRow -Column $EndColumn
            $RangeCoordinates = "$Start`:$End"

			# Apply the formatting
            $CellRange = $WorkSheet.Cells[$RangeCoordinates]
            
            switch ($PSBoundParameters.Keys)
            {
                'Bold'                { $CellRange.Style.Font.Bold = $Bold  }
                'Italic'              { $CellRange.Style.Font.Italic = $Italic  }
                'Underline'           { $CellRange.Style.Font.UnderLine = $Underline}
                'Size'                { $CellRange.Style.Font.Size = $Size }
                'Font'                { $CellRange.Style.Font.Name = $Font }
                'Color'               { $CellRange.Style.Font.Color.SetColor($ColorConverted) }
                'BackgroundColor'     {
                    $CellRange.Style.Fill.PatternType = $FillStyle
                    $CellRange.Style.Fill.BackgroundColor.SetColor($BackgroundColorConverted)
                }
                'WrapText'            { 

                $CellRange.Style.WrapText = $WrapText  
                }
                'VerticalAlignment'   { $CellRange.Style.VerticalAlignment = $VerticalAlignment }
                'HorizontalAlignment' { $CellRange.Style.HorizontalAlignment = $HorizontalAlignment }
                'AutoFilter'          { $CellRange.AutoFilter = $AutoFilter }
                'Autofit'         {
                    #Probably a cleaner way to call this...
                    try
                    {
                        if($PSBoundParameters.ContainsKey('AutofitMaxWidth'))
                        {
                            $CellRange.AutoFitColumns($AutofitMinWidth, $AutofitMaxWidth)
                        }
                        elseif($PSBoundParameters.ContainsKey('AutofitMinWidth'))
                        {
                            $CellRange.AutoFitColumns($AutofitMinWidth)
                        }
                        else
                        {
                            $CellRange.AutoFitColumns()
                        }
                    }
                    Catch
                    {
                        Write-Error $_
                    }
                }
                'Border' {
                    If($Border -eq '*')
                    {
                        $Border = 'Top', 'Bottom', 'Left', 'Right'
                    }
                    foreach($Side in @( $Border | Select -Unique ) )
                    {
                        if(-not $BorderStyle)
                        {
                            $BorderStyle = [OfficeOpenXml.Style.ExcelBorderStyle]::Thin
                        }
                        if(-not $BorderColorConverted)
                        {
                            $BorderColorConverted = [System.Drawing.Color]::Black
                        }
                        $CellRange.Style.Border.$Side.Style = $BorderStyle
                        $CellRange.Style.Border.$Side.Color.SetColor( $BorderColorConverted )
                    }
                }
                'NumberFormat' {
                    $CellRange.Style.Numberformat.Format = $NumberFormat
                }
            }
        if($Passthru)
        {
            $WorkSheet
        }
    }
}


Function ConvertTo-ExcelCoordinate
{
    <#
    .SYNOPSIS
        Convert a row and column to an Excel coordinate

    .DESCRIPTION
        Convert a row and column to an Excel coordinate

    .PARAMETER Row
        Row number

    .PARAMETER Column
        Column number

    .EXAMPLE
        ConvertTo-ExcelCoordinate -Row 1 -Column 2

        #Get Excel coordinates for Row 1, Column 2.  B1.

    .NOTES
        Thanks to Doug Finke for his example:
            https://github.com/dfinke/ImportExcel/blob/master/ImportExcel.psm1

        Thanks to Philip Thompson for an expansive set of examples on working with EPPlus in PowerShell:
            https://excelpslib.codeplex.com/

    .LINK
        https://github.com/RamblingCookieMonster/PSExcel

    .FUNCTIONALITY
        Excel
    #>
    [OutputType([system.string])]
    [cmdletbinding()]
    param(
        [int]$Row,
        [int]$Column
    )

        #From http://stackoverflow.com/questions/297213/translate-a-column-index-into-an-excel-column-name
        Function Get-ExcelColumn
        {
            param([int]$ColumnIndex)

            [string]$Chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'

            $ColumnIndex -= 1
            [int]$Quotient = [math]::floor($ColumnIndex / 26)

            if($Quotient -gt 0)
            {
                ( Get-ExcelColumn -ColumnIndex $Quotient ) + $Chars[$ColumnIndex % 26]
            }
            else
            {
                $Chars[$ColumnIndex % 26]
            }
        }

    $ColumnIndex = Get-ExcelColumn $Column
    "$ColumnIndex$Row"
}