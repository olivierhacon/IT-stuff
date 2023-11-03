$allpools = (Get-CimInstance -EA SilentlyContinue -ClassName applicationpool -Namespace root\webadministration).Name
@{  
	"data" = $allpools | foreach { @{
		"{#APPNAME}" = $_.ToUpper()
	}}
} | ConvertTo-Json