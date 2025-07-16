import { LightningElement, track } from 'lwc';
import {showToast} from 'c/utilityLWC';
import getWellsFargoDealers from '@salesforce/apex/WellsFargoAPIController.getWellsFargoDealers';
import saveWellsFargoDealers from '@salesforce/apex/WellsFargoAPIController.saveWellsFargoDealers';

export default class WellsFargoDealerSetup extends LightningElement {  
    @track dealers = [];
    dealerIds=[];
    emailPattern = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    isLoading=false;
    
    connectedCallback(){
        this.isLoading = true;
        //this.dispatchEvent(showToast(undefined, 'test','test','error'));
        getWellsFargoDealers().then(result => { 
            //alert(JSON.stringify(result));
            if(result.rm.isError == true)
                showToast(this, result.rm);
            else
                this.dealers = result.wfDealers;
            
            this.isLoading = false;
        }).catch(error => {
            //alert('catch=='+JSON.stringify(error));
            this.msg = (error.body != undefined) ? error.body.message : '';
            showToast(this, undefined,'Failed!', msg, 'error');
            this.isLoading = false;
        });
    }
    
    saveDealers(event){
        this.dealersToUpsert = JSON.parse(JSON.stringify(this.dealers));
        
        //console.log('dealersToUpsert=='+JSON.stringify(this.dealersToUpsert));
        this.dealersToUpsert.forEach(
            ele => {
                if(ele.Id.startsWith('new-'))
                    ele.Id = null;
            }
        );
            //console.log('dealersToUpsert=='+JSON.stringify(this.dealersToUpsert));
            //console.log('dealers=='+JSON.stringify(this.dealers));
        saveWellsFargoDealers({"wfDealers":this.dealersToUpsert,"dealersToDelete":this.dealerIds}).then(result => { 
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
                /*console.log('@@@=='+JSON.stringify(inputField));
                console.log('@@@name=='+inputField.name);
                console.log('@@@type=='+inputField.type);
                console.log('@@@val=='+inputField.value);
                console.log('@@@test email=='+inputField.value.match(this.emailPattern));
                console.log('@@@validity=='+inputField.checkValidity(''));*/

                this.flag = true;
                if(inputField.type=='email'){
                    inputField.setCustomValidity('');
                    if(inputField.checkValidity() && inputField.value.match(this.emailPattern) == null){
                        //console.log('@@inside if');
                        inputField.setCustomValidity('You have entered an invalid format.');
                        this.flag = false;
                    }
                }
                inputField.reportValidity();
                return validSoFar && inputField.checkValidity() && this.flag;
            }, true);
        if (isInputsCorrect) {
            this.saveDealers(event);
        }else{
            showToast(this, undefined,'Error: Invalid data.', 'Review all error messages below to correct your data.', 'error');
            this.isLoading = false;
        }

    }

    validateEmail(event){
        if(event.target.value.match(this.emailPattern) == null)
            event.target.setCustomValidity('You have entered an invalid format.');
        else
            event.target.setCustomValidity('');
        
        event.target.reportValidity();
    }

    deleteDealer(event){
        if(confirm('Are you sure?')){
            //console.log(event.target.dataset.index);
            this.dealers.splice(event.target.dataset.index,1);
            if(!event.target.dataset.id.startsWith('new-'))
                this.dealerIds.push(event.target.dataset.id);
        }
        //console.log(this.dealerIds);
    }

    addDealer(event){
        this.dealers = [...this.dealers,{Id:'new-'+new Date()}];
    }

    changeHandler(event) {
        this.dealers[event.target.dataset.index][event.target.name] = event.target.value;
    }
}