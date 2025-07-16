import { LightningElement } from 'lwc';
import scheduleWellsFargoSync from '@salesforce/apex/WellsFargoAPIController.scheduleWellsFargoSync';
import findRunningAsyncJob from '@salesforce/apex/WellsFargoAPIController.findRunningAsyncJob';
import {showToast} from 'c/utilityLWC';
import saveWellsFargoSettings from '@salesforce/apex/WellsFargoAPIController.saveWellsFargoSettings';
import getWellsFargoSettings from '@salesforce/apex/WellsFargoAPIController.getWellsFargoSettings';

export default class WellsFargoSchedulerSetup extends LightningElement {
    intervalOptions= [
                {value: '', label: '-- None --'},
                {value: '15 minutes', label: '15 minutes'},
                {value: '30 minutes', label: '30 minutes'},
                //{value: '45 minutes', label: '45 minutes'},
                {value: 'Hourly', label: 'Hourly'},
            ];
    obj = {};
    schedulerValues = {};
    isLoading = false;
    custObj = {};

    connectedCallback(){
        this.isLoading = true;
        this.obj.interval = '';
        this.obj.schedulerValues = {};
        this.obj.schedulerValues.message = '';
        this.checkRunningAsyncJob();
        this.datafetch();
    }

    datafetch(){
        getWellsFargoSettings().then(result => { 
            //alert(JSON.stringify(result));
            if(result.rm.isError == true){
                showToast(this, result.rm);
            }else{
                this.custObj = result.wfSetting;
            }
            this.isLoading = false;
        }).catch(error => {
            //alert('catch=='+JSON.stringify(error));
            this.msg = (error.body != undefined) ? error.body.message : '';
            showToast(this, undefined,'Failed!', msg, 'error');
            this.isLoading = false;
        });
    }

    checkRunningAsyncJob(){
        findRunningAsyncJob().then(result => { 
            //console.log(JSON.stringify(result));
            if(result.rm.isError == true){
                //console.log('error block');
                showToast(this, result.rm);
            }else{
                //console.log('no error block');
                this.schedulerValues = result;
            }
            //console.log(JSON.stringify(this.schedulerValues));
            this.isLoading = false;
        }).catch(error => {
            //console.log('catch=='+JSON.stringify(error));
            this.msg = (error.body != undefined) ? error.body.message : '';
            showToast(this, undefined,'Failed!', msg, 'error');
            this.isLoading = false;
        });
    }

    scheduleSync(event){
        //alert(this.obj.interval);
        scheduleWellsFargoSync({interval:this.obj.interval}).then(result => { 
            //alert(JSON.stringify(result));
            showToast(this, result);
            this.checkRunningAsyncJob();
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
        const inputField = this.template.querySelector("[data-name='interval']")
        inputField.setCustomValidity('');
        
        //console.log('length=='+inputField.value.trim().length);
        if(inputField.value.trim().length > 0){
            this.scheduleSync(event);
        }else{
            inputField.setCustomValidity('Please select job interval.');
            showToast(this, undefined,'Error: Invalid data.', 'Review all error messages below to correct your data.', 'error');
            this.isLoading = false;
        }
        inputField.reportValidity();
    }

    changeHandler(event) {
        this.obj[event.target.name] = event.target.value;

        if(event.target.value.trim().length >0)
            event.target.setCustomValidity('');
        
        event.target.reportValidity();
    }

    changedealerHandler(event) {      
        if(event.target.name == 'TSGCFG__Dealer_Lease_Admin_Detail_for_Credit_App__c'){
            this.custObj[event.target.name] = event.target.checked;
        }else{  
            this.custObj[event.target.name] = event.target.value;        
        }
    }

    saveDetails(event){
        this.isLoading = true;
        this.saveSettings(event);
    }

    saveSettings(event){
        saveWellsFargoSettings({"wfSetting":this.custObj}).then(result => { 
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
}