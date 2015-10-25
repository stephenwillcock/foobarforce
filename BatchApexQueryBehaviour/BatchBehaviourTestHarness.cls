public class BatchBehaviourTestHarness implements Database.Batchable<sObject>, Database.Stateful
{
	/*
	 * Static
	 */
    
    static final String TEST_NAME = 'TEST_TO_DELETE';
    static final Integer BATCH_SIZE = 10;

    public static void createTestData()
    {
		Creator job = new Creator();
        job.TestName = TEST_NAME;
        job.NumberPrefix = 'TEST_';
		job.NumberOfRecords = 5000;
		System.enqueueJob(job);
    }

    public static void deleteTestData()
    {
        Deleter job = new Deleter();
        job.TestName = TEST_NAME;
        System.enqueueJob(job);
    }
    
    public static void deleteTest()
    {
        updateTestDataBatch(true,'Asc');
        deleteTestDataBatch(false);
    }

    public static void updateTest()
    {
        updateTestDataBatch(true,'Asc');
        updateTestDataBatch(false,'Desc');
    }

    static void updateTestDataBatch(Boolean ascending, String tag)
    {
        BatchBehaviourTestHarness job = new BatchBehaviourTestHarness();
        Updater updater = new Updater();
        updater.Tag = tag;
        job.Worker = updater; 
		job.Ascending = ascending;
        job.TestName = TEST_NAME;
		Database.executeBatch(job,BATCH_SIZE);
    }
    
    static void deleteTestDataBatch(Boolean ascending)
    {
        BatchBehaviourTestHarness job = new BatchBehaviourTestHarness();
        job.Worker = new Deleter();
		job.Ascending = ascending;
        job.TestName = TEST_NAME;
		Database.executeBatch(job,BATCH_SIZE);
    }
    
	/*
	 * Instance
	 */
    
    public Boolean Ascending = true;
    public String TestName;
    public IBatchWorker Worker;

    public Database.querylocator start(Database.BatchableContext BC)
	{
		String q = 'select Id,Name,AccountNumber,Site from Account where Name=\''+ TestName + '\' order by AccountNumber ' + (Ascending ? 'ASC' : 'DESC');
        system.debug(q);
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
            Database.update(scope);            
        }
    }
    
    public class Creator implements System.Queueable
    {
        public String TestName, NumberPrefix;
        public Integer NumberOfRecords;
        public String Tag = '';
        
        public void execute(System.QueueableContext qc)
        {
            List<Account> accounts = new List<Account>();
            for(Integer i = 0; i<NumberOfRecords; i++)
            {
                accounts.add(new Account(
                    Name=this.TestName,
                    AccountNumber=this.NumberPrefix+format(i+1),
                	Site=this.Tag));
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
            Database.emptyRecycleBin(scope);

        }
    }
}