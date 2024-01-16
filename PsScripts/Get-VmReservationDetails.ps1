<#
.SYNOPSIS
    Gets consumption summary and consumption detail and merges this with the provided reservation(s)
.DESCRIPTION
    Information about (VM) reservations and their usage are, besides the portal, not available in a single view. This 
    script takes one or more reservation objects as input and grabs the consumption summary and details. It outputs a row for 
    each obtained detail (VM) merged with the summary and reservation data.

    By default it grabs the summary for current month and the details for the last day, but can be configured to use last month for the
    summary and it will then grab the last day of that month for the details.
.PARAMETER Reservation
    Input object containing the reservation the summary and details should be retrieved for.
.PARAMETER ReportLastMonth
    Switch parameter. If set the summary of the last month will be used for the output. If not set
    the script will use the current month for the summary and the last day for the details.
.EXAMPLE
    Get-VmReservationDetails.ps1 -Reservation $Reservation
    Grabs the details for the (one) provided reservation object
.EXAMPLE
    Get-AzReservation `
        | Where-Object {
            $_.ReservedResourceType -eq "VirtualMachines" `
            -and $_.ProvisioningState -ne "Expired"
        } | .\Get-VmReservationDetails.ps1
    Grabs the details for all the retrieved reservations.
.EXAMPLE
    Get-AzReservation `
        | Where-Object {
            $_.ReservedResourceType -eq "VirtualMachines" `
            -and $_.ProvisioningState -ne "Expired"
        } | .\Get-VmReservationDetails.ps1 `
             | Select-Object DisplayName, DisplayProvisioningState, `
                    ExpiryDate, PurchaseDate, Location, Sku, Term, `
                    AveUtilizationPercentage, MaxUtilizationPercentage, `
                    MinUtilizationPercentage, UsageDate, UsedHour, LastUsedByName, `
                    LastUsedBySubscriptionId, LastUsedBySubscriptionName, LastUsedByResourceGroup
    Grabs the details for all the retrieved reservations, limiting the output to common columns
#>


[CmdletBinding()]
param (
    [Parameter(ValueFromPipeline)]
    [object]
    $Reservation,

    [Switch]
    $ReportLastMonth
)

Begin {
    function Split-ResourceId {
        param (
            [string]$resourceID
        )
        $array = $resourceID.Split('/') 
        $indexS = 0..($array.Length - 1) | Where-Object { $array[$_] -eq 'subscriptions' }
        $indexG = 0..($array.Length - 1) | Where-Object { $array[$_] -eq 'resourcegroups' }
        # If the resource is a scale set the resource id looks slightly different
        $indexV = $resourceID -match "virtualMachineScaleSets" ? 
             (0..($array.Length - 1) | Where-Object { $array[$_] -eq 'virtualMachineScaleSets' }) :
             (0..($array.Length - 1) | Where-Object { $array[$_] -eq 'virtualmachines' })
        return $array.get($indexS + 1), $array.get($indexG + 1), $array.get($indexV + 1)
    }

    # Set reporting variables
    $today = (Get-Date)
    $reportingMonth = $ReportLastMonth ? $today.AddMonths(-1).Month : $today.Month
    $reportingYear = $ReportLastMonth -and $today.Month -eq 1 ? $today.AddYears(-1).Year : $today.Year
    $lastDayOfLastMonth = [DateTime]::DaysInMonth($reportingYear, $today.Month)
    $knownSubs = Get-AzSubscription -TenantId (Get-AzContext).Tenant | Select-Object subscriptionId, Name

} Process {

    # Get the consumption summary for the reservations, default is current month, unless $ReportLastMonth is set
    $consumptionSummary = $Reservation `
    | ForEach-Object { 
        Get-AzConsumptionReservationSummary `
            -ReservationOrderId $_.name.split('/')[0] `
            -ReservationId $_.name.split('/')[1] `
            -Grain Monthly
    } | Where-Object { $_.UsageDate -eq ("1-{0}-{1} 00:00:00" -f ($reportingMonth, $reportingYear) | Get-Date) }

    # Get the consumption detail for the reservations over last day, unless $ReportLastMonth is set, then use last day of the month
    $detailDate = $ReportLastMonth ? 
    ("{0}-{1}-{2} 00:00:00" -f ($lastDayOfLastMonth, $reportingMonth, $reportingYear) | Get-Date) : 
        ("{0}-{1}-{2} 00:00:00" -f ($today.Day, $today.Month, $today.Year) | Get-Date)

    $consumptionDetail = $Reservation `
    | ForEach-Object {
        Get-AzConsumptionReservationDetail `
            -ReservationOrderId $_.name.split('/')[0] `
            -ReservationId $_.name.split('/')[1] `
            -StartDate $detailDate `
            -EndDate $detailDate
    }


    # Merge
    foreach ($reservation in $reservations) {
        $summary = $consumptionSummary `
        | Where-Object {
            $_.ReservationOrderId -eq $reservation.name.split('/')[0] `
                -and $_.ReservationId -eq $reservation.name.split('/')[1]
        }
        foreach ($detail in ($consumptionDetail `
                | Where-Object { 
                    $_.ReservationOrderId -eq $reservation.name.split('/')[0] `
                        -and $_.ReservationId -eq $reservation.name.split('/')[1]
                })) {
            # Build a report row
            $reportRow = New-Object -TypeName psobject
            # Add reservation properties
        ($reservation | get-member -MemberType Property) | Where-Object {$_.name -notin ("Etag", "Name", "Id", "Type")} | ForEach-Object { $reportRow | Add-Member -MemberType NoteProperty -Name $_.Name -Value $reservation.($_.Name)}
            # Add summary properties
        ($summary | get-member -MemberType Property) | Where-Object {$_.name -notin ("Etag", "Name", "Id", "Type")} | ForEach-Object { $reportRow | Add-Member -MemberType NoteProperty -Name $_.Name -Value $summary.($_.Name) }
            # Add detail properties
            $resource = Split-ResourceId $detail.InstanceId
            $resourceSubName = $resource[0] -in $knownSubs.SubscriptionId ? ($knownSubs | Where-Object { $_.SubscriptionId -eq $resource[0] }).Name : ""
            $reportRow | Add-Member -MemberType NoteProperty -Name LastUsedByName -Value $resource[2]
            $reportRow | Add-Member -MemberType NoteProperty -Name LastUsedBySubscriptionId -Value $resource[0]
            $reportRow | Add-Member -MemberType NoteProperty -Name LastUsedBySubscriptionName -Value $resourceSubName
            $reportRow | Add-Member -MemberType NoteProperty -Name LastUsedByResourceGroup -Value $resource[1]
            $reportRow | Add-Member -MemberType NoteProperty -Name LastUsedByResourceId -Value $detail.InstanceId
            # output row
            $reportRow
        }
    }
} End {}