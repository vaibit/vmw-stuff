## PSQL

**backup db over network**

    ssh root@vra-va-ip "/opt/vmware/vpostgres/current/bin/pg_dump -U vcac -h localhost vcac" >> vra_postgress_bak.sql

**Compressed/binary :**

    ssh root@vra-va-ip "su - postgres -c '/opt/vmware/vpostgres/current/bin/pg_dump -v -d vcac -Fc'" >> dump.sql


**If the database is large:**

    Use the "-Fc" option in the dump command to create a compressed binary backup (instead of the "-Fp" option that creates a huge SQL text file).  The default compression of the "-Fc" option is roughly the equivalent of zip.
         
    #Dump the source vcac db in binary format (postgres user must have write permissions to the target path)
    su - postgres -c "/opt/vmware/vpostgres/current/bin/pg_dump -v -d vcac -Fc -f /tmp/vcacbak.dmp"
         
    The only caveat is that you will have to restore the dump to a postgres instance that is the same version and was compiled with the same flags as the source. That should not be a problem for vRA since you can just restore to any other instance of the same version (and maybe to *any* postgres 9.5 instance since vRA postgres was probably not compiled with any intrusive custom flags). A binary dump also gives you the option of restoring it to a different db name on the same server as an existing vcac db, e.g.:
         
    #Export variable for DB name:
    export database=database_name
         
    #Create a new db to restore to, e.g., $database
    su - postgres -c "/opt/vmware/vpostgres/current/bin/createdb -e $database"
         
    #Restore the db dump to the new db (postgres user must have read permissions on the dmp file)
    su - postgres -c "/opt/vmware/vpostgres/current/bin/pg_restore -j2 -v -d $database /tmp/vcacbak.dmp"
         
    #Connect to the new db
    su - postgres -c "/opt/vmware/vpostgres/current/bin/psql -d $database"
     
    #Drop the temporary db when you're done using it
    su - postgres -c "/opt/vmware/vpostgres/current/bin/psql -e -c 'DROP DATABASE $database'"



## MSSQL
**Show largest objects**
[How to find largest objects in a SQL Server database? - Stack Overflow](https://stackoverflow.com/questions/2094436/how-to-find-largest-objects-in-a-sql-server-database)

    SELECT
    t.NAME AS TableName,
    i.name as indexName,
    sum(p.rows) as RowCounts,
    sum(a.total_pages) as TotalPages,
    sum(a.used_pages) as UsedPages,
    sum(a.data_pages) as DataPages,
    (sum(a.total_pages) * 8) / 1024 as TotalSpaceMB,
    (sum(a.used_pages) * 8) / 1024 as UsedSpaceMB,
    (sum(a.data_pages) * 8) / 1024 as DataSpaceMB
    FROM
    sys.tables t
    INNER JOIN
    sys.indexes i ON t.OBJECT_ID = i.object_id
    INNER JOIN
    sys.partitions p ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
    INNER JOIN
    sys.allocation_units a ON p.partition_id = a.container_id
    WHERE
    t.NAME NOT LIKE 'dt%' AND
    i.OBJECT_ID > 255 AND
    i.index_id <= 1GROUP BY
    t.NAME, i.object_id, i.index_id, i.name
    ORDER BY SUM(p.rows) DESC

**Last run queries**

    SELECT deqs.last_execution_time AS [Time], dest.text AS [Query]
    FROM sys.dm_exec_query_stats AS deqs
    CROSS APPLY sys.dm_exec_sql_text(deqs.sql_handle) AS dest
    ORDER BY deqs.last_execution_time DESC

**LongRunningQueries.SQL**

    SELECT
    qs.execution_count
    , qs.total_physical_reads
    ,(qs.total_physical_reads / qs.execution_count) AS average_physical_reads
    , qs.total_logical_writes
    , (qs.total_logical_writes / qs.execution_count) AS average_logical_writes
    , qs.total_logical_reads
    , (qs.total_logical_reads / qs.execution_count) AS average_logical_lReads
    , qs.total_clr_time
    , (qs.total_clr_time / qs.execution_count) AS average_CLRTime
    , qs.total_elapsed_time
    , (qs.total_elapsed_time / qs.execution_count) AS average_elapsed_time
    , qs.last_execution_time
    , qs.creation_time
    , SUBSTRING(st.[text], (qs.statement_start_offset/2) + 1,
    ((CASE qs.statement_end_offset
    WHEN -1 THEN DATALENGTH(st.[text]) ELSE qs.statement_end_offset END
    - qs.statement_start_offset)/2) + 1) AS SQL_Statement
    FROM sys.dm_exec_query_stats AS qs
    CROSS apply sys.dm_exec_sql_text(qs.sql_handle) AS st    
    WHERE qs.last_execution_time > DATEADD(HH,-2,GETDATE())    
    ORDER BY average_elapsed_time DESC

**delete in batches**
[How to efficiently delete rows while NOT using Truncate Table in a 500,000+ rows table](https://stackoverflow.com/questions/11230225/how-to-efficiently-delete-rows-while-not-using-truncate-table-in-a-500-000-rows)](https://stackoverflow.com/questions/11230225/how-to-efficiently-delete-rows-while-not-using-truncate-table-in-a-500-000-rows)

    deleteMore:
    DELETE TOP(10000) Sales WHERE toDelete='1'IF @@ROWCOUNT != 0
    goto deleteMore
    
    deleteMore:
    DELETE TOP(10000) [DynamicOps.Tracking].[TrackingLogItems]
    where Message like '%Cannot find%'
    IF @@ROWCOUNT != 0
    goto deleteMore
    
**Wait statistics, or please tell me where it hurts**
[SQL Server Wait Statistics: Tell me where it hurts](https://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/)

    -- Last updated October 1, 2021
    WITH [Waits] AS
        (SELECT
            [wait_type],
            [wait_time_ms] / 1000.0 AS [WaitS],
            ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
            [signal_wait_time_ms] / 1000.0 AS [SignalS],
            [waiting_tasks_count] AS [WaitCount],
            100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
            ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
        FROM sys.dm_os_wait_stats
        WHERE [wait_type] NOT IN (
            -- These wait types are almost 100% never a problem and so they are
            -- filtered out to avoid them skewing the results. Click on the URL
            -- for more information.
            N'BROKER_EVENTHANDLER', -- https://www.sqlskills.com/help/waits/BROKER_EVENTHANDLER
            N'BROKER_RECEIVE_WAITFOR', -- https://www.sqlskills.com/help/waits/BROKER_RECEIVE_WAITFOR
            N'BROKER_TASK_STOP', -- https://www.sqlskills.com/help/waits/BROKER_TASK_STOP
            N'BROKER_TO_FLUSH', -- https://www.sqlskills.com/help/waits/BROKER_TO_FLUSH
            N'BROKER_TRANSMITTER', -- https://www.sqlskills.com/help/waits/BROKER_TRANSMITTER
            N'CHECKPOINT_QUEUE', -- https://www.sqlskills.com/help/waits/CHECKPOINT_QUEUE
            N'CHKPT', -- https://www.sqlskills.com/help/waits/CHKPT
            N'CLR_AUTO_EVENT', -- https://www.sqlskills.com/help/waits/CLR_AUTO_EVENT
            N'CLR_MANUAL_EVENT', -- https://www.sqlskills.com/help/waits/CLR_MANUAL_EVENT
            N'CLR_SEMAPHORE', -- https://www.sqlskills.com/help/waits/CLR_SEMAPHORE
     
            -- Maybe comment this out if you have parallelism issues
            N'CXCONSUMER', -- https://www.sqlskills.com/help/waits/CXCONSUMER
     
            -- Maybe comment these four out if you have mirroring issues
            N'DBMIRROR_DBM_EVENT', -- https://www.sqlskills.com/help/waits/DBMIRROR_DBM_EVENT
            N'DBMIRROR_EVENTS_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_EVENTS_QUEUE
            N'DBMIRROR_WORKER_QUEUE', -- https://www.sqlskills.com/help/waits/DBMIRROR_WORKER_QUEUE
            N'DBMIRRORING_CMD', -- https://www.sqlskills.com/help/waits/DBMIRRORING_CMD
            N'DIRTY_PAGE_POLL', -- https://www.sqlskills.com/help/waits/DIRTY_PAGE_POLL
            N'DISPATCHER_QUEUE_SEMAPHORE', -- https://www.sqlskills.com/help/waits/DISPATCHER_QUEUE_SEMAPHORE
            N'EXECSYNC', -- https://www.sqlskills.com/help/waits/EXECSYNC
            N'FSAGENT', -- https://www.sqlskills.com/help/waits/FSAGENT
            N'FT_IFTS_SCHEDULER_IDLE_WAIT', -- https://www.sqlskills.com/help/waits/FT_IFTS_SCHEDULER_IDLE_WAIT
            N'FT_IFTSHC_MUTEX', -- https://www.sqlskills.com/help/waits/FT_IFTSHC_MUTEX
      
           -- Maybe comment these six out if you have AG issues
            N'HADR_CLUSAPI_CALL', -- https://www.sqlskills.com/help/waits/HADR_CLUSAPI_CALL
            N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', -- https://www.sqlskills.com/help/waits/HADR_FILESTREAM_IOMGR_IOCOMPLETION
            N'HADR_LOGCAPTURE_WAIT', -- https://www.sqlskills.com/help/waits/HADR_LOGCAPTURE_WAIT
            N'HADR_NOTIFICATION_DEQUEUE', -- https://www.sqlskills.com/help/waits/HADR_NOTIFICATION_DEQUEUE
            N'HADR_TIMER_TASK', -- https://www.sqlskills.com/help/waits/HADR_TIMER_TASK
            N'HADR_WORK_QUEUE', -- https://www.sqlskills.com/help/waits/HADR_WORK_QUEUE
     
            N'KSOURCE_WAKEUP', -- https://www.sqlskills.com/help/waits/KSOURCE_WAKEUP
            N'LAZYWRITER_SLEEP', -- https://www.sqlskills.com/help/waits/LAZYWRITER_SLEEP
            N'LOGMGR_QUEUE', -- https://www.sqlskills.com/help/waits/LOGMGR_QUEUE
            N'MEMORY_ALLOCATION_EXT', -- https://www.sqlskills.com/help/waits/MEMORY_ALLOCATION_EXT
            N'ONDEMAND_TASK_QUEUE', -- https://www.sqlskills.com/help/waits/ONDEMAND_TASK_QUEUE
            N'PARALLEL_REDO_DRAIN_WORKER', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_DRAIN_WORKER
            N'PARALLEL_REDO_LOG_CACHE', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_LOG_CACHE
            N'PARALLEL_REDO_TRAN_LIST', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_TRAN_LIST
            N'PARALLEL_REDO_WORKER_SYNC', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_SYNC
            N'PARALLEL_REDO_WORKER_WAIT_WORK', -- https://www.sqlskills.com/help/waits/PARALLEL_REDO_WORKER_WAIT_WORK
            N'PREEMPTIVE_OS_FLUSHFILEBUFFERS', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_OS_FLUSHFILEBUFFERS
            N'PREEMPTIVE_XE_GETTARGETSTATE', -- https://www.sqlskills.com/help/waits/PREEMPTIVE_XE_GETTARGETSTATE
            N'PVS_PREALLOCATE', -- https://www.sqlskills.com/help/waits/PVS_PREALLOCATE
            N'PWAIT_ALL_COMPONENTS_INITIALIZED', -- https://www.sqlskills.com/help/waits/PWAIT_ALL_COMPONENTS_INITIALIZED
            N'PWAIT_DIRECTLOGCONSUMER_GETNEXT', -- https://www.sqlskills.com/help/waits/PWAIT_DIRECTLOGCONSUMER_GETNEXT
            N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP', -- https://www.sqlskills.com/help/waits/QDS_PERSIST_TASK_MAIN_LOOP_SLEEP
            N'QDS_ASYNC_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_ASYNC_QUEUE
            N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
                -- https://www.sqlskills.com/help/waits/QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP
            N'QDS_SHUTDOWN_QUEUE', -- https://www.sqlskills.com/help/waits/QDS_SHUTDOWN_QUEUE
            N'REDO_THREAD_PENDING_WORK', -- https://www.sqlskills.com/help/waits/REDO_THREAD_PENDING_WORK
            N'REQUEST_FOR_DEADLOCK_SEARCH', -- https://www.sqlskills.com/help/waits/REQUEST_FOR_DEADLOCK_SEARCH
            N'RESOURCE_QUEUE', -- https://www.sqlskills.com/help/waits/RESOURCE_QUEUE
            N'SERVER_IDLE_CHECK', -- https://www.sqlskills.com/help/waits/SERVER_IDLE_CHECK
            N'SLEEP_BPOOL_FLUSH', -- https://www.sqlskills.com/help/waits/SLEEP_BPOOL_FLUSH
            N'SLEEP_DBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DBSTARTUP
            N'SLEEP_DCOMSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_DCOMSTARTUP
            N'SLEEP_MASTERDBREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERDBREADY
            N'SLEEP_MASTERMDREADY', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERMDREADY
            N'SLEEP_MASTERUPGRADED', -- https://www.sqlskills.com/help/waits/SLEEP_MASTERUPGRADED
            N'SLEEP_MSDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_MSDBSTARTUP
            N'SLEEP_SYSTEMTASK', -- https://www.sqlskills.com/help/waits/SLEEP_SYSTEMTASK
            N'SLEEP_TASK', -- https://www.sqlskills.com/help/waits/SLEEP_TASK
            N'SLEEP_TEMPDBSTARTUP', -- https://www.sqlskills.com/help/waits/SLEEP_TEMPDBSTARTUP
            N'SNI_HTTP_ACCEPT', -- https://www.sqlskills.com/help/waits/SNI_HTTP_ACCEPT
            N'SOS_WORK_DISPATCHER', -- https://www.sqlskills.com/help/waits/SOS_WORK_DISPATCHER
            N'SP_SERVER_DIAGNOSTICS_SLEEP', -- https://www.sqlskills.com/help/waits/SP_SERVER_DIAGNOSTICS_SLEEP
            N'SQLTRACE_BUFFER_FLUSH', -- https://www.sqlskills.com/help/waits/SQLTRACE_BUFFER_FLUSH
            N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', -- https://www.sqlskills.com/help/waits/SQLTRACE_INCREMENTAL_FLUSH_SLEEP
            N'SQLTRACE_WAIT_ENTRIES', -- https://www.sqlskills.com/help/waits/SQLTRACE_WAIT_ENTRIES
            N'VDI_CLIENT_OTHER', -- https://www.sqlskills.com/help/waits/VDI_CLIENT_OTHER
            N'WAIT_FOR_RESULTS', -- https://www.sqlskills.com/help/waits/WAIT_FOR_RESULTS
            N'WAITFOR', -- https://www.sqlskills.com/help/waits/WAITFOR
            N'WAITFOR_TASKSHUTDOWN', -- https://www.sqlskills.com/help/waits/WAITFOR_TASKSHUTDOWN
            N'WAIT_XTP_RECOVERY', -- https://www.sqlskills.com/help/waits/WAIT_XTP_RECOVERY
            N'WAIT_XTP_HOST_WAIT', -- https://www.sqlskills.com/help/waits/WAIT_XTP_HOST_WAIT
            N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', -- https://www.sqlskills.com/help/waits/WAIT_XTP_OFFLINE_CKPT_NEW_LOG
            N'WAIT_XTP_CKPT_CLOSE', -- https://www.sqlskills.com/help/waits/WAIT_XTP_CKPT_CLOSE
            N'XE_DISPATCHER_JOIN', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_JOIN
            N'XE_DISPATCHER_WAIT', -- https://www.sqlskills.com/help/waits/XE_DISPATCHER_WAIT
            N'XE_TIMER_EVENT' -- https://www.sqlskills.com/help/waits/XE_TIMER_EVENT
            )
        AND [waiting_tasks_count] > 0
        )
    SELECT
        MAX ([W1].[wait_type]) AS [WaitType],
        CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
        CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
        CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
        MAX ([W1].[WaitCount]) AS [WaitCount],
        CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
        CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
        CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
        CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S],
        CAST ('https://www.sqlskills.com/help/waits/' + MAX ([W1].[wait_type]) as XML) AS [Help/Info URL]
    FROM [Waits] AS [W1]
    INNER JOIN [Waits] AS [W2] ON [W2].[RowNum] <= [W1].[RowNum]
    GROUP BY [W1].[RowNum]
    HAVING SUM ([W2].[Percentage]) - MAX( [W1].[Percentage] ) < 95; -- percentage threshold
    GO
