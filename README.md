This Repository was created to document the possible values of the [Microsoft Graph Device Property](https://learn.microsoft.com/en-us/graph/api/resources/device?view=graph-rest-1.0#properties) "systemLabels", since the official Documentation is not quite clear.

What we do know is that the Property is read-only and used by Microsoft internally.
> [From Entra ID dynamic Group Rules for devices](https://learn.microsoft.com/en-us/entra/identity/users/groups-dynamic-membership#rules-for-devices)   
> Note  
> systemlabels is a read-only attribute that cannot be set with Intune.

In hope that Cunninghams Law is true, I thought it might be a good idea for someone to try and keep a public collection.
 
<br class="">
  

# Known Values

| Value | Use / Appearance | Submitter | Verified |
|---|---|---|---|
| AzureResource | [Windows VMs in Azure enabled with Microsoft Entra sign-in](https://learn.microsoft.com/en-us/entra/identity/devices/howto-vm-sign-in-azure-ad-windows) | Author | [Conditional Acces Documentation](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-condition-filters-for-devices#supported-operators-and-device-properties-for-filters), not seen in the wild yet  |
| M365Managed | [Devices managed using Microsoft Managed Desktop](https://learn.microsoft.com/en-us/managed-desktop/overview/service-plan) | Author | [Conditional Acces Documentation](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-condition-filters-for-devices#supported-operators-and-device-properties-for-filters), not seen in the wild yet |
| MultiUser | [Shared devices](https://learn.microsoft.com/en-us/entra/identity-platform/msal-shared-devices)  | Author | [Conditional Acces Documentation](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-condition-filters-for-devices#supported-operators-and-device-properties-for-filters), not seen in the wild yet |
| ...? | | | |

 
<br class="">
  


# Add more

If you would like to add more values or have a description corrected (or maybe even direct me to a complete official documentation), please raise a GitHub Issue (or a pull request) with a screenshot of the new Value and a guess as to what the usage might be.
 
<br class="">
  
If you would like to find out what the values in your Environments are, I have provided an example Script that pulls from your Environment
 
<br class="">
  
## informationCollector Prerequisites

1. PowerShell Modules
    - Microsoft.Graph.Authentication
2. GraphAPI Permissions on the Graph PowerShell, or A Custom Enterprise App
    - Device.Read.All
3. If Using Delegate Permission
    - User with Global Reader or a Role that can show Devices
4. A privileged Auth / Global Admin to Consent to the API Permissions

 
<br class="">
  

## informationCollector Usage

The Scipt mirrors most Authentication Flows of Connect-MgGraph. By default it will ask for the credentials interactively.

```powershell
.\informationCollector -tenantId "..." -clientId "..."

.\informationCollector -tenantId "..." -clientId "..." -certificateThumbprint "..."

# Will Prompt you for the Secret of your App ID - consider using a certificate
.\informationCollector -tenantId "..." -clientId "..." -useSecret

# Will go though the Device Code flow, should be used by default in for Example Cloud Shell
.\informationCollector -deviceCode
```
 
<br class="">
  
By Default you will get a short List of all systemLabels found in your Environment with a single Example Devicy displayName.   


If you want the script to return a full list of all Devices with the associated labels, use  `.\informationCollector -fullList`     
This should also be used in environments with a lot of Devices to skip the simplification, since reducing the List requires parsing all returned entries.