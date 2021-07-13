({
	init : function(component) {
		var record = component.get("v.record");
		var field = component.get("v.field");
		if(!$A.util.isEmpty(record) && !$A.util.isEmpty(field)){
			var fieldValue = record[field];
			if(!$A.util.isEmpty(fieldValue)){
				component.set("v.valueToShow", fieldValue);
			} else{
				component.set("v.valueToShow", '');
			}
		}
	}
})