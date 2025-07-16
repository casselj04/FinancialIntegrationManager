import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { NavigationMixin } from 'lightning/navigation';
import { updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';

/*const showToast = (rm, title, message, variant) =>{
    let evt;
    if(rm != undefined){
        evt = new CustomEvent('notify',{
            detail:{rm:rm}
        });
    }else{
        evt = new CustomEvent('notify',{
            detail:{'title':title,'message':message,'variant':variant}
        });
    }
    return evt;
}*/

function showToast(cmp, rm, title, message, variant) {
    if(rm != undefined){
      this.title = (rm.isError == true) ? 'Failed!' : 'Success!';
      this.variant = (rm.isError == true) ? 'error' : 'success';
      
      rm.messages.forEach(element => {
          if(element.toLowerCase().includes('decision in progress')){
            const evt = new ShowToastEvent({
                title: 'Info',
                message: element,
                variant: 'Info',
            });
            cmp.dispatchEvent(evt);

          }else{
            const evt = new ShowToastEvent({
                title: this.title,
                message: element,
                variant: this.variant,
            });
            cmp.dispatchEvent(evt);
          }
        
      });
    }else{
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
        });
        cmp.dispatchEvent(evt);
    }
}

function closeQuickAction(cmp) {
    cmp.dispatchEvent(new CloseActionScreenEvent());
}

function closeQuickActionWithRefresh(cmp, recordId) {
    cmp.dispatchEvent(new CloseActionScreenEvent());
    if(recordId){
        eval("$A.get('e.force:refreshView').fire();");
        //updateRecord({fields: { Id: recordId }});
        //getRecordNotifyChange([{recordId: recordId}]);
    }
}

function navigateToLWC(cmp, attribs){
    var compDefinition = {
        componentDef: "TSGCFG:submitWFApplication",
        attributes: attribs//{"propertyValue": "500","recordId":this.recordId}
    };
    // Base64 encode the compDefinition JS object
    var encodedCompDef = btoa(JSON.stringify(compDefinition));

    
    cmp[NavigationMixin.Navigate]({
        type: "standard__webPage",
        attributes: {
            url: '/one/one.app#' + encodedCompDef
        }
    });
}

function navigateToLWCLeaf(cmp, attribs){
    var compDefinition = {
        componentDef: "TSGCFG:submitLeafApplication",
        attributes: attribs//{"propertyValue": "500","recordId":this.recordId}
    };
    // Base64 encode the compDefinition JS object
    var encodedCompDef = btoa(JSON.stringify(compDefinition));

    
    cmp[NavigationMixin.Navigate]({
        type: "standard__webPage",
        attributes: {
            url: '/one/one.app#' + encodedCompDef
        }
    });
}

function navigateToRecordPage(cmp, recordId, objectApiName) {
    cmp[NavigationMixin.Navigate]({
        type: 'standard__recordPage',
        attributes: {
            recordId: recordId,
            objectApiName: objectApiName,
            actionName: 'view'
        }
    });
}

export {showToast, closeQuickAction, closeQuickActionWithRefresh, navigateToLWC,navigateToLWCLeaf, navigateToRecordPage};