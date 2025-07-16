import { LightningElement, wire, track } from 'lwc';
import fiLogos from '@salesforce/resourceUrl/fiLogos';
import getUSBankSettings from '@salesforce/apex/FinancialIntegrationManager.getUSBankConfigurationSettings';
import updateUSBankSettings from '@salesforce/apex/FinancialIntegrationManager.UpdateUSBankConfigurationSettings';
import ScheduleUSBankForMin from '@salesforce/apex/FinancialIntegrationManager.ScheduleUSBankForMin';
import killUSBankStatusScheduled  from '@salesforce/apex/FinancialIntegrationManager.killUSBankStatusScheduled';
import setLeaseSchedule from '@salesforce/apex/USBankController.rateFactorLeaseData';
export default class UsbIntegrationCard extends LightningElement {
    usbLogoUrl = `${fiLogos}/USB-logo.svg`;
    @track settings = {};
    @track settingsMap = {};
    @track settingsHelp = {};
    @track settingsType = {};
    @track settingsLabel = {};
    @track changedFields = new Set();
    @track selectedStatusScheduleValue = '';
    isLoading = true;
   //tempdata
    @track isUSBankLeaseDataSync = true;
    leaseSchedulerTime = '';
    usBankLeaseSyncTimeZone = 'America/New_York';
    //
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
    handleStatusScheduleValueChange(event) {
        this.selectedStatusScheduleValue = event.target.value;
    }
    handleStatusScheduleClick() {
        if (!this.selectedStatusScheduleValue) {
            this.myToast('Error', 'Value cannot be left blank!', 'error');
            return;
        }

        this.isLoading = true;

        ScheduleUSBankForMin({ selectedValue: this.selectedStatusScheduleValue })
            .then(result => {
                if (result && result.includes('Error:')) {
                    this.myToast('Error', result, 'error');
                } else {
                    this.myToast('Success', result || 'Scheduled successfully.', 'success');
                }
            })
            .catch(error => {
                this.myToast('Error', this.getErrorMessage(error), 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    myToast(title, msg, variant){
         this.dispatchEvent(new CustomEvent('toastrequest', {
                detail: {
                    title: title,
                    message: msg,
                    variant: variant
                },
                bubbles: true,
                composed: true
            }));
    }
    getErrorMessage(error) {
        if (Array.isArray(error.body)) {
            return error.body.map(e => e.message).join(', ');
        } else if (typeof error.body?.message === 'string') {
            return error.body.message;
        }
        return 'Unknown error';
    }
    handleLeaseScheduleClick() {
        this.isLoading = true;

        const time = this.leaseSchedulerTime; // ISO string or 'HH:mm:ss' format

        setLeaseSchedule({ dtDate: time })
            .then(result => {
                if (result.isError) {
                    let lmsg = result.messages.join(', ');
                    this.myToast('Error', lmsg , 'error');
                 } else {
                    this.myToast('Success', result.messages.join(', '),'success');
                }
            })
            .catch(error => {
                this.myToast('Exception', error.body?.message || error.message, 'error');
            })
            .finally(() => {
                this.isLoading = false;
            });
    }
    handleLeaseTimeChange(event) {
        const selectedTime = event.target.value; // e.g., "13:30:00"
        const [hour, minute] = selectedTime.split(':').map(Number);

        if (minute % 15 !== 0) {
            this.myToast('Please select a time in 15-minute intervals.', 'error');
            event.target.setCustomValidity('Time must be in 15-minute increments');
        } else {
            event.target.setCustomValidity('');
            this.leaseSchedulerTime = selectedTime;
        }
        event.target.reportValidity();
    }
    get statusScheduleOptions() {
        return [
            { label: '10 Minutes', value: '10' },
            { label: '20 Minutes', value: '20' },
            { label: '30 Minutes', value: '30' },
            { label: '40 Minutes', value: '40' },
            { label: '50 Minutes', value: '50' },
            { label: '1 Hour', value: '60' }
        ];
    }

}