public class BatchBehaviourTestHarness implements Database.Batchable<sObject>, Database.Stateful
{
    /*
     * Static
     */
    
    static final String TEST_NAME = 'TEST_TO_DELETE';
    static final Integer BATCH_SIZE = 20;
    static final Boolean ASCENDING_ORDER = true;
    static final Boolean DESCENDING_ORDER = false;
    static final String ANY_ACCOUNT_TYPE = null;

    public static void createTestData()
    {
        Creator job = new Creator();
        job.TestName = TEST_NAME;
        job.NumberPrefix = 'TEST_';
        job.NumberOfRecords = 5000;
        job.AccountType = 'NORMAL';
        System.enqueueJob(job);
    }

    public static void deleteTestData()
    {
        Deleter job = new Deleter();
        job.TestName = TEST_NAME;
        System.enqueueJob(job);
    }
    
    public static void updateTest()
    {
        submitJob(new Updater('UpdAsc'),ASCENDING_ORDER,BATCH_SIZE,ANY_ACCOUNT_TYPE);
        submitJob(new Updater('UpdDsc'),DESCENDING_ORDER,BATCH_SIZE,ANY_ACCOUNT_TYPE);
    }

    public static void updateDeleteTest()
    {
        submitJob(new Updater('UpdAsc'),ASCENDING_ORDER,BATCH_SIZE,ANY_ACCOUNT_TYPE);
        submitJob(new Deleter(),DESCENDING_ORDER,BATCH_SIZE,ANY_ACCOUNT_TYPE);
    }

    public static void duplicateDeleteTest()
    {
        submitJob(new Duplicator('DupAsc'),ASCENDING_ORDER,BATCH_SIZE,'NORMAL');
        submitJob(new Deleter(),DESCENDING_ORDER,BATCH_SIZE,'NORMAL');
    }

    public static void submitJob(IBatchWorker worker, Boolean ascending, Integer batchSize, String accountType)
    {
        BatchBehaviourTestHarness job = new BatchBehaviourTestHarness();
        job.Worker = worker;
        job.Ascending = ascending;
        job.TestName = TEST_NAME;
        job.AccountType = accountType;
        Database.executeBatch(job,batchSize);
    }
    
    /*
     * Instance
     */
    
    public Boolean Ascending = true;
    public Boolean ExcludeNew = false;
    public String AccountType;
    public String TestName;
    public IBatchWorker Worker;

    public Database.querylocator start(Database.BatchableContext BC)
    {
        String q = 'select Id,Name,AccountNumber,Site from Account where Name=\''+ TestName + '\'';
        if(AccountType!=null) q += ' and Type = :AccountType';
        q += ' order by AccountNumber ' + (Ascending ? 'ASC' : 'DESC');
        return Database.getQueryLocator(q);
        
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        Worker.execute(scope);
    }
    
    public void finish(Database.BatchableContext BC){}
    
    /* 
     * Workers
     */

    public interface IBatchWorker
    {
        void execute(List<sObject> scope);
    }
    
    public class Updater implements IBatchWorker
    {
        public String Tag = '';
        Integer Counter = 0;
        
        public Updater(String tag)
        {
            this.Tag = tag;
        }

        public void execute(List<sObject> scope)
        {
            Counter++;
            for(sObject item : scope)
            {
                if(item instanceof Account)
                {
                    Account a = (Account) item;
                    a.Site = (a.Site == null ? '' : a.Site) + tag + String.valueOf(Counter);
                }
            }
            List<Database.SaveResult> srList = Database.update(scope,false);
            for(Database.SaveResult sr : srList)
            {
                if(!sr.isSuccess()) insert new FeedItem(body=Tag+String.valueOf(Counter)+JSON.serialize(sr),parentId=UserInfo.getUserId());
            }
        }
    }
    
    public class Duplicator implements IBatchWorker
    {
        public String Tag = '';
        Integer Counter = 0;

        public Duplicator(String tag)
        {
            this.tag = tag;
        }
        
        public void execute(List<sObject> scope)
        {
            Counter++;
            List<sObject> newItems = new List<sObject>();
            for(sObject item : scope)
            {
                sObject newItem = item.clone(false,false,false,false);
                newItems.add(newItem);
                if(newItem instanceof Account)
                {
                    Account a = (Account) newItem;
                    a.Site = tag + String.valueOf(Counter);
                    a.Type = 'DUPLICATE';
                }
            }
            Database.insert(newItems);            
        }
    }
    
    public class Creator implements System.Queueable
    {
        public String TestName, NumberPrefix;
        public Integer NumberOfRecords;
        public String Tag = '';
        public String AccountType;
        
        public void execute(System.QueueableContext qc)
        {
            List<Account> accounts = new List<Account>();
            for(Integer i = 0; i<NumberOfRecords; i++)
            {
                accounts.add(new Account(
                    Name=this.TestName,
                    AccountNumber=this.NumberPrefix+format(i+1),
                    Site=this.Tag,
                    Type=AccountType));
            }
            insert accounts;
        }
        
        String format(Integer i)
        {
            String numberString = String.valueOf(i);
            while(numberString.length()<6) numberString = '0' + numberString;
            return numberString;
        }
    }
    
    public class Deleter implements System.Queueable, IBatchWorker
    {
        public String TestName;
        public Boolean Purge=true;

        // Queueable
        public void execute(System.QueueableContext qc)
        {
            List<Account> accounts =[select id from Account where Name=:TestName limit 5000];
            execute(accounts);
        }

        // IBatchWorker
        public void execute(List<sObject> scope)
        {
            Database.delete(scope);
            if(Purge) Database.emptyRecycleBin(scope);

        }
    }
}
