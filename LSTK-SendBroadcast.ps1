############### Quick and Dirty Broadcast Message ###############
#################################################################
############# Part of the LSTK (Lex Stanger ToolKit #############
#################################################################
############## Note: this must be run from a DAW ################
#################################################################
#################################################################

##### Update this to point to your OU ###########################
$SEARCHBASE  = "OU=Workstations,OU=Post,DC=child,DC=domain,DC=com"

##### Update with your message number ###########################
$message = "IRM in Washington has informed us that enterprise e-mail is down globally.  They have no estimated time for a fix.  ISC will send out updates as they are available.  If you have any questions, please call x2000."

#################################################################

# Pull all computers from your OU
$computers = Get-ADComputer -SearchBase $SEARCHBASE -Filter *

# Foreach computer in OU, spin up a job to send a message 
## Note: Jobs make the entire process run slightly faster. Job batches would drastically improve performance--future update.
$computers | Sort-Object name | Where-Object{$_.name -notin (Get-Job -state Completed).name } | %{
    
    # This governer prevents the jobs from overrunning your computer.
    # There is a much better way, but I wrote this in ~10 min.  Will update soon.
    while((Get-Job -state Running).count -ge 10)
    {
        "$((Get-Job -state Completed).count) / $($computers.count)"
        "Running: $((get-job -state Running).count)"
        
        while((Get-Job -state Running).count -ge 10)
        {
            sleep 2
        }
    }
    # Output current computer name
    $_.name
    # Spin up job to send message to PC.
    $null = Start-Job -Name $_.name -ArgumentList $_.name,$message -script{ 
        $comp    = $args[0]
        $message = $args[1]
        winrs -r:$comp msg * $message
    }
}
