﻿
Set-StrictMode -Version "latest"
$ErrorActionPreference="Stop"

$ResourceGroup="rg-demo-webapp-with-cicd"
$Location="uksouth"
$PlanName="WebAppPlanName"
$NumOfWorkers=2
$WebAppName="MyDemoWebApi123"
$PlanSKu="FREE"
$environment=$env:ENVIRONMENT
if ([string]::IsNullOrWhiteSpace($environment)){
    Write-Error -Message "The variable 'environment' was empty"
}
$StaticSiteStorageAccount="saustorageaccount001$environment"
$StaticSiteResourceGroup="rg-demo-staticwebsite-with-cicd"

$ctx=Get-AzContext
New-AzResourceGroup -Name $ResourceGroup  -Location $Location -Force

function CreatePlan(){
    Write-Host "Creating plan $PlanName"
    az appservice plan create --name $PlanName --resource-group $ResourceGroup --sku $PlanSKu --number-of-workers $NumOfWorkers --subscription $ctx.Subscription.Id    
}

function CreateWebApp(){
    Write-Host "Creating Web App $WebAppName"
    az webapp create --name $WebAppName --plan $PlanName --resource-group $ResourceGroup --subscription $ctx.Subscription.Id    
}

function CreateAppSettings(){
    Write-Host "Setting configuration parameters"
    $setting=@{}
    $setting.Add("key001","value001")
    $setting.Add("key002","value002")
    Set-AzWebApp -ResourceGroupName $ResourceGroup -Name $WebAppName -AppSettings $setting    
}

function RemoveAllExistingCORS(){
    Write-Host "Removing all CORS sites"
    az webapp cors remove --resource-group $ResourceGroup --name $WebAppName --allowed-origins    
}

function AddCORS(){
    $acc=Get-AzStorageAccount -ResourceGroupName $StaticSiteResourceGroup -Name $StaticSiteStorageAccount -ErrorAction Continue
    if ($null -eq $acc){
        Write-Warning -Message "The storage account $StaticSiteStorageAccount was not found. Not setting CORS"
    }
    Write-Host ("Endpoint of static site is {0}" -f $acc.PrimaryEndpoints.Web)
    $staticSiteEndPoint=$acc.PrimaryEndpoints.Web
    if ($staticSiteEndPoint.EndsWith("/")){
        $staticSiteEndPoint=$staticSiteEndPoint.Substring(0, $staticSiteEndPoint.Length-1)
    }

    $corsUrls=@($staticSiteEndPoint)

    foreach ($corsUrl in $corsUrls) {
        Write-Host "Adding CORS url $corsUrl"
        az webapp cors add --resource-group $ResourceGroup --name $WebAppName --allowed-origins $corsUrl
    }    
}


CreatePlan
CreateWebApp
CreateAppSettings
RemoveAllExistingCORS
AddCORS
