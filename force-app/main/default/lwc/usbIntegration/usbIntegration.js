import { LightningElement, wire } from 'lwc';
import fiLogos from '@salesforce/resourceUrl/fiLogos';
import getCustomSettingDetails from '@salesforce/apex/USBankController.getCustomSettingDetails';


export default class UsbIntegrationCard extends LightningElement {
    usbLogoUrl = `${fiLogos}/USB-logo.svg`;
    settings = {};
    isLoading = true;
    @wire(getCustomSettingDetails)
    wiredSettings({ error, data }) {
        if (data) {
            this.settings = data;
            this.isLoading = false;
        } else if (error) {
            console.error('Error fetching settings', error);
        }
    }
}