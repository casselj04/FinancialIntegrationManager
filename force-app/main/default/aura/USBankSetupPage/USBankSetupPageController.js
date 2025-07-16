({
    doInit : function(component, event, helper) {
        component.set("v.loaded",false);
        var action = component.get("c.getCustomSettingDetails");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                component.set("v.Configuration",response.getReturnValue());                
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
        helper.findRunningAsyncJob(component, event, helper);
        helper.clientBranchDetails(component, event, helper);
    },
    
    addRow: function(component, event, helper) {
        helper.createObjectData(component, event);
    },
    
    removeRow: function(component, event, helper) {
        debugger;
        var CustomList = component.get("v.CustomSettingList");
        var removeLst = component.get("v.ClientToRemove");
        var selectedItem = event.currentTarget;
        var index = selectedItem.dataset.record;
        if(CustomList.length >= index && CustomList[index].Id != undefined && CustomList[index].Id != ''){
            removeLst.push(CustomList[index].Id);
        }
        component.set("v.ClientToRemove", removeLst);
        CustomList.splice(index, 1);
        component.set("v.CustomSettingList", CustomList);
    },
    
    saveBranchDetails : function(component, event, helper) {
        component.set("v.loaded",false);
        helper.saveBranchSettingDetails(component, event);
    },
    
    handleCheckbox : function(component, event, helper) {
        var CustomList = component.get("v.CustomSettingList");
        console.log('CustomList :'+JSON.stringify(CustomList));
        var index = event.getSource().get("v.name");
        console.log('index ::'+index);
        console.log('1st Name :'+CustomList[index].TSGCFG__Is_Default__c);
        for(let i=0;i<CustomList.length;i++){
            if(index == i){
                CustomList[i].TSGCFG__Is_Default__c = true;
            }else{
                CustomList[i].TSGCFG__Is_Default__c = false;
            }
            
        }
        component.set("v.CustomSettingList",CustomList);
        
    },
    
    
    SaveSetting : function(component, event, helper) {
        
        var action = component.get("c.updateCustomSettingDetails");
        action.setParams({ config : component.get("v.Configuration") });
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                helper.showToast(component, event,"Success!","Successfully updated custom setting!","success");  
                $A.get('e.force:refreshView').fire();
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    doAPICallout : function(component, event, helper) {
        
        var action = component.get("c.USBankAuthentication");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                var result = response.getReturnValue();
                if(result.includes('Authentication')){
                    helper.showToast(component, event,"Success!",result,"success");
                }else{
                    helper.showToast(component, event,"Error!",result,"error");
                }
                
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    helper.showToast(component, event,"Error!",errors[0].message,"error");
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + 
                                    errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
        
    },
    
    runBatchToUpdateCreditStatus : function(component, event, helper) {
        var action = component.get("c.UpdateCreditStatusFromBatch");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                
                helper.showToast(component, event,"Success!","Batch has been Started to sync Application status!","success");
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    helper.showToast(component, event,"Error!",errors[0].message,"error");
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    schedulerUSBank : function(component, event, helper){
        
        var selValue = component.get("v.selectedValue");
        
        var action = component.get("c.ScheduleUSBankForMin");
        action.setParams({selectedValue: selValue});
        
        action.setCallback(this, function(response){
            var state = response.getState();
            if(state === "SUCCESS"){
                var msg = response.getReturnValue();
                if(msg != null && msg.includes('Error:')){                       
                    helper.showToast(component, event, "Error!", msg, "error");
                }else if(msg != null){
                    helper.showToast(component, event, "Success!" ,msg, "success");
                    //helper.findRunningAsyncJob(component, event);
                }
            }else if(state === "ERROR"){
                helper.showToast(component, event,"Error",response.getError(), "error");
            }
        });
        $A.enqueueAction(action);
        
        /* var validdate = component.find('schedulerUSBankStatus').get("v.value");
		if(validdate){
			var action = component.get("c.ScheduleUSBankCreditStatus");
			action.setParams({dtDate: validdate});

			action.setCallback(this, function(response){
				var state = response.getState();
				if(state === "SUCCESS"){
					var model = response.getReturnValue();
					if(model.includes('Error:'))
						helper.showToast(component, event, helper, "Error!", model, "error");
					else{
						helper.showToast(component, event, helper,"Success!" ,model, "success");
						helper.findRunningAsyncJob(component, event);
					}
						
				}else if(state === "ERROR"){
					helper.showToast(component, event, helper,"Error",response.getError(), "error");
				}
			});
			$A.enqueueAction(action);
		}else{
			var model = [];
			model.push('Value cannot be left blank!');
			helper.showToast(component, event, helper ,"Error",model, "error");
		}*/		
    },

    schedulerLeaseData:function(component, event, helper){
		helper.schedulerLeaseData(component, event);
	},
    
    runBatchToUpdateLeaseData : function(component, event, helper) {
        component.set("v.loadedSpin" , true);
        var action = component.get("c.runLeaseDataBatch");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") { 
                component.set("v.loadedSpin" , false);
                var result = response.getReturnValue();
                if(result.isError){
                    helper.showToast(component, event,"Error!",result.messages,"Error"); 
                    component.set("v.loadedSpin" , false);
                }
                else{
                    helper.showToast(component, event,"Success!",result.messages,"Success"); 
                    component.set("v.loadedSpin" , false);
                }
                
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    component.set("v.loadedSpin" , false);
                    helper.showToast(component, event,"Error!",errors[0].message,"error");
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    runBatchToSubmitBOdata : function(component, event, helper) {
        component.set("v.loadedSpin" , true);
        var action = component.get("c.runBatchSyncAllBOQuoteAgreement");
        
        action.setCallback(this, function(response) {
            component.set("v.loadedSpin" , false);
            var state = response.getState();
            if (state === "SUCCESS") { 
                var result = response.getReturnValue();
                if(result.isError){
                    helper.showToast(component, event,"Error!",result.messages,"Error"); 
                }
                else{
                    helper.showToast(component, event,"Success!",result.messages,"Success"); 
                }
                
            }else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    helper.showToast(component, event,"Error!",errors[0].message,"error");
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                    }
                } else {
                    console.log("Unknown error");
                }
            }
        });
        
        $A.enqueueAction(action);
    },
    
    
    
})