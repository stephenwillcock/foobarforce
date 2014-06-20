public abstract with sharing class ControllerAdapter {

	public static ControllerAdapter adapt(Object controller) {
		if(controller instanceof ApexPages.StandardController)
			return new StandardControllerAdapter((ApexPages.StandardController) controller);
		else
			return new StandardSetControllerAdapter((ApexPages.StandardSetController) controller);
	}

	public abstract void addFields(List<String> fieldNames);
	public abstract List<SObject> getSelected();
	public abstract ApexPages.PageReference cancel();

	public class StandardControllerAdapter extends ControllerAdapter {
		ApexPages.StandardController m_controller;
		StandardControllerAdapter(ApexPages.StandardController controller) {
			m_controller = controller;
		}
		public override void addFields(List<String> fieldNames) {
			m_controller.addFields(fieldNames);
		}
		// StandardController has no equivalent to getSelected(), but we're 
		// making the single record of the StandardController to be "selected"
		public override List<SObject> getSelected() {
			return new List<SObject>{m_controller.getRecord()};
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
		public override ApexPages.PageReference cancel() {
			return m_controller.cancel();
		}
	}
}