public with sharing class BumpControllerExtension {

	// extension for both StandardControllers and StandardSetControllers
	// there's no implementation relation between StandardController and StandardSetController, 
	// so we use ControllerAdapter
	ControllerAdapter m_controller;

	public String BumpMessage { get; set; }

	static final List<String> FIELD_NAMES = new List<String> {'OwnerId'};
	static final String DEFAULT_MESSAGE = 'Bump! ';

	public BumpControllerExtension(ApexPages.StandardSetController controller) {
		init(controller);
	}

	public BumpControllerExtension(ApexPages.StandardController controller) {
		init(controller);
	}

	void init(Object controller) {
		m_controller = ControllerAdapter.adapt(controller);
		m_controller.addFields(FIELD_NAMES);
		BumpMessage = DEFAULT_MESSAGE;
	}

	public ApexPages.PageReference bump() {
		try{
			List<FeedItem> feedItems = new List<FeedItem>();
			List<EntitySubscription> entitySubscriptions = new List<EntitySubscription>();
			for(SObject item : m_controller.getSelected()) {
				feedItems.add(new FeedItem(ParentId=item.Id, body=BumpMessage));
				entitySubscriptions.add(new EntitySubscription(ParentId=item.Id, subscriberid=(Id)item.get('OwnerId')));
			}
			insert feedItems;
			insert entitySubscriptions;
			return m_controller.cancel(); // all's good - go back to where we came from
		}
		catch(Exception e) {
			ApexPages.addMessages(e);
			return null; // all's not good  - stay put to see the messages
		}
	}

}