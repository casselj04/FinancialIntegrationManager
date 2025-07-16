import { LightningElement, wire, track } from 'lwc';
import fiLogos from '@salesforce/resourceUrl/fiLogos';
import getUSBankSettings from '@salesforce/apex/FinancialIntegrationManager.getUSBankConfigurationSettings';
import updateUSBankSettings from '@salesforce/apex/FinancialIntegrationManager.UpdateUSBankConfigurationSettings';


export default class UsbIntegrationCard extends LightningElement {
    usbLogoUrl = `${fiLogos}/USB-logo.svg`;
    @track settings = {};
    @track settingsMap = {};
    @track settingsHelp = {};
    @track settingsType = {};
    @track settingsLabel = {};
    @track changedFields = new Set();
    isLoading = true;
    @track isSaveDisabled=true;

    connectedCallback() {
            getUSBankSettings()
                .then(data => {
                    const rawData = JSON.parse(JSON.stringify(data)); // kills proxies
                    //console.log(rawData)
                    let valueMap = {};
                    let labelMap = {};
                    let helpMap = {};
                    let typeMap = {};

                    Object.keys(rawData).forEach(key => {
                        const field = rawData[key];
                        valueMap[key] = field.value;
                        labelMap[key] = field.label;
                        helpMap[key] = field.helpText||'';
                        typeMap[key] = field.dataType;
                    });

                   this.settingsMap = JSON.parse(JSON.stringify(valueMap));
                   this.settingsLabel = JSON.parse(JSON.stringify(labelMap));
                   this.settingsHelp = JSON.parse(JSON.stringify(helpMap));
                   this.settingsType = JSON.parse(JSON.stringify(typeMap));
                   

                    this.isLoading = false;

              //      console.log('Values:', this.settingsMap);
              //      console.log('Types:', this.settingsType);
              //      console.log('Help:', this.settingsHelp);
                })
                .catch(error => {
                    console.error('Error fetching settings:', error);
                    this.isLoading = false;
                });
        }
    handleInputChange(event) {
        const fieldName = event.target.name;
        this.changedFields.add(fieldName);
        event.target.classList.add('changed-style');
        this.settingsMap ={
            ...this.settingsMap,
            [fieldName]: event.target.value
        }
        this.settings = {
            ...this.settings,
            [fieldName]: event.target.value
        };
        console.log(this.settings );
        this.isSaveDisabled = false;
    }
   handleConnSaveClick() {
    console.log(this.changedFields);
    if (this.changedFields.size === 0) return;

    const updatedValues = {};
    this.changedFields.forEach(fieldName => {
        updatedValues[fieldName] = this.settings[fieldName];
    });
    console.log(this.settings);
    console.log(updatedValues);
    
    updateUSBankSettings({ updatedFields: updatedValues })
        .then(() => {
           this.changedFields.forEach(fieldName => {
                const input = this.template.querySelector(`[name="${fieldName}"]`);
                if (input) {
                    input.value = this.settingsMap[fieldName];
                    input.classList.remove('changed-style');
                }
            });

            this.changedFields.clear();
            this.isSaveDisabled = true;
            this.dispatchEvent(new CustomEvent('toastrequest', {
                detail: {
                    title: 'Success',
                    message: 'Settings updated successfully.',
                    variant: 'success'
                },
                bubbles: true,
                composed: true
            }));
        })
        .catch(error => {
            console.error('Error saving settings:', error);
            this.dispatchEvent(new CustomEvent('toastrequest', {
                detail: {
                    title: 'Error Occurred',
                    message: 'Unable to update settings.'+ error,
                    variant: 'error'
                },
                bubbles: true,
                composed: true
            }));
        });
    }
}