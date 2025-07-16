import { LightningElement } from 'lwc';

export default class WellsFargoSetup extends LightningElement {
  

  connectedCallback(){

  }

  /*showNotification(event) {
    let data = event.detail;

    if(data.rm != undefined){
      this.title = (data.rm.isError == true) ? 'Failed!' : 'Success!';
      this.variant = (data.rm.isError == true) ? 'error' : 'success';
      
      data.rm.messages.forEach(element => {
        const evt = new ShowToastEvent({
          title: this.title,
          message: element,
          variant: this.variant,
        });
        this.dispatchEvent(evt);
      });
    }else{
      const evt = new ShowToastEvent({
          title: data.title,
          message: data.message,
          variant: data.variant,
        });
      this.dispatchEvent(evt);
    }
  }*/
}