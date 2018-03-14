# LogicMonitor Collectors (New vNet)

[![Deploy to Azure](/Azure/Images/azure_deploy.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fans-cst%2FCloud-Scripts%2Fmaster%2FAzure%2FLogicMonitor%2FLogicMonitor-Collector-New-Network%2FCreateAVSetLMCollector.json)
[![Deploy to Azure](/Azure/Images/azure_view.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fans-cst%2FCloud-Scripts%2Fmaster%2FAzure%2FLogicMonitor%2FLogicMonitor-Collector-New-Network%2FCreateAVSetLMCollector.json)

The CreateAVSetLMCollector template creates a failover pair of LogicMonitor collectors into a new vNet and registers them in the LogicMonitor portal. The template uses the Azure VM CustomScriptExtension to download a PowerShell installation script from GitHub, once executed it registers the collectors in LogicMonitor then downloads the collector installation media, and finally installs the collector software. 

![Diagram](/LogicMonitor-Collector-New-Network/CreateLMCollector.png)


[![Deploy to Azure](/Azure/Images/azure_deploy.png)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fans-cst%2FCloud-Scripts%2Fmaster%2FAzure%2FLogicMonitor%2FLogicMonitor-Collector-New-Network%2FCreateSingleLMCollector.json)
[![Deploy to Azure](/Azure/Images/azure_view.png)](http://armviz.io/#/?load=https%3A%2F%2Fraw.githubusercontent.com%2Fans-cst%2FCloud-Scripts%2Fmaster%2FAzure%2FLogicMonitor%2FLogicMonitor-Collector-New-Network%2FCreateSingleLMCollector.json)

The CreateSingleLMCollector template creates a single LogicMonitor collector into a new vNet and registers it in the LogicMonitor portal. The template uses the Azure VM CustomScriptExtension to download a PowerShell installation script from GitHub, once executed it registers the collector in LogicMonitor then downloads the collector installation media, and finally installs the collector software. 

![Diagram](/LogicMonitor-Collector-Existing-Network/CreateLMCollectorSingleVM.png)
