#Get All Azure Resources
$Resources = Get-AzureRmResource

#Get All Azure Resource Groups
foreach ($G in Get-AzureRmResourceGroup) {

#If Resource Group Tags Exist Iterate Resource Groups Resources
    if ($G.Tags -ne $null) {
        foreach ($R in $Resources)
        {
            if ($R.ResourceGroupName -eq $G.ResourceGroupName) 
            {
                Write-Output ("Processing " + $R.ResourceName)
                Write-Output $G.ResourceGroupName

#Get Resource's Tags
                $ResourceTags = $R.Tags

#If current Resource Tag exists in its Resource Group's Tags then remove the tag. 
                if ($ResourceTags -ne $null) 
                {
                foreach ($key in $G.Tags.Keys)
                {
                    if ($ResourceTags.ContainsKey($key)) { $ResourceTags.Remove($key) }
                }
                
#Append Resource Group's tags to Resource's Tags.
                $ResourceTags += $G.Tags

#Write Tags in ResourceTags Variable.
                Set-AzureRmResource -Tag $ResourceTags -ResourceId $R.ResourceId -Force
                Write-Output ("Completed " + $R.ResourceName)
                }
            }
        }
    }
}