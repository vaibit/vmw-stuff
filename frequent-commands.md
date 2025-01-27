**count stuff**

    | awk '{print $6,$7,$8,$9,$10,$11,$12,$13,$14}' | sort | uniq -c | sort -nr
    | awk '{print $15,$16,$17,$18,$19,$20,$21}' | sort | uniq -c | sort -nr

    $ grep "Password-based authentication" connector-* | grep SUCCESS | awk '{print $6,$7,$8,$9,$10,$11,$12,$13,$14}' | sort | uniq -c | sort -nr
    
    8 - Password-based authentication: sa-vmware-vco@corp.local - SUCCESS    
    6 - Password-based authentication: SVR-SX-CMP@corp.local - SUCCESS    
    5 - Password-based authentication: adm1@corp.local - SUCCESS

    $ grep "Executing workflow" server.log* | awk '{print$7,$8,$9,$10,$11,$12,$13,$14}' | sort | uniq -c | sort -nr | head -20
    
    335 Executing workflow 'Find LB-Zone By Id'    
    41 Executing workflow 'Find Relation LB-Zone'    
    14 Executing workflow 'F5_Zones'
  

**Upgrade history:**

    cat upgrade-report-* | grep -E 'Date|Before|After|Description' | grep -A 3 Date


**Auth** 

    grep " Authentication not valid." catalina.out | awk -F ' - ' '{ print $2}' | sort | uniq -c | sort -nr    
    6730 Authentication request for '/catalog-service/api/consumer/requests/353de668-7ef5-49b6-a44e-e1ce675e121a' failed with: Authentication not valid.    
    6658 Authentication request for '/catalog-service/api/consumer/requests/e8ec106d-cd20-4cdc-8897-8f6c9f6820c2' failed with: Authentication not valid.


**sort by date from multiple files:**

We tell it to split fields on **:** then sort on **characters 1 through 20** of the **second** field.  

    $ grep "successfully logged in" /ServerLogs/server.log* | sort **-t:** -k **2.1,2.20**
        
     /ServerLogs/server.log.38**:2020-09-01 02:58:56**.159+0000 [https-jsse-nio-0.0.0.0-8281-exec-7] INFO {} [UsersController] User 'admin' successfully logged in. Access point type 'client'  

**vSphere inventory DC**

    $ find . -type f -exec grep 'task type="inventory"' {} \; | grep 'result succeeded' | awk '{print $15,$16,$17,$18,$19,$20,$21,$22}' | sort | uniq -c | sort -nr
    
    388 type="inventory"><result succeeded="True"><message>&lt;?xml version="1.0" encoding="utf-16"?&gt;    
    29 type="inventory"><result succeeded="False"><message>One or more errors occurred.</message><parameter name="trace_id" /></result></task></workItemResponse>]    
    10 type="inventory"><result succeeded="False"><message>The request failed with HTTP status 501:

**VIDM AD SYNC**

    find . -name connector.log* -exec grep -E 'BEGIN SYNC|END SYNC' {} \; | sort
    
    find . -name connector.log* -exec grep -E 'BEGIN SYNC|END SYNC|Source directory poll|Directory Sync time for LIVE RUN'{} \;

 **Print all lines between two timestamps:**  

    export start=2022-07-27T10:26
    export end=2022-07-27T11:46
    sed -n '/$start/,/$end/p' log.txt

  **cron script if grep then**  

    */10 * * * * /bin/bash -c 'if grep -q "file-descriptors, value=0.8" /var/log/vmware/vco/app-server/metrics.log; then lsof -p "$(cat /var/log/vco/app-server/tomcat.pid)" > /var/log/vmware/vco/app-server/$(date +%Y-%m-%dT%H:%M:%S).txt; fi' 

  

  