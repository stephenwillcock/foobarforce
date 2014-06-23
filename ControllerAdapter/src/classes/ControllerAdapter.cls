public abstract with sharing class ControllerAdapter {

	public static ControllerAdapter adapt(ApexPages.StandardController controller) {
			return new StandardControllerAdapter(controller, new List<SObject>());
	}

	// use this factory method where the list type is important - for example if we need to perform list.getSObjectType() later on
	public static ControllerAdapter adapt(ApexPages.StandardController controller, List<SObject> listPrototype) {
			return new StandardControllerAdapter(controller, listPrototype);
	}

	public static ControllerAdapter adapt(ApexPages.StandardSetController controller) {
			return new StandardSetControllerAdapter(controller);
	}

	public abstract void addFields(List<String> fieldNames);
	public abstract List<SObject> getSelected();
	public abstract ApexPages.PageReference cancel();

	public class StandardControllerAdapter extends ControllerAdapter {
		ApexPages.StandardController m_controller;
		List<SObject> m_listPrototype;
		StandardControllerAdapter(ApexPages.StandardController controller, List<SObject> listPrototype) {
			m_controller = controller;
			m_listPrototype = listPrototype;
		}
		public override void addFields(List<String> fieldNames) {
			m_controller.addFields(fieldNames);
		}
		// StandardController has no equivalent to getSelected(), but we're 
		// making the single record of the StandardController to be "selected"
		public override List<SObject> getSelected() {
			List<SObject> result = m_listPrototype.clone();
			result.add(m_controller.getRecord());
			return result;
		}
		public override ApexPages.PageReference cancel() {
			return m_controller.cancel();
		}
	}

	public class StandardSetControllerAdapter extends ControllerAdapter {
		ApexPages.StandardSetController m_controller;
		StandardSetControllerAdapter(ApexPages.StandardSetController controller) {
			m_controller = controller;
		}
		public override void addFields(List<String> fieldNames) {
			m_controller.addFields(fieldNames);
		}
		public override List<SObject> getSelected() {
			return m_controller.getSelected();
		}
		public void setSelected(List<SObject> items) {
			m_controller.setSelected(items);
		}
		public override ApexPages.PageReference cancel() {
			return m_controller.cancel();
		}
	}
}