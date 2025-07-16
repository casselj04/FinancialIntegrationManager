({
    clientBranchDetails : function(component, event){
        var action = component.get("c.getClientBranchDetails");
        action.setCallback(this, function(response){
            
            var state = response.getState();
            if(state === "SUCCESS"){
                var obj = response.getReturnValue();
                console.log('setting detais :: '+JSON.stringify(obj));
               component.set("v.CustomSettingList",obj);
                 component.set("v.loaded",true);
            }else if(state === "ERROR"){
                this.showToast(component, event,"Error!",response.getError(),"error"); 
            }
        });
        $A.enqueueAction(action);
                
    },

    schedulerLeaseData : function(component, event) {
		var validdate = component.find('LeaseDataTime').get("v.value");;
		if(validdate){
			var action = component.get("c.rateFactorLeaseData");
			action.setParams({dtDate: validdate});

			action.setCallback(this, function(response){
				var state = response.getState();
				if(state === "SUCCESS"){
					var model = response.getReturnValue();
					if(model.isError)
						this.showToast(component, event, '', JSON.stringify(model.messages), 'error');
					else{
						this.showToast(component, event, '', JSON.stringify(model.messages),'success');
						this.findRunningAsyncJob(component);
					}
						
				}else if(state === "ERROR"){
					this.showToast(component, event, '', response.getError(),'error');
				}
			});
			$A.enqueueAction(action);
		}else{
			
			this.showToast(component, event, '', 'Value cannot be left blank!', 'error');
		}		
    },
    
    createObjectData: function(component, event) {
        var RowItemList = component.get("v.CustomSettingList");
        RowItemList.push({
            'TSGCFG__Is_Default__c': false,
            'TSGCFG__Client_NBR__c': '',
            'TSGCFG__Client_Name__c': '',
            'TSGCFG__Relation__c': ''
        });
        // set the updated list to attribute (contactList) again    
        component.set("v.CustomSettingList", RowItemList);
    },
    
    saveBranchSettingDetails: function(component, event) {
        //let strDetails = JSON.stringify(component.get("v.CustomSettingList"));
         var action = component.get("c.updateClientBranchDetails");
        action.setParams({ branchDetails : component.get("v.CustomSettingList"),removeClientIds : component.get("v.ClientToRemove")});
 
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (state === "SUCCESS") {
                 component.set("v.loaded",true);
                 $A.get('e.force:refreshView').fire();
                this.showToast(component, event,"Success!","Client Branch Details Updated Successfully!","success"); 
            }else if(state === "ERROR"){
                this.showToast(component, event,"Error!",response.getError(),"error"); 
                // component.set("v.loaded",true);
                $A.get('e.force:refreshView').fire();
            }
        });
        $A.enqueueAction(action);
    },
    
    findRunningAsyncJob: function(component, event){
        component.set("v.isUSBankStatusSync",false);   
        component.set("v.isUSBankLeaseDataSync",false);   
             
        
        var action = component.get("c.findRunningAsyncJob");
        action.setCallback(this, function(response){
            
            var state = response.getState();
            if(state === "SUCCESS"){
                var obj = response.getReturnValue();
                if(obj != null && obj.length >0){
                        obj.forEach(o => {
                            if(o.jobname == 'USBank Status Sync'){
                            component.set("v.isUSBankStatusSync",true);
                            component.set("v.SchedulerTime", o.NextFireTime);
                            component.set("v.USBankSyncTimeZone", o.TimeZoneSidKey);
                        }  
                        if(o.jobname == 'Lease Data'){
                            component.set("v.isUSBankLeaseDataSync",true); 
                            component.set("v.LeaseSchedulerTime", o.NextFireTime);
                            component.set("v.USBankLeaseSyncTimeZone", o.TimeZoneSidKey);
                        }         
                    });
                    
                }
                
            }else if(state === "ERROR"){
                this.showToast(component, event,"Error!",response.getError(),"error");             
            }
        });
        $A.enqueueAction(action);
    },
    
    showSuccess : function(component, event, helper,message) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            title : 'Success',
            message: message,
            duration:' 5000',
            key: 'info_alt',
            type: 'success',
            mode: 'pester'
        });
        toastEvent.fire();
    },
    showToast : function(component, event,title,message,type) {
        var toastEvent = $A.get("e.force:showToast");
        toastEvent.setParams({
            "title": title,
            "message": message,
            "type":type
        });
        toastEvent.fire();
    }
})