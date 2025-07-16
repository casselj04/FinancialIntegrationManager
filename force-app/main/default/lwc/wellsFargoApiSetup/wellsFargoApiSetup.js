import { LightningElement } from 'lwc';
import {showToast} from 'c/utilityLWC';
import getWellsFargoSettings from '@salesforce/apex/WellsFargoAPIController.getWellsFargoSettings';
import saveWellsFargoSettings from '@salesforce/apex/WellsFargoAPIController.saveWellsFargoSettings';

export default class WellsFargoApiSetup extends LightningElement {  
    obj = {};
    isLoading = false;

    connectedCallback(){
        this.isLoading = true;
        getWellsFargoSettings().then(result => { 
            //alert(JSON.stringify(result));
            if(result.rm.isError == true){
                showToast(this, result.rm);
            }else{
                this.obj = result.wfSetting;
            }
            this.isLoading = false;
        }).catch(error => {
            //alert('catch=='+JSON.stringify(error));
            this.msg = (error.body != undefined) ? error.body.message : '';
            showToast(this, undefined,'Failed!', msg, 'error');
            this.isLoading = false;
        });

        //this.obj.Endpoint__c = '';
        //this.obj.Partner_Reference_Id__c = '';
        //this.obj.Signed_Certificate_Name__c = '';
        //this.obj.interval = '15 minutes';
    }
    
    saveSettings(event){
        saveWellsFargoSettings({"wfSetting":this.obj}).then(result => { 
            //alert(JSON.stringify(result));
            showToast(this, result);
            this.isLoading = false;
        }).catch(error => {
            //alert('catch=='+JSON.stringify(error));
            this.msg = (error.body != undefined) ? error.body.message : '';
            showToast(this, undefined,'Failed!', msg, 'error');
            this.isLoading = false;
        });
    }

    validateData(event){
        this.isLoading = true;
        const isInputsCorrect = [...this.template.querySelectorAll('lightning-input')]
            .reduce((validSoFar, inputField) => {
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity();
            }, true);
        if (isInputsCorrect) {
            this.saveSettings(event);
        }else{
            showToast(this, undefined,'Error: Invalid data.', 'Review all error messages below to correct your data.', 'error');
            this.isLoading = false;
        }

    }

    changeHandler(event) {
        //this.greeting = event.target.value;
        if(event.target.name == 'TSGCFG__Use_logged_in_user_for_credit_app__c'){
            this.obj[event.target.name] = event.target.checked;
        }else{
            this.obj[event.target.name] = event.target.value;
        }
        
    }
}