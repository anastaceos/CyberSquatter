# Set the path to the directory containing the CSV files
$csvDirectory = "C:\CyberSquatter"

# Create an empty array to store the data from each CSV file
$csvData = @()

# Loop through each CSV file in the directory
$csvFiles = Get-ChildItem -Path $csvDirectory -Filter "*.csv"
foreach ($csvFile in $csvFiles) {
    # Import the CSV file
    $csv = Import-Csv -Path $csvFile.FullName

    # Loop through each row in the CSV file
    foreach ($row in $csv) {
        # Create an object to store the desired column values
        $csvEntry = [PSCustomObject]@{
            Fuzzer  = $row.fuzzer
            Domain  = $row.domain
            DNS_A   = $row.dns_a
            DNS_AAAA = $row.dns_aaaa
            DNS_MX  = $row.dns_mx
            DNS_NS  = $row.dns_ns
            GeoIP   = $row.geoip
            MX_Spy  = $row.mx_spy
        }

        # Add the object to the array
        $csvData += $csvEntry
    }
}

# Export the combined data to a new CSV file
$csvData | Export-Csv -Path "C:\CSMerged.csv" -NoTypeInformation
